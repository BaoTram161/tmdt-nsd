require "test_helper"

module Admin
  class PromotionCodesControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = users(:one)
      @admin.update!(is_admin: true)
      sign_in_as(@admin)

      @promotion_code = PromotionCode.create!(
        code: "TEST10",
        discount_type: :percentage,
        discount_value: 10,
        minimum_order_value: 0,
        used_count: 0,
        active: true
      )
    end

    test "admin có thể xem danh sách mã khuyến mãi" do
      get admin_promotion_codes_url

      assert_response :success
      assert_includes response.body, "TEST10"
    end

    test "admin có thể xem trang tạo mã khuyến mãi" do
      get new_admin_promotion_code_url

      assert_response :success
    end

    test "admin có thể tạo mã khuyến mãi" do
      assert_difference("PromotionCode.count", 1) do
        post admin_promotion_codes_url, params: {
          promotion_code: {
            code: "NEW20",
            discount_type: "percentage",
            discount_value: 20,
            minimum_order_value: 0,
            active: true
          }
        }
      end

      assert_redirected_to admin_promotion_codes_url
    end

    test "admin có thể chỉnh sửa mã khuyến mãi" do
      patch admin_promotion_code_url(@promotion_code), params: {
        promotion_code: {
          discount_value: 15
        }
      }

      assert_redirected_to admin_promotion_codes_url
      assert_equal 15, @promotion_code.reload.discount_value
    end

    test "admin có thể kích hoạt và tạm ngưng mã khuyến mãi" do
      patch toggle_active_admin_promotion_code_url(@promotion_code)

      assert_redirected_to admin_promotion_codes_url
      assert_not @promotion_code.reload.active?

      patch toggle_active_admin_promotion_code_url(@promotion_code)

      assert_redirected_to admin_promotion_codes_url
      assert @promotion_code.reload.active?
    end

    test "admin có thể tìm kiếm mã khuyến mãi" do
      get admin_promotion_codes_url, params: { q: "TEST10" }

      assert_response :success
      assert_includes response.body, "TEST10"
    end

    test "admin có thể lọc mã đang hoạt động" do
      get admin_promotion_codes_url, params: { status: "active" }

      assert_response :success
      assert_includes response.body, "TEST10"
    end

    test "khách hàng không có quyền quản lý mã khuyến mãi" do
      sign_out
      @admin.update!(is_admin: false)
      sign_in_as(@admin)

      get admin_promotion_codes_url

      assert_redirected_to root_url
    end
  end
end
