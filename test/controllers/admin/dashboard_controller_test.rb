require "test_helper"

module Admin
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = users(:one)
      @admin.update!(is_admin: true)
      sign_in_as(@admin)
    end

    test "admin có thể xem dashboard" do
      get admin_root_url

      assert_response :success
      assert_not response.body.empty?
    end

    test "dashboard hiển thị nội dung thống kê" do
      get admin_root_url

      assert_response :success
      assert_includes response.body, "Đơn hàng"
      assert_includes response.body, "Sản phẩm"
      assert_includes response.body, "Khách hàng"
    end

    test "người chưa đăng nhập không thể truy cập dashboard" do
      sign_out
      get admin_root_url

      assert_redirected_to new_session_url
    end

    test "khách hàng không có quyền truy cập dashboard" do
      sign_out
      @admin.update!(is_admin: false)
      sign_in_as(@admin)

      get admin_root_url

      assert_redirected_to root_url
    end
  end
end
