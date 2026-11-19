require "test_helper"

module Admin
  class CustomersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = users(:one)
      @admin.update!(is_admin: true)

      @customer = users(:two)
      @customer.update!(
        full_name: "Nguyễn Văn An",
        phone: "0901234567"
      )

      sign_in_as(@admin)
    end

    test "admin có thể xem danh sách khách hàng" do
      get admin_customers_url

      assert_response :success
      assert_includes response.body, "Nguyễn Văn An"
      assert_includes response.body, @customer.email_address
      assert_not_includes response.body, @admin.email_address
    end

    test "admin có thể tìm kiếm khách hàng theo tên" do
      get admin_customers_url, params: { q: "Nguyễn Văn An" }

      assert_response :success
      assert_includes response.body, "Nguyễn Văn An"
      assert_not_includes response.body, @admin.email_address
    end

    test "admin có thể tìm kiếm khách hàng theo email" do
      get admin_customers_url, params: { q: @customer.email_address }

      assert_response :success
      assert_includes response.body, @customer.email_address
    end

    test "admin có thể xem chi tiết khách hàng" do
      get admin_customer_url(@customer)

      assert_response :success
      assert_includes response.body, "Nguyễn Văn An"
      assert_includes response.body, @customer.email_address
      assert_includes response.body, "0901234567"
      assert_includes response.body, "THÔNG TIN TÀI KHOẢN"
      assert_includes response.body, "ĐỊA CHỈ ĐÃ LƯU"
      assert_includes response.body, "LỊCH SỬ ĐƠN HÀNG"
    end

    test "admin có thể xem địa chỉ đã lưu của khách hàng" do
      create_address

      get admin_customer_url(@customer)

      assert_response :success
      assert_includes response.body, "Địa chỉ nhà"
      assert_includes response.body, "Nguyễn Văn An"
      assert_includes response.body, "123 Đường Nguyễn Huệ"
      assert_includes response.body, "MẶC ĐỊNH"
    end

    test "admin có thể xem lịch sử đơn hàng của khách hàng" do
      order = create_order

      get admin_customer_url(@customer)

      assert_response :success
      assert_includes response.body, order.order_number
      assert_includes response.body, "LỊCH SỬ ĐƠN HÀNG"
    end

    test "khách hàng không có quyền truy cập quản lý khách hàng" do
      sign_out
      @admin.update!(is_admin: false)
      sign_in_as(@admin)

      get admin_customers_url

      assert_redirected_to root_url
    end

    test "admin không thể xem chi tiết tài khoản admin khác" do
      get admin_customer_url(@admin)

      assert_response :not_found
    end

    private

    def create_address
      Address.create!(
        user: @customer,
        label: "Địa chỉ nhà",
        recipient_name: "Nguyễn Văn An",
        phone: "0901234567",
        province: "TP. Hồ Chí Minh",
        ward: "Phường Bến Nghé",
        street_address: "123 Đường Nguyễn Huệ",
        is_default: true
      )
    end

    def create_order
      Order.create!(
        user: @customer,
        recipient_name: "Nguyễn Văn An",
        phone: "0901234567",
        province: "TP. Hồ Chí Minh",
        ward: "Phường Bến Nghé",
        street_address: "123 Đường Nguyễn Huệ",
        subtotal: 500_000,
        shipping_fee: 0,
        total: 500_000,
        payment_method: :cod,
        payment_status: :unpaid,
        status: :pending
      )
    end
  end
end
