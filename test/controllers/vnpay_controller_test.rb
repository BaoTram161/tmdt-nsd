require "test_helper"

class VnpayControllerTest < ActionDispatch::IntegrationTest
  SECRET = "test-vnpay-secret"
  TMN_CODE = "TESTCODE"

  setup do
    @user = users(:one)

    @product = Product.create!(
      category: categories(:one),
      name: "Sản phẩm kiểm thử VNPAY",
      description: "Sản phẩm dùng để kiểm thử thanh toán",
      price: 100_000,
      image_url: "/test-product.jpg",
      stock: 8,
      sold_count: 2,
      featured: false,
      active: true
    )

    @order = @user.orders.create!(
      recipient_name: "Nguyễn Văn A",
      phone: "0901234567",
      province: "Tỉnh kiểm thử",
      ward: "Phường kiểm thử",
      street_address: "123 Đường kiểm thử",
      subtotal: 200_000,
      shipping_fee: 20_000,
      total: 220_000,
      payment_method: :vnpay,
      payment_status: :unpaid,
      status: :pending,
      payment_expires_at: 15.minutes.from_now
    )

    @order.order_items.create!(
      product: @product,
      product_name: @product.name,
      product_image: @product.image_url,
      quantity: 2,
      unit_price: 100_000,
      total_price: 200_000
    )
  end

  test "IPN hợp lệ cập nhật đơn hàng thành đã thanh toán" do
    with_vnpay_credentials do
      get vnpay_ipn_path, params: signed_params

      assert_response :success
      assert_equal "00", response_json["RspCode"]

      @order.reload

      assert_equal "paid", @order.payment_status
      assert_equal "pending", @order.status
      assert_equal "20123456", @order.vnpay_transaction_no
      assert_not_nil @order.paid_at

      assert_equal 8, @product.reload.stock
      assert_equal 2, @product.sold_count
    end
  end

  test "IPN sai chữ ký không cập nhật đơn hàng" do
    with_vnpay_credentials do
      params = signed_params
      params["vnp_Amount"] = "100"

      get vnpay_ipn_path, params: params

      assert_response :success
      assert_equal "97", response_json["RspCode"]

      assert_equal "unpaid", @order.reload.payment_status
      assert_equal 8, @product.reload.stock
    end
  end

  test "IPN sai số tiền không cập nhật đơn hàng" do
    with_vnpay_credentials do
      params = signed_params("vnp_Amount" => "100")

      get vnpay_ipn_path, params: params

      assert_response :success
      assert_equal "04", response_json["RspCode"]

      assert_equal "unpaid", @order.reload.payment_status
      assert_equal 8, @product.reload.stock
    end
  end

  test "IPN gửi lại không cập nhật giao dịch lần thứ hai" do
    with_vnpay_credentials do
      get vnpay_ipn_path, params: signed_params

      assert_equal "00", response_json["RspCode"]

      get vnpay_ipn_path, params: signed_params

      assert_equal "02", response_json["RspCode"]
      assert_equal "paid", @order.reload.payment_status
      assert_equal "20123456", @order.vnpay_transaction_no
    end
  end

  test "IPN thất bại hủy đơn và hoàn lại tồn kho" do
    with_vnpay_credentials do
      params = signed_params(
        "vnp_ResponseCode" => "24",
        "vnp_TransactionStatus" => "02"
      )

      get vnpay_ipn_path, params: params

      assert_response :success
      assert_equal "00", response_json["RspCode"]

      @order.reload

      assert_equal "failed", @order.payment_status
      assert_equal "cancelled", @order.status
      assert_equal 10, @product.reload.stock
      assert_equal 0, @product.sold_count
    end
  end

  test "IPN không tìm thấy đơn hàng" do
    with_vnpay_credentials do
      params = signed_params(
        "vnp_TxnRef" => "BG-NOT-FOUND"
      )

      get vnpay_ipn_path, params: params

      assert_response :success
      assert_equal "01", response_json["RspCode"]
    end
  end

  test "IPN không thể xác nhận đơn hàng COD" do
    @order.update!(payment_method: :cod)

    with_vnpay_credentials do
      get vnpay_ipn_path, params: signed_params

      assert_response :success
      assert_equal "01", response_json["RspCode"]
      assert_equal "unpaid", @order.reload.payment_status
    end
  end

  test "Return hợp lệ cập nhật đơn hàng thành đã thanh toán" do
    sign_in_as(@user)

    with_vnpay_credentials do
      get vnpay_return_path, params: signed_params

      assert_redirected_to order_path(@order)

      @order.reload

      assert_equal "paid", @order.payment_status
      assert_equal "20123456", @order.vnpay_transaction_no
      assert_not_nil @order.paid_at
    end
  end

  test "Return sai số tiền không cập nhật đơn hàng" do
    sign_in_as(@user)

    with_vnpay_credentials do
      get vnpay_return_path,
          params: signed_params("vnp_Amount" => "100")

      assert_redirected_to order_path(@order)
      assert_equal "unpaid", @order.reload.payment_status
    end
  end

  test "Return gửi lại không ghi nhận thanh toán lần thứ hai" do
    sign_in_as(@user)

    with_vnpay_credentials do
      get vnpay_return_path, params: signed_params

      assert_equal "paid", @order.reload.payment_status
      paid_at = @order.paid_at

      get vnpay_return_path, params: signed_params

      assert_redirected_to order_path(@order)
      assert_equal "paid", @order.reload.payment_status
      assert_equal paid_at, @order.paid_at
    end
  end

  private

  def with_vnpay_credentials
    application = Rails.application
    original_credentials = application.method(:credentials)

    application.define_singleton_method(:credentials) do
      {
        vnpay: {
          tmn_code: TMN_CODE,
          hash_secret: SECRET
        }
      }
    end

    yield
  ensure
    application.define_singleton_method(
      :credentials,
      original_credentials
    )
  end

  def signed_params(overrides = {})
    params = {
      "vnp_TmnCode" => TMN_CODE,
      "vnp_TxnRef" => @order.order_number,
      "vnp_Amount" => "22000000",
      "vnp_TransactionNo" => "20123456",
      "vnp_ResponseCode" => "00",
      "vnp_TransactionStatus" => "00"
    }.merge(overrides)

    params["vnp_SecureHash"] = VnpaySignatureService.generate(
      params,
      secret: SECRET
    )

    params
  end

  def response_json
    JSON.parse(response.body)
  end
end
