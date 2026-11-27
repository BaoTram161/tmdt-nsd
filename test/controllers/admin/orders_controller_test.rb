require "test_helper"

module Admin
  class OrdersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = users(:one)
      @admin.update!(is_admin: true)

      @customer = users(:two)
      @customer.update!(is_admin: false)

      sign_in_as(@admin)
    end

    test "admin có thể xem danh sách đơn hàng" do
      order = create_order

      get admin_orders_url

      assert_response :success
      assert_includes response.body, order.order_number
      assert_includes response.body, "QUẢN LÝ ĐƠN HÀNG"
    end

    test "admin có thể tìm kiếm đơn hàng theo tên người nhận" do
      order = create_order(recipient_name: "Nguyễn Văn An")
      other_order = create_order(recipient_name: "Trần Văn Bình")

      get admin_orders_url, params: { q: "Nguyễn Văn An" }

      assert_response :success
      assert_includes response.body, order.order_number
      assert_not_includes response.body, other_order.order_number
    end

    test "admin có thể tìm kiếm đơn hàng theo số điện thoại" do
      order = create_order(phone: "0901234567")
      other_order = create_order(phone: "0987654321")

      get admin_orders_url, params: { q: "0901234567" }

      assert_response :success
      assert_includes response.body, order.order_number
      assert_not_includes response.body, other_order.order_number
    end

    test "admin có thể lọc đơn hàng theo trạng thái" do
      pending_order = create_order(status: :pending)
      confirmed_order = create_order(status: :confirmed)

      get admin_orders_url, params: { status: "confirmed" }

      assert_response :success
      assert_includes response.body, confirmed_order.order_number
      assert_not_includes response.body, pending_order.order_number
    end

    test "admin có thể lọc đơn hàng theo phương thức thanh toán" do
      cod_order = create_order(payment_method: :cod)
      vnpay_order = create_order(payment_method: :vnpay)

      get admin_orders_url, params: { payment_method: "vnpay" }

      assert_response :success
      assert_includes response.body, vnpay_order.order_number
      assert_not_includes response.body, cod_order.order_number
    end

    test "admin có thể lọc đơn hàng theo trạng thái thanh toán" do
      unpaid_order = create_order(payment_status: :unpaid)
      paid_order = create_order(
        payment_method: :vnpay,
        payment_status: :paid
      )

      get admin_orders_url, params: { payment_status: "paid" }

      assert_response :success
      assert_includes response.body, paid_order.order_number
      assert_not_includes response.body, unpaid_order.order_number
    end

    test "admin có thể xem chi tiết đơn hàng" do
      order = create_order
      create_order_item(order)

      get admin_order_url(order)

      assert_response :success
      assert_includes response.body, order.order_number
      assert_includes response.body, "THÔNG TIN ĐƠN HÀNG"
      assert_includes response.body, "THÔNG TIN NHẬN HÀNG"
      assert_includes response.body, "SẢN PHẨM ĐÃ ĐẶT"
      assert_includes response.body, "TỔNG THANH TOÁN"
      assert_includes response.body, "Nhân sâm đen kiểm thử"
      assert_includes response.body, "Thanh toán khi nhận hàng (COD)"
      assert_includes response.body, "Chưa thanh toán"
    end

    test "admin có thể xem thông tin giao dịch VNPAY" do
      paid_at = Time.zone.parse("2026-11-26 16:09:00")

      order = create_order(
        payment_method: :vnpay,
        payment_status: :paid,
        vnpay_transaction_no: "15750168",
        paid_at: paid_at
      )

      get admin_order_url(order)

      assert_response :success
      assert_includes response.body, "Thanh toán trực tuyến qua VNPAY"
      assert_includes response.body, "Đã thanh toán"
      assert_includes response.body, "15750168"
      assert_includes response.body, "16:09 26/11/2026"
    end

    test "admin có thể cập nhật trạng thái đơn hàng" do
      order = create_order(status: :pending)

      patch admin_order_url(order), params: {
        order: { status: "confirmed" }
      }

      assert_redirected_to admin_order_url(order)
      assert_equal "confirmed", order.reload.status
      assert_equal "Đã cập nhật trạng thái đơn hàng.", flash[:notice]
    end

    test "cập nhật trạng thái đơn hàng không làm thay đổi thông tin thanh toán VNPAY" do
      order = create_order(
        payment_method: :vnpay,
        payment_status: :paid,
        vnpay_transaction_no: "15750168",
        paid_at: Time.zone.parse("2026-11-26 16:09:00")
      )

      patch admin_order_url(order), params: {
        order: { status: "confirmed" }
      }

      order.reload

      assert_redirected_to admin_order_url(order)
      assert_equal "confirmed", order.status
      assert_equal "paid", order.payment_status
      assert_equal "15750168", order.vnpay_transaction_no
      assert_equal Time.zone.parse("2026-11-26 16:09:00"), order.paid_at
    end

    test "admin không thể cập nhật trạng thái đơn hàng không hợp lệ" do
      order = create_order(status: :pending)

      patch admin_order_url(order), params: {
        order: { status: "invalid_status" }
      }

      assert_redirected_to admin_order_url(order)
      assert_equal "pending", order.reload.status
      assert_equal "Trạng thái đơn hàng không hợp lệ.", flash[:alert]
    end

    test "khách hàng không có quyền truy cập quản lý đơn hàng" do
      sign_out
      @admin.update!(is_admin: false)
      sign_in_as(@admin)

      get admin_orders_url

      assert_redirected_to root_url
    end

    private

    def create_order(attributes = {})
      Order.create!(
        {
          user: @customer,
          recipient_name: "Nguyễn Văn An",
          phone: "0901234567",
          province: "TP. Hồ Chí Minh",
          ward: "Phường Bến Nghé",
          street_address: "123 Đường Nguyễn Huệ",
          subtotal: 500_000,
          shipping_fee: 30_000,
          total: 530_000,
          payment_method: :cod,
          payment_status: :unpaid,
          status: :pending
        }.merge(attributes)
      )
    end

    def create_order_item(order)
      OrderItem.create!(
        order: order,
        product_name: "Nhân sâm đen kiểm thử",
        quantity: 2,
        unit_price: 250_000,
        total_price: 500_000
      )
    end
  end
end
