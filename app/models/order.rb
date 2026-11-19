class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy

  # Trạng thái xử lý đơn hàng
  enum :status, {
    pending: "pending",
    confirmed: "confirmed",
    shipping: "shipping",
    delivered: "delivered",
    cancelled: "cancelled"
  }, default: :pending

  # Phương thức thanh toán
  enum :payment_method, {
    cod: "cod"
  }, default: :cod

  # Trạng thái thanh toán độc lập với trạng thái đơn hàng
  enum :payment_status, {
    unpaid: "unpaid",
    paid: "paid",
    refunded: "refunded"
  }, default: :unpaid

  before_validation :generate_order_number, on: :create

  validates :order_number, presence: true, uniqueness: true

  validates :recipient_name, :phone, :province,
            :ward, :street_address, presence: true

  validates :subtotal, :shipping_fee, :total,
            numericality: { greater_than_or_equal_to: 0 }

  private

  def generate_order_number
    return if order_number.present?

    loop do
      self.order_number = "BG-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
      break unless self.class.exists?(order_number: order_number)
    end
  end
end
