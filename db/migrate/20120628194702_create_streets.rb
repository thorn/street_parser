class CreateCities < ActiveRecord::Migration
  def change
    create_table :streets do |t|
      t.string :name
      t.string :ancestry
      t.string :aoguid
      t.string :formalname
      t.string :regioncode
      t.string :areacode
      t.string :citycode
      t.string :ctarcode
      t.string :placecode
      t.string :streetcode
      t.string :extrcode
      t.string :offname
      t.string :shortname
      t.string :aolevel
      t.string :parentguid
      t.string :aoid
      t.string :previd
      t.string :nextid

      t.timestamps
    end
  end
end
