class Product < ApplicationRecord
  belongs_to :category

  validates :name, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :original_price, numericality: { greater_than: 0 }, allow_nil: true
  validates :stock, :sold_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :available, -> { where(active: true) }
  scope :featured, -> { where(featured: true) }
  scope :latest, -> { order(created_at: :desc) }

  def in_stock?
    stock.to_i > 0
  end

  def on_sale?
    original_price.present? && original_price > price
  end

  def discount_percent
    return 0 unless on_sale?

    ((original_price - price) * 100 / original_price).round
  end
end
