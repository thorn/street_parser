class Add < ActiveRecord::Migration
  def change
    add_column :cities, :ancestry_depth, :integer, default: 0
  end

end
