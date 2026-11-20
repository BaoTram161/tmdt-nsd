require "test_helper"

module Admin
  class ReviewsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = users(:one)
      @admin.update!(is_admin: true)
      sign_in_as(@admin)

      @product = products(:two)

      @review = Review.create!(
        user: @admin,
        product: @product,
        rating: 5,
        content: "Sản phẩm rất tốt"
      )
    end

    test "admin có thể xem danh sách đánh giá" do
      get admin_reviews_url

      assert_response :success
      assert_includes response.body, "Sản phẩm rất tốt"
    end

    test "admin có thể tìm kiếm đánh giá" do
      get admin_reviews_url, params: { q: "rất tốt" }

      assert_response :success
      assert_includes response.body, "Sản phẩm rất tốt"
    end

    test "admin có thể lọc đánh giá theo số sao" do
      get admin_reviews_url, params: { rating: 5 }

      assert_response :success
      assert_includes response.body, "Sản phẩm rất tốt"
    end

    test "admin có thể xóa đánh giá" do
      assert_difference("Review.count", -1) do
        delete admin_review_url(@review)
      end

      assert_redirected_to admin_reviews_url
    end

    test "khách hàng không có quyền quản lý đánh giá" do
      sign_out
      @admin.update!(is_admin: false)
      sign_in_as(@admin)

      get admin_reviews_url

      assert_redirected_to root_url
    end
  end
end
