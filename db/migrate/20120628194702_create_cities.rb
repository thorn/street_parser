class CreateCities < ActiveRecord::Migration
  def change
    create_table :cities do |t|
      t.string :name
      t.string :ancestry

      t.timestamps
    end
  end
end
