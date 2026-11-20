require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  test "đánh giá hợp lệ" do
    review = Review.new(
      user: users(:one),
      product: products(:two),
      rating: 5,
      content: "Sản phẩm rất tốt"
    )

    assert review.valid?
  end

  test "không chấp nhận số sao nhỏ hơn 1" do
    review = reviews(:one)
    review.rating = 0

    assert_not review.valid?
  end

  test "không chấp nhận số sao lớn hơn 5" do
    review = reviews(:one)
    review.rating = 6

    assert_not review.valid?
  end

  test "không cho phép đánh giá trùng sản phẩm" do
    review = Review.new(
      user: users(:one),
      product: products(:one),
      rating: 4,
      content: "Đánh giá lần hai"
    )

    assert_not review.valid?
  end
end
