#-*- encoding: utf-8 -*-
require "nokogiri"

module Parser
  class StreetParser
    def initialize(filename)
      City.delete_all
      @document = Nokogiri::XML(File.open(filename))
      root = create_root
      recursive_parse(root.id, '0bb7fa19-736d-49cf-ad0e-9774c4dae09b')
    end

    def recursive_parse(parent_id, find_node_id)
      @document.css("Object[PARENTGUID=\"#{find_node_id}\"]").each do |el|
        name = el[:SHORTNAME].length <= 3 ? "#{el[:SHORTNAME]}. #{el[:OFFNAME]}" : "#{el[:SHORTNAME]} #{el[:OFFNAME]}"
        new_parent = create_city(name, parent_id)
        recursive_parse(new_parent.id, el[:AOGUID])
      end
    end

    def create_root
      main = create_city "Россия"
      root = @document.at_css('Object[AOGUID="0bb7fa19-736d-49cf-ad0e-9774c4dae09b"]')
      create_city "#{root[:SHORTNAME]}. #{root[:OFFNAME]}", main.id
    end

    def create_city(name, parent=nil)
      City.create(name: name, parent_id: parent)
    end
  end
end

class City < ActiveRecord::Base
  attr_accessible :ancestry, :name, :parent_id
  has_ancestry cache_depth: true
  include Parser

  def self.parse_all
    s = StreetParser.new('/home/arsen/work/street_parser/app/models/daghestan.xml')
  end

  def self.order_cities
    Hirb.enable
    root = City.roots.first.children.first # Дагестан
    cities = root.children.where("name LIKE 'г. %'")
    cities.each do |city|
      city_copy = City.create(name: city.name, parent_id: city.id)
      city.children.each do |child|
        child.update_attribute(:parent_id, city_copy.id) if child.children.length.zero?
      end
    end
  end
end
