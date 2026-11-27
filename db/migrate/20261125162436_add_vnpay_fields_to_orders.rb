class AddVnpayFieldsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :vnpay_transaction_no, :string
    add_column :orders, :paid_at, :datetime
    add_column :orders, :payment_expires_at, :datetime

    add_index :orders, :vnpay_transaction_no, unique: true
  end
end
