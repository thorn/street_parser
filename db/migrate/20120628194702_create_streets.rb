class CreateStreets < ActiveRecord::Migration
  def change
    create_table :streets do |t|
      t.string :name
      t.string :ancestry
      t.text   :aoguid

      t.timestamps
    end
  end
end
