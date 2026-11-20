require "test_helper"

class CartsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)

    @product = Product.create!(
      category: categories(:one),
      name: "Sản phẩm kiểm thử giỏ hàng",
      description: "Sản phẩm dùng để kiểm thử giỏ hàng",
      price: 100_000,
      image_url: "/test-product.jpg",
      stock: 10,
      sold_count: 0,
      featured: false,
      active: true
    )
  end

  # HIỂN THỊ GIỎ HÀNG

  test "hiển thị giỏ hàng có sản phẩm" do
    add_product_to_cart

    get cart_url

    assert_response :success
    assert_includes response.body, @product.name
  end

  test "hiển thị giỏ hàng trống" do
    get cart_url

    assert_response :success
  end

  # THÊM SẢN PHẨM

  test "thêm sản phẩm vào giỏ hàng thành công" do
    post add_cart_item_url(@product), params: { quantity: 2 }

    assert_redirected_to cart_path
    assert_equal 2, session[:cart][@product.id.to_s]
  end

  test "thêm cùng sản phẩm nhiều lần thì cộng số lượng" do
    post add_cart_item_url(@product), params: { quantity: 2 }
    post add_cart_item_url(@product), params: { quantity: 3 }

    assert_equal 5, session[:cart][@product.id.to_s]
  end

  test "không thêm sản phẩm vượt quá tồn kho" do
    post add_cart_item_url(@product), params: { quantity: 11 }

    assert_redirected_to cart_path
    assert_nil session[:cart][@product.id.to_s]
  end

  test "không thêm sản phẩm khi số lượng mới vượt tồn kho" do
    post add_cart_item_url(@product), params: { quantity: 8 }
    post add_cart_item_url(@product), params: { quantity: 3 }

    assert_equal 8, session[:cart][@product.id.to_s]
  end

  test "không thêm sản phẩm đã hết hàng" do
    @product.update!(stock: 0)

    post add_cart_item_url(@product), params: { quantity: 1 }

    assert_redirected_to cart_path
    assert_nil session[:cart][@product.id.to_s]
  end

  test "không thêm sản phẩm với số lượng không hợp lệ" do
    post add_cart_item_url(@product), params: { quantity: "abc" }

    assert_redirected_to cart_path

    follow_redirect!
    assert_response :success
    assert_includes response.body, "Số lượng sản phẩm không hợp lệ."
  end

  test "không thêm sản phẩm đã ngừng kinh doanh" do
    @product.update!(active: false)

    post add_cart_item_url(@product), params: { quantity: 1 }

    assert_response :not_found
  end

  # CẬP NHẬT SỐ LƯỢNG

  test "cập nhật số lượng sản phẩm thành công" do
    post add_cart_item_url(@product), params: { quantity: 2 }

    patch update_cart_item_url(@product), params: { quantity: 5 }

    assert_redirected_to cart_path
    assert_equal 5, session[:cart][@product.id.to_s]
  end

  test "không cập nhật số lượng vượt tồn kho" do
    post add_cart_item_url(@product), params: { quantity: 2 }

    patch update_cart_item_url(@product), params: { quantity: 11 }

    assert_redirected_to cart_path
    assert_equal 2, session[:cart][@product.id.to_s]
  end

  test "không cập nhật số lượng với dữ liệu không hợp lệ" do
    post add_cart_item_url(@product), params: { quantity: 2 }

    patch update_cart_item_url(@product), params: { quantity: "abc" }

    assert_redirected_to cart_path
    assert_equal 2, session[:cart][@product.id.to_s]
  end

  test "cập nhật số lượng bằng không thì xóa sản phẩm" do
    post add_cart_item_url(@product), params: { quantity: 2 }

    patch update_cart_item_url(@product), params: { quantity: 0 }

    assert_redirected_to cart_path
    assert_nil session[:cart][@product.id.to_s]
  end

  test "không cập nhật sản phẩm đã hết hàng" do
    post add_cart_item_url(@product), params: { quantity: 2 }
    @product.update!(stock: 0)

    patch update_cart_item_url(@product), params: { quantity: 3 }

    assert_redirected_to cart_path
    assert_equal 2, session[:cart][@product.id.to_s]
  end

  test "xử lý sản phẩm không còn tồn tại trong giỏ hàng" do
    post add_cart_item_url(@product), params: { quantity: 2 }
    @product.destroy!

    patch update_cart_item_url(@product.id), params: { quantity: 3 }

    assert_redirected_to cart_path

    follow_redirect!
    assert_response :success
    assert_not_includes response.body, @product.name
  end

  # XÓA SẢN PHẨM

  test "xóa sản phẩm khỏi giỏ hàng" do
    post add_cart_item_url(@product), params: { quantity: 2 }

    delete remove_cart_item_url(@product)

    assert_redirected_to cart_path
    assert_nil session[:cart][@product.id.to_s]
  end

  # MÃ KHUYẾN MÃI

  test "áp dụng mã khuyến mãi hợp lệ thành công" do
    add_product_to_cart
    create_promotion_code(code: "SAVE10")

    post apply_cart_promotion_url, params: { code: "SAVE10" }

    assert_redirected_to cart_path
    assert_equal "SAVE10", session[:promotion_code]
  end

  test "không áp dụng mã khuyến mãi không tồn tại" do
    add_product_to_cart

    post apply_cart_promotion_url, params: { code: "NOTFOUND" }

    assert_redirected_to cart_path
    assert_nil session[:promotion_code]
  end

  test "không áp dụng mã khi giỏ hàng trống" do
    create_promotion_code(code: "SAVE10")

    post apply_cart_promotion_url, params: { code: "SAVE10" }

    assert_redirected_to cart_path
    assert_nil session[:promotion_code]
  end

  test "không áp dụng mã khi chưa đạt giá trị đơn hàng tối thiểu" do
    add_product_to_cart

    create_promotion_code(
      code: "SAVE10",
      minimum_order_value: 200_000
    )

    post apply_cart_promotion_url, params: { code: "SAVE10" }

    assert_redirected_to cart_path
    assert_nil session[:promotion_code]
  end

  test "không áp dụng mã đã bị tạm ngưng" do
    add_product_to_cart

    create_promotion_code(
      code: "SAVE10",
      active: false
    )

    post apply_cart_promotion_url, params: { code: "SAVE10" }

    assert_redirected_to cart_path
    assert_nil session[:promotion_code]
  end

  test "không áp dụng mã đã hết hạn" do
    add_product_to_cart

    create_promotion_code(
      code: "SAVE10",
      expires_at: 1.day.ago
    )

    post apply_cart_promotion_url, params: { code: "SAVE10" }

    assert_redirected_to cart_path
    assert_nil session[:promotion_code]
  end

  test "không áp dụng mã đã hết lượt sử dụng" do
    add_product_to_cart

    create_promotion_code(
      code: "SAVE10",
      usage_limit: 5,
      used_count: 5
    )

    post apply_cart_promotion_url, params: { code: "SAVE10" }

    assert_redirected_to cart_path
    assert_nil session[:promotion_code]
  end

  test "gỡ mã khuyến mãi khỏi giỏ hàng" do
    add_product_to_cart
    create_promotion_code(code: "SAVE10")

    post apply_cart_promotion_url, params: { code: "SAVE10" }

    assert_equal "SAVE10", session[:promotion_code]

    delete remove_cart_promotion_url

    assert_redirected_to cart_path
    assert_nil session[:promotion_code]
  end

  private

  def add_product_to_cart
    post add_cart_item_url(@product), params: { quantity: 1 }
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
