require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)

    sign_in_as(@user)
  end

  test "chỉ hiển thị đơn hàng của tài khoản đang đăng nhập" do
    own_order = create_order_for(@user)
    other_order = create_order_for(@other_user)

    get orders_url

    assert_response :success
    assert_includes response.body, own_order.order_number
    assert_not_includes response.body, other_order.order_number
  end

  test "người dùng có thể xem chi tiết đơn hàng của mình" do
    order = create_order_for(@user)

    get order_url(order)

    assert_response :success
    assert_includes response.body, order.order_number
    assert_includes response.body, order.recipient_name
  end

  test "người dùng không thể xem đơn hàng của tài khoản khác" do
    other_order = create_order_for(@other_user)

    get order_url(other_order)

    assert_response :not_found
  end

  # DANH SÁCH ĐƠN HÀNG

  test "hiển thị danh sách trống khi chưa có đơn hàng" do
    get orders_url

    assert_response :success
  end

  test "sắp xếp đơn hàng mới nhất lên trước" do
    older_order = create_order_for(@user)
    newer_order = create_order_for(@user)

    older_order.update!(created_at: 2.days.ago)
    newer_order.update!(created_at: 1.day.ago)

    get orders_url

    assert_response :success
    assert_operator response.body.index(newer_order.order_number),
                    :<,
                    response.body.index(older_order.order_number)
  end

  private

  def create_order_for(user)
    user.orders.create!(
      recipient_name: "Nguyễn Văn A",
      phone: "0901234567",
      province: "Tỉnh kiểm thử",
      ward: "Phường kiểm thử",
      street_address: "123 Đường kiểm thử",
      subtotal: 100_000,
      shipping_fee: 20_000,
      total: 120_000,
      payment_method: :cod,
      payment_status: :unpaid,
      status: :pending
    )
  end
end
