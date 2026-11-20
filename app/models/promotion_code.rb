class PromotionCode < ApplicationRecord
  has_many :orders,
           foreign_key: :promotion_code,
           primary_key: :code,
           inverse_of: false

  enum :discount_type, {
    percentage: "percentage",
    fixed: "fixed"
  }

  before_validation :normalize_code

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :discount_type, presence: true
  validates :discount_value, numericality: { greater_than: 0 }
  validates :minimum_order_value,
            numericality: { greater_than_or_equal_to: 0 }
  validates :maximum_discount,
            numericality: { greater_than: 0 },
            allow_nil: true
  validates :usage_limit,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
  validates :per_user_limit,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
  validates :used_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :validate_discount_value
  validate :validate_dates

  scope :active, -> { where(active: true) }

  def available?
    active? &&
      (starts_at.nil? || starts_at <= Time.current) &&
      (expires_at.nil? || expires_at >= Time.current) &&
      (usage_limit.nil? || used_count < usage_limit)
  end

  def eligibility_error(user:, subtotal:)
    amount = subtotal.to_d

    return "Mã khuyến mãi hiện đã bị tạm ngưng." unless active?

    if starts_at.present? && starts_at > Time.current
      return "Mã khuyến mãi chưa đến thời gian sử dụng."
    end

    if expires_at.present? && expires_at < Time.current
      return "Mã khuyến mãi đã hết hạn."
    end

    if usage_limit.present? && used_count >= usage_limit
      return "Mã khuyến mãi đã hết lượt sử dụng."
    end

    if amount < minimum_order_value.to_d
      return "Đơn hàng chưa đạt giá trị tối thiểu để sử dụng mã này."
    end

    if per_user_limit.present?
      return "Vui lòng đăng nhập để sử dụng mã khuyến mãi." unless user

      usage_count = user.orders.where(promotion_code: code).count

      if usage_count >= per_user_limit
        return "Bạn đã sử dụng hết số lượt cho phép của mã này."
      end
    end

    nil
  end

  def calculate_discount(subtotal)
    amount = subtotal.to_d

    return 0.to_d unless available?
    return 0.to_d if amount < minimum_order_value.to_d

    discount =
      if percentage?
        amount * discount_value.to_d / 100
      else
        discount_value.to_d
      end

    discount = [ discount, maximum_discount.to_d ].min if maximum_discount.present?

    [ discount, amount ].min.round(2)
  end

  private

  def normalize_code
    self.code = code.to_s.strip.upcase.presence
  end

  def validate_discount_value
    return unless discount_value.present?

    if percentage? && discount_value.to_d > 100
      errors.add(:discount_value, "không được vượt quá 100%")
    end

    if fixed? && maximum_discount.present?
      errors.add(:maximum_discount, "không áp dụng cho mã giảm tiền cố định")
    end
  end

  def validate_dates
    if starts_at.present? && expires_at.present? && expires_at <= starts_at
      errors.add(:expires_at, "phải sau ngày bắt đầu")
    end
  end
end
