class CreateCustomerOrdering < ActiveRecord::Migration[8.1]
  def change
    # Thông tin hồ sơ khách hàng
    add_column :users, :full_name, :string
    add_column :users, :phone, :string

    # Địa chỉ giao hàng của khách hàng
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true

      t.string :label, null: false
      t.string :recipient_name, null: false
      t.string :phone, null: false
      t.string :province, null: false
      t.string :district, null: false
      t.string :ward, null: false
      t.string :street_address, null: false
      t.boolean :is_default, null: false, default: false

      t.timestamps
    end

    # Đơn hàng
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true

      t.string :order_number, null: false
      t.string :recipient_name, null: false
      t.string :phone, null: false
      t.string :province, null: false
      t.string :district, null: false
      t.string :ward, null: false
      t.string :street_address, null: false

      t.string :status, null: false, default: "pending"
      t.string :payment_method, null: false, default: "cod"

      t.decimal :subtotal, precision: 12, scale: 2, null: false, default: 0
      t.decimal :shipping_fee, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0

      t.text :note

      t.timestamps
    end

    add_index :orders, :order_number, unique: true

    # Chi tiết sản phẩm trong từng đơn hàng
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: true,
                             foreign_key: { on_delete: :nullify }

      # Lưu thông tin tại thời điểm đặt hàng
      t.string :product_name, null: false
      t.string :product_image
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 12, scale: 2, null: false
      t.decimal :total_price, precision: 12, scale: 2, null: false

      t.timestamps
    end
  end
end
