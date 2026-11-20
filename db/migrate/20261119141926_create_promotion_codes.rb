class CreatePromotionCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :promotion_codes do |t|
      t.string :code, null: false
      t.string :discount_type, null: false
      t.decimal :discount_value, precision: 12, scale: 2, null: false
      t.decimal :minimum_order_value, precision: 12, scale: 2,
                                     null: false, default: 0
      t.decimal :maximum_discount, precision: 12, scale: 2
      t.integer :usage_limit
      t.integer :per_user_limit
      t.integer :used_count, null: false, default: 0
      t.datetime :starts_at
      t.datetime :expires_at
      t.boolean :active, null: false, default: true
      t.text :description

      t.timestamps
    end

    add_index :promotion_codes, :code, unique: true

    add_column :orders, :promotion_code, :string
    add_column :orders, :discount_amount, :decimal,
               precision: 12, scale: 2, null: false, default: 0
  end
end
