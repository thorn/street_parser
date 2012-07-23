#-*- encoding: utf-8 -*-
require "nokogiri"

module Parser
  class StreetParser
    def initialize(filename)
      Street.delete_all
      @document = Nokogiri::XML(File.open(filename))
      root = create_root
      recursive_parse(root.id, '0bb7fa19-736d-49cf-ad0e-9774c4dae09b')
      true
    end

    def recursive_parse(parent_id, find_node_id)
      @document.css("Object[PARENTGUID=\"#{find_node_id}\"]").each do |el|
        new_parent = create_city(el, parent_id)
        recursive_parse(new_parent.id, el[:AOGUID])
      end
    end

    def create_root
      root = Street.create(name: "Россия", aoguid: "0")
      dag = @document.at_css('Object[AOGUID="0bb7fa19-736d-49cf-ad0e-9774c4dae09b"]')
      daghestan = create_city dag, root.id
    end

    def create_city(el, parent_id = nil)
      name = el[:SHORTNAME].length <= 3 ? "#{el[:SHORTNAME]}. #{el[:OFFNAME]}" : "#{el[:SHORTNAME]} #{el[:OFFNAME]}"
      attr = {
        name:       name,
        aoguid:     el[:AOGUID],
        parent_id:  parent_id
      }
      Street.create(attr)
    end
  end
end

class Street < ActiveRecord::Base
  attr_accessible :parent_id, :ancestry, :name, :aoguid, :formalname, :regioncode, :areacode, :citycode, :ctarcode, :placecode, :streetcode, :extrcode, :offname, :shortname, :aolevel, :parentguid, :aoid, :previd, :nextid
  has_ancestry #primary_key_format: /^[\d,\w]{8}-[\d,\w]{4}-[\d,\w]{4}-[\d,\w]{4}-[\d,\w]{12}$/i
  include Parser

  def self.parse_all
    s = StreetParser.new('/home/arsen/work/street_parser/app/models/daghestan.xml')
  end

  def parent_id=(parent_id)
    parent = Street.find_by_id(parent_id)
    new_ancestry = parent.ancestry.nil? ? parent.aoguid : parent.ancestry + "/#{parent.aoguid}"
    update_attribute :ancestry, new_ancestry
  end

  def children
    child_ancestry = ancestry.nil? ? aoguid : ancestry + "/#{aoguid}"
    Street.where("ancestry LIKE '#{child_ancestry}'")
  end

  def self.order_cities
    Hirb.enable
    root = Street.roots.first.children.first # Дагестан
    cities = root.children.where("name LIKE 'г. %'")
    cities.each do |city|
      city_copy = Street.create(name: city.name, aoguid: city.aoguid, parent_id: city.id)
      city.children.each do |child|
        child.update_attribute(:parent_id, city_copy.id) if child.children.length.zero?
      end
    end
  end
end

# root = City.roots.first.children.first
def child_ancestry
  if self.send("#{self.base_class.ancestry_column}_was").blank? then id.to_s else "#{self.send "#{self.base_class.ancestry_column}_was"}/#{id}" end
end
