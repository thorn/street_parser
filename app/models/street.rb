#-*- encoding: utf-8 -*-
require "nokogiri"

module Parser
  class StreetParser
    def initialize(filename)
      Street.delete_all
      @document = Nokogiri::XML(File.open(filename))
      root = create_root
      recursive_parse(root.id, '0bb7fa19-736d-49cf-ad0e-9774c4dae09b')
    end

    def recursive_parse(parent_id, find_node_id)
      @document.css("Object[PARENTGUID=\"#{find_node_id}\"]").each do |el|
        new_parent = create_city(el, parent_id)
        recursive_parse(new_parent.id, el[:AOGUID])
      end
    end

    def create_root
      root = Street.create(name: "Россия")
      dag = @document.at_css('Object[AOGUID="0bb7fa19-736d-49cf-ad0e-9774c4dae09b"]')
      daghestan = create_city dag, root.id
    end

    def create_city(el, parent = nil)
      name = el[:SHORTNAME].length <= 3 ? "#{el[:SHORTNAME]}. #{el[:OFFNAME]}" : "#{el[:SHORTNAME]} #{el[:OFFNAME]}"
      attr = {
        name:       name,
        aoguid:     el[:AOGUID],
        formalname: el[:FORMALNAME],
        regioncode: el[:REGIONCODE],
        areacode:   el[:AREACODE],
        citycode:   el[:CITYCODE],
        ctarcode:   el[:CTARCODE],
        placecode:  el[:PLACECODE],
        streetcode: el[:STREETCODE],
        extrcode:   el[:EXTRCODE],
        offname:    el[:OFFNAME],
        shortname:  el[:SHORTNAME],
        aolevel:    el[:AOLEVEL],
        parentguid: el[:PARENTGUID],
        aoid:       el[:AOID],
        previd:     el[:PREVID],
        nextid:     el[:NEXTID],
        parent_id:  parent
      }
      Street.create(attr)
    end
  end
end

class Street < ActiveRecord::Base
  attr_accessible :parent_id, :ancestry, :name, :aoguid, :formalname, :regioncode, :areacode, :citycode, :ctarcode, :placecode, :streetcode, :extrcode, :offname, :shortname, :aolevel, :parentguid, :aoid, :previd, :nextid
  has_ancestry
  include Parser

  def self.parse_all
    s = StreetParser.new('/home/arsen/work/street_parser/app/models/daghestan.xml')
  end

  def self.order_cities
    Hirb.enable
    root = Street.roots.first.children.first # Дагестан
    cities = root.children.where("name LIKE 'г. %'")
    cities.each do |city|
      city_copy = Street.create(name: city.name, aoguid: city.aoguid, formalname: city.formalname, regioncode: city.regioncode, areacode: city.areacode, citycode: city.citycode, ctarcode: city.ctarcode, placecode: city.placecode, streetcode: city.streetcode, extrcode: city.extrcode, offname: city.offname, shortname: city.shortname, aolevel: city.aolevel, parentguid: city.parentguid, aoid: city.aoid, previd: city.previd, nextid: city.nextid, parent_id: city.id)
      city.children.each do |child|
        child.update_attribute(:parent_id, city_copy.id) if child.children.length.zero?
      end
    end
  end
end

# root = City.roots.first.children.first
