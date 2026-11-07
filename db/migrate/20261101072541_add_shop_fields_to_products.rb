class AddShopFieldsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :original_price, :decimal, precision: 12, scale: 0
    add_column :products, :sold_count, :integer, null: false, default: 0
    add_column :products, :brand, :string
    add_index :products, :brand
  end
end
