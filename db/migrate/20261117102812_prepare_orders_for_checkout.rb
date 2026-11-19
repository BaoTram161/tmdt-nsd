class PrepareOrdersForCheckout < ActiveRecord::Migration[8.1]
  def change
    # Địa chỉ mới không còn sử dụng Quận / Huyện
    remove_column :orders, :district, :string

    # Theo dõi trạng thái thanh toán độc lập với trạng thái giao hàng.
    # Mở rộng sang QR / chuyển khoản.
    add_column :orders, :payment_status,
               :string,
               null: false,
               default: "unpaid"

    add_index :orders, :payment_status
  end
end