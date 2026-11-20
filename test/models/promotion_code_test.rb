require "test_helper"

class PromotionCodeTest < ActiveSupport::TestCase
  def setup
    @promotion_code = PromotionCode.new(
      code: "test10",
      discount_type: :percentage,
      discount_value: 10,
      minimum_order_value: 0,
      used_count: 0,
      active: true
    )
  end

  test "valid promotion code" do
    assert @promotion_code.valid?
  end

  test "normalizes code to uppercase" do
    @promotion_code.valid?
    assert_equal "TEST10", @promotion_code.code
  end

  test "requires unique code" do
    @promotion_code.save!

    duplicate = PromotionCode.new(
      code: "test10",
      discount_type: :percentage,
      discount_value: 10,
      active: true
    )

    assert_not duplicate.valid?
  end

  test "rejects percentage greater than 100" do
    @promotion_code.discount_value = 101

    assert_not @promotion_code.valid?
  end

  test "rejects zero discount value" do
    @promotion_code.discount_value = 0

    assert_not @promotion_code.valid?
  end

  test "rejects negative minimum order value" do
    @promotion_code.minimum_order_value = -1

    assert_not @promotion_code.valid?
  end

  test "rejects maximum discount for fixed discount" do
    @promotion_code.discount_type = :fixed
    @promotion_code.discount_value = 50_000
    @promotion_code.maximum_discount = 20_000

    assert_not @promotion_code.valid?
  end

  test "rejects expiration date before start date" do
    @promotion_code.starts_at = 2.days.from_now
    @promotion_code.expires_at = 1.day.from_now

    assert_not @promotion_code.valid?
  end

  test "rejects usage limit of zero" do
    @promotion_code.usage_limit = 0

    assert_not @promotion_code.valid?
  end

  test "rejects per user limit of zero" do
    @promotion_code.per_user_limit = 0

    assert_not @promotion_code.valid?
  end

  test "calculates percentage discount" do
    assert_equal 100.to_d, @promotion_code.calculate_discount(1_000)
  end

  test "limits percentage discount by maximum discount" do
    @promotion_code.maximum_discount = 50

    assert_equal 50.to_d, @promotion_code.calculate_discount(1_000)
  end

  test "does not discount more than subtotal" do
    @promotion_code.discount_value = 5_000

    assert_equal 1_000.to_d, @promotion_code.calculate_discount(1_000)
  end

  test "does not apply discount below minimum order value" do
    @promotion_code.minimum_order_value = 2_000

    assert_equal 0.to_d, @promotion_code.calculate_discount(1_000)
  end

  test "does not apply inactive promotion code" do
    @promotion_code.active = false

    assert_equal 0.to_d, @promotion_code.calculate_discount(1_000)
  end

  test "does not apply expired promotion code" do
    @promotion_code.expires_at = 1.day.ago

    assert_equal 0.to_d, @promotion_code.calculate_discount(1_000)
  end

  test "does not apply promotion code before start date" do
    @promotion_code.starts_at = 1.day.from_now

    assert_equal 0.to_d, @promotion_code.calculate_discount(1_000)
  end

  test "does not apply promotion code after usage limit is reached" do
    @promotion_code.usage_limit = 5
    @promotion_code.used_count = 5

    assert_equal 0.to_d, @promotion_code.calculate_discount(1_000)
  end
end
