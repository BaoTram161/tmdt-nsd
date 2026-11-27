require "test_helper"

class CheckoutsControllerTest < ActionDispatch::IntegrationTest
  SECRET = "test-vnpay-secret"
  TMN_CODE = "TESTCODE"

  setup do
    @user = users(:one)
    sign_in_as(@user)

    @product = Product.create!(
      category: categories(:one),
      name: "Sản phẩm kiểm thử checkout",
      description: "Sản phẩm dùng để kiểm thử đặt hàng",
      price: 100_000,
      image_url: "/test-product.jpg",
      stock: 10,
      sold_count: 0,
      featured: false,
      active: true
    )

    @address = @user.addresses.create!(
      label: "Nhà riêng",
      recipient_name: "Nguyễn Văn A",
      phone: "0901234567",
      province: "Tỉnh kiểm thử",
      ward: "Phường kiểm thử",
      street_address: "123 Đường kiểm thử",
      is_default: true
    )
  end

  test "đặt hàng COD thành công và cập nhật tồn kho" do
    post add_cart_item_url(@product), params: { quantity: 2 }

    post checkout_url, params: {
      address_id: @address.id,
      note: "Giao hàng giờ hành chính"
    }

    assert_response :created

    order = @user.orders.order(created_at: :desc).first
    assert_not_nil order

    assert_equal "cod", order.payment_method
    assert_equal "unpaid", order.payment_status
    assert_equal "pending", order.status

    assert_equal 200_000, order.subtotal
    assert_equal 20_000, order.shipping_fee
    assert_equal 0, order.discount_amount
    assert_equal 220_000, order.total

    assert_nil order.promotion_code

    assert_equal @address.recipient_name, order.recipient_name
    assert_equal @address.phone, order.phone
    assert_equal @address.province, order.province
    assert_equal @address.ward, order.ward
    assert_equal @address.street_address, order.street_address
    assert_equal "Giao hàng giờ hành chính", order.note

    order_item = order.order_items.sole

    assert_equal @product.id, order_item.product_id
    assert_equal @product.name, order_item.product_name
    assert_equal 100_000, order_item.unit_price
    assert_equal 2, order_item.quantity
    assert_equal 200_000, order_item.total_price

    @product.reload
    assert_equal 8, @product.stock
    assert_equal 2, @product.sold_count

    get checkout_url
    assert_redirected_to cart_path
  end

  test "đặt hàng VNPAY thành công và chuyển đến trang QR thanh toán" do
    post add_cart_item_url(@product), params: { quantity: 2 }

    with_vnpay_credentials do
      post checkout_url, params: {
        address_id: @address.id,
        payment_method: "vnpay"
      }

      order = @user.orders.order(created_at: :desc).first

      assert_not_nil order
      assert_redirected_to payment_order_url(order)

      assert_equal "vnpay", order.payment_method
      assert_equal "unpaid", order.payment_status
      assert_equal "pending", order.status
      assert_equal 220_000, order.total
      assert_not_nil order.payment_expires_at

      payment_url = VnpayPaymentService.new(
        order: order,
        ip_address: "127.0.0.1",
        return_url: "http://www.example.com/vnpay/return"
      ).payment_url

      payment_uri = URI.parse(payment_url)
      payment_params = URI.decode_www_form(payment_uri.query).to_h

      assert_equal URI.parse(VnpayPaymentService::PAYMENT_URL).host,
                   payment_uri.host
      assert_equal "TESTCODE", payment_params["vnp_TmnCode"]
      assert_equal "pay", payment_params["vnp_Command"]
      assert_equal "22000000", payment_params["vnp_Amount"]
      assert_equal "VND", payment_params["vnp_CurrCode"]

      refute payment_params.key?("vnp_BankCode")

      assert VnpaySignatureService.valid?(
        payment_params,
        secret: SECRET
      )

      @product.reload
      assert_equal 8, @product.stock
      assert_equal 2, @product.sold_count

      assert_nil session[:cart]
    end
  end

  test "không tạo đơn hàng và không trừ kho khi thiếu cấu hình VNPAY" do
    post add_cart_item_url(@product), params: { quantity: 2 }

    with_vnpay_credentials({}) do
      assert_no_difference -> { @user.orders.count } do
        post checkout_url, params: {
          address_id: @address.id,
          payment_method: "vnpay"
        }
      end

      assert_redirected_to checkout_path

      @product.reload
      assert_equal 10, @product.stock
      assert_equal 0, @product.sold_count

      assert_equal 2, session[:cart][@product.id.to_s]
    end
  end

  test "đặt hàng thành công với mã khuyến mãi và cập nhật lượt sử dụng" do
    post add_cart_item_url(@product), params: { quantity: 2 }

    promotion = create_promotion_code(
      code: "SAVE10",
      discount_type: "percentage",
      discount_value: 10
    )

    post apply_cart_promotion_url, params: { code: "SAVE10" }

    assert_redirected_to cart_path

    post checkout_url, params: {
      address_id: @address.id
    }

    assert_response :created

    order = @user.orders.order(created_at: :desc).first

    assert_not_nil order
    assert_equal "SAVE10", order.promotion_code

    assert_equal 200_000, order.subtotal
    assert_equal 20_000, order.discount_amount
    assert_equal 20_000, order.shipping_fee
    assert_equal 200_000, order.total

    assert_equal 1, promotion.reload.used_count

    @product.reload
    assert_equal 8, @product.stock
    assert_equal 2, @product.sold_count
  end

  test "không tăng lượt sử dụng mã khi đặt hàng thất bại" do
    post add_cart_item_url(@product), params: { quantity: 1 }

    promotion = create_promotion_code(
      code: "SAVE10",
      discount_type: "percentage",
      discount_value: 10
    )

    post apply_cart_promotion_url, params: { code: "SAVE10" }

    assert_redirected_to cart_path

    assert_no_difference -> { @user.orders.count } do
      post checkout_url, params: {
        address_id: -1
      }
    end

    assert_redirected_to checkout_path

    assert_equal 0, promotion.reload.used_count

    @product.reload
    assert_equal 10, @product.stock
    assert_equal 0, @product.sold_count
  end

  test "không tạo đơn hàng khi địa chỉ không hợp lệ" do
    post add_cart_item_url(@product), params: { quantity: 1 }

    assert_no_difference -> { @user.orders.count } do
      post checkout_url, params: {
        address_id: -1
      }
    end

    assert_redirected_to checkout_path

    @product.reload
    assert_equal 10, @product.stock
    assert_equal 0, @product.sold_count
  end

  test "không tạo đơn hàng khi tồn kho không đủ" do
    post add_cart_item_url(@product), params: { quantity: 2 }

    @product.update!(stock: 1)

    assert_no_difference -> { @user.orders.count } do
      post checkout_url, params: {
        address_id: @address.id
      }
    end

    assert_redirected_to checkout_path

    @product.reload
    assert_equal 1, @product.stock
    assert_equal 0, @product.sold_count
  end

  test "hiển thị trang thanh toán khi giỏ hàng hợp lệ" do
    post add_cart_item_url(@product), params: { quantity: 2 }

    get checkout_url

    assert_response :success
    assert_includes response.body, @product.name
    assert_includes response.body, @address.recipient_name
  end

  test "không mở trang thanh toán khi giỏ hàng trống" do
    get checkout_url

    assert_redirected_to cart_path
  end

  test "không thanh toán sản phẩm đã ngừng kinh doanh" do
    post add_cart_item_url(@product), params: { quantity: 1 }
    @product.update!(active: false)

    get checkout_url

    assert_redirected_to cart_path
  end

  test "không thanh toán khi tồn kho không đủ" do
    post add_cart_item_url(@product), params: { quantity: 3 }
    @product.update!(stock: 2)

    get checkout_url

    assert_redirected_to cart_path
  end

  private

  def with_vnpay_credentials(values = {
    tmn_code: TMN_CODE,
    hash_secret: SECRET
  })
    application = Rails.application
    original_credentials = application.method(:credentials)

    application.define_singleton_method(:credentials) do
      { vnpay: values }
    end

    yield
  ensure
    application.define_singleton_method(
      :credentials,
      original_credentials
    )
  end

  def create_promotion_code(attributes = {})
    PromotionCode.create!(
      {
        code: "SAVE10",
        discount_type: "percentage",
        discount_value: 10,
        minimum_order_value: 0,
        active: true,
        used_count: 0
      }.merge(attributes)
    )
  end
end
