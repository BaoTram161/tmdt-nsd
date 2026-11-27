require "test_helper"

class ApiV1Test < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)

    @active_product = create_product(
      name: "Sản phẩm API đang hoạt động",
      active: true
    )

    @inactive_product = create_product(
      name: "Sản phẩm API đã ẩn",
      active: false
    )
  end

  # SẢN PHẨM

  test "API trả về danh sách sản phẩm đang hoạt động" do
    get api_v1_products_url

    assert_response :success

    data = JSON.parse(response.body)

    assert_equal 1, data["total"]
    assert_equal @active_product.id, data["data"].first["id"]
  end

  test "API không hiển thị sản phẩm đã bị ẩn" do
    get api_v1_products_url

    data = JSON.parse(response.body)

    product_ids = data["data"].map { |product| product["id"] }

    assert_not_includes product_ids, @inactive_product.id
  end

  test "API trả về chi tiết sản phẩm hợp lệ" do
    get api_v1_product_url(@active_product)

    assert_response :success

    data = JSON.parse(response.body)["data"]

    assert_equal @active_product.id, data["id"]
    assert_equal @active_product.name, data["name"]
    assert_equal @active_product.price.to_s, data["price"]
  end

  test "API trả về 404 khi sản phẩm không tồn tại" do
    get api_v1_product_url(99_999_999)

    assert_response :not_found

    data = JSON.parse(response.body)

    assert_equal "not_found", data["error"]
  end

  # ĐĂNG NHẬP VÀ ĐĂNG XUẤT

  test "API đăng nhập thành công và cấp Bearer token" do
    post api_v1_session_url, params: {
      email_address: @user.email_address,
      password: "password"
    }

    assert_response :created

    data = JSON.parse(response.body)

    assert_equal "Bearer", data["token_type"]
    assert data["access_token"].present?
    assert_equal @user.id, data.dig("user", "id")
    assert_equal 24.hours.to_i, data["expires_in"]
  end

  test "API trả về 401 khi đăng nhập sai mật khẩu" do
    post api_v1_session_url, params: {
      email_address: @user.email_address,
      password: "wrong-password"
    }

    assert_response :unauthorized

    data = JSON.parse(response.body)

    assert_equal "unauthorized", data["error"]
  end

  test "API đăng xuất và thu hồi quyền sử dụng token" do
    headers = authenticated_headers

    delete api_v1_session_url, headers: headers

    assert_response :success

    get api_v1_orders_url, headers: headers

    assert_response :unauthorized
  end

  # XÁC THỰC VÀ ĐƠN HÀNG

  test "API trả về 401 khi xem đơn hàng mà chưa đăng nhập" do
    get api_v1_orders_url

    assert_response :unauthorized
  end

  test "API trả về 401 khi sử dụng token không hợp lệ" do
    get api_v1_orders_url, headers: {
      "Authorization" => "Bearer invalid-token"
    }

    assert_response :unauthorized
  end

  test "API trả về 401 khi token đã hết hạn" do
    session = @user.sessions.create!

    expired_token = Rails.application.message_verifier(:api_auth).generate(
      session.id,
      expires_in: -1.minute,
      purpose: :api_auth
    )

    get api_v1_orders_url, headers: {
      "Authorization" => "Bearer #{expired_token}"
    }

    assert_response :unauthorized
  end

  test "API chỉ trả về đơn hàng của tài khoản đang đăng nhập" do
    own_order = create_order_for(@user)
    other_order = create_order_for(@other_user)

    get api_v1_orders_url, headers: authenticated_headers

    assert_response :success

    data = JSON.parse(response.body)

    order_numbers = data["data"].map { |order| order["order_number"] }

    assert_includes order_numbers, own_order.order_number
    assert_not_includes order_numbers, other_order.order_number
  end

  test "API trả về chi tiết đơn hàng của chính tài khoản" do
    order = create_order_for(@user)

    get api_v1_order_url(order), headers: authenticated_headers

    assert_response :success

    data = JSON.parse(response.body)["data"]

    assert_equal order.order_number, data["order_number"]
    assert_equal order.recipient_name, data["recipient_name"]
  end

  test "API trả về 404 khi truy cập đơn hàng của tài khoản khác" do
    order = create_order_for(@other_user)

    get api_v1_order_url(order), headers: authenticated_headers

    assert_response :not_found
  end

  test "API trả về 404 khi đơn hàng không tồn tại" do
    get api_v1_order_url(99_999_999), headers: authenticated_headers

    assert_response :not_found

    data = JSON.parse(response.body)

    assert_equal "not_found", data["error"]
  end

  test "API trả về trạng thái thanh toán VNPAY của đơn hàng" do
    order = create_order_for(@user)

    order.update!(
      payment_method: :vnpay,
      payment_status: :unpaid,
      payment_expires_at: 15.minutes.from_now
    )

    get payment_status_api_v1_order_url(order),
        headers: authenticated_headers

    assert_response :success

    data = JSON.parse(response.body)

    assert_equal order.order_number, data["order_number"]
    assert_equal "vnpay", data["payment_method"]
    assert_equal "unpaid", data["payment_status"]
    assert_equal false, data["paid"]
    assert_equal false, data["expired"]
  end

  private

  def create_product(name:, active:)
    Product.create!(
      category: categories(:one),
      name: name,
      description: "Sản phẩm dùng để kiểm thử API",
      price: 100_000,
      stock: 10,
      sold_count: 0,
      active: active,
      featured: false
    )
  end

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

  def authenticated_headers
    session = @user.sessions.create!

    token = Rails.application.message_verifier(:api_auth).generate(
      session.id,
      expires_in: 24.hours,
      purpose: :api_auth
    )

    {
      "Authorization" => "Bearer #{token}"
    }
  end
end
