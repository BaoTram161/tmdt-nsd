require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @product = Product.create!(
      category: categories(:one),
      name: "Sản phẩm đánh giá",
      description: "Sản phẩm kiểm thử",
      price: 100_000,
      stock: 10,
      sold_count: 0,
      active: true
    )

    sign_in_as(@user)
  end

  test "không cho đánh giá khi chưa có đơn giao thành công" do
    assert_no_difference("Review.count") do
      post product_reviews_path(@product), params: {
        review: { rating: 5, content: "Sản phẩm tốt" }
      }
    end

    assert_redirected_to product_path(@product)
  end

  test "cho phép đánh giá khi đơn hàng đã giao" do
    create_delivered_order

    assert_difference("Review.count", 1) do
      post product_reviews_path(@product), params: {
        review: { rating: 5, content: "Sản phẩm rất tốt" }
      }
    end

    assert_redirected_to product_path(@product, anchor: "reviews")
  end

  test "không cho đánh giá lần thứ hai" do
    create_delivered_order

    Review.create!(
      user: @user,
      product: @product,
      rating: 4,
      content: "Đánh giá trước đó"
    )

    assert_no_difference("Review.count") do
      post product_reviews_path(@product), params: {
        review: { rating: 5, content: "Đánh giá lần hai" }
      }
    end
  end

  test "chỉ chủ sở hữu mới được xóa đánh giá" do
    review = Review.create!(
      user: users(:two),
      product: @product,
      rating: 4,
      content: "Đánh giá của người khác"
    )

    assert_no_difference("Review.count") do
      delete product_review_path(@product, review)
    end
  end

  test "chủ sở hữu có thể cập nhật đánh giá" do
    review = Review.create!(
      user: @user,
      product: @product,
      rating: 3,
      content: "Đánh giá ban đầu"
    )

    patch product_review_path(@product, review), params: {
      review: {
        rating: 5,
        content: "Sản phẩm rất tốt"
      }
    }

    assert_redirected_to product_path(@product, anchor: "reviews")
    assert_equal 5, review.reload.rating
    assert_equal "Sản phẩm rất tốt", review.content
  end

  test "chủ sở hữu có thể xóa đánh giá" do
    review = Review.create!(
      user: @user,
      product: @product,
      rating: 5,
      content: "Đánh giá của tôi"
    )

    assert_difference("Review.count", -1) do
      delete product_review_path(@product, review)
    end

    assert_redirected_to product_path(@product, anchor: "reviews")
  end

  test "chuyển đến trang đăng nhập khi chưa đăng nhập để đánh giá" do
    sign_out

    assert_no_difference("Review.count") do
      post product_reviews_path(@product), params: {
        review: { rating: 5, content: "Sản phẩm tốt" }
      }
    end

    assert_redirected_to new_session_path
  end

  private

  def create_delivered_order
    order = Order.create!(
      user: @user,
      status: :delivered,
      recipient_name: "Nguyen Van A",
      phone: "0900000000",
      province: "TP.Hồ Chí Minh",
      ward: "Phường 1",
      street_address: "Địa chỉ kiểm thử",
      subtotal: 100_000,
      shipping_fee: 0,
      total: 100_000
    )

    OrderItem.create!(
      order: order,
      product: @product,
      product_name: @product.name,
      quantity: 1,
      unit_price: 100_000,
      total_price: 100_000
    )
  end

  # DANH SÁCH ĐÁNH GIÁ

  test "chỉ hiển thị đánh giá của tài khoản đang đăng nhập" do
    own_review = Review.create!(
      user: @user,
      product: @product,
      rating: 5,
      content: "Đánh giá của tôi"
    )

    other_review = Review.create!(
      user: users(:two),
      product: @product,
      rating: 4,
      content: "Đánh giá của người khác"
    )

    get reviews_path

    assert_response :success
    assert_includes response.body, own_review.content
    assert_not_includes response.body, other_review.content
  end

  # KIỂM TRA QUYỀN CẬP NHẬT

  test "không thể cập nhật đánh giá của người khác" do
    review = Review.create!(
      user: users(:two),
      product: @product,
      rating: 4,
      content: "Đánh giá của người khác"
    )

    patch product_review_path(@product, review), params: {
      review: {
        rating: 1,
        content: "Nội dung bị thay đổi"
      }
    }

    assert_response :not_found
    assert_equal 4, review.reload.rating
    assert_equal "Đánh giá của người khác", review.content
  end

  test "không thể sửa đánh giá thông qua sản phẩm khác" do
    other_product = Product.create!(
      category: categories(:one),
      name: "Sản phẩm khác",
      description: "Sản phẩm kiểm thử",
      price: 150_000,
      stock: 5,
      sold_count: 0,
      active: true
    )

    review = Review.create!(
      user: @user,
      product: @product,
      rating: 4,
      content: "Đánh giá ban đầu"
    )

    patch product_review_path(other_product, review), params: {
      review: {
        rating: 1,
        content: "Nội dung bị thay đổi"
      }
    }

    assert_response :not_found
    assert_equal 4, review.reload.rating
    assert_equal "Đánh giá ban đầu", review.content
  end
end
