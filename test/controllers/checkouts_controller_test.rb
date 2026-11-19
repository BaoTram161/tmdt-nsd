require "test_helper"

class CheckoutsControllerTest < ActionDispatch::IntegrationTest
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

    # Kiểm tra thông tin đơn hàng
    assert_equal "cod", order.payment_method
    assert_equal "unpaid", order.payment_status
    assert_equal "pending", order.status

    # Kiểm tra tổng tiền và phí vận chuyển
    assert_equal 200_000, order.subtotal
    assert_equal 20_000, order.shipping_fee
    assert_equal 220_000, order.total

    # Kiểm tra thông tin người nhận được lưu vào đơn hàng
    assert_equal @address.recipient_name, order.recipient_name
    assert_equal @address.phone, order.phone
    assert_equal @address.province, order.province
    assert_equal @address.ward, order.ward
    assert_equal @address.street_address, order.street_address
    assert_equal "Giao hàng giờ hành chính", order.note

    # Kiểm tra thông tin sản phẩm tại thời điểm đặt hàng
    order_item = order.order_items.sole

    assert_equal @product.id, order_item.product_id
    assert_equal @product.name, order_item.product_name
    assert_equal 100_000, order_item.unit_price
    assert_equal 2, order_item.quantity
    assert_equal 200_000, order_item.total_price

    # Kiểm tra tồn kho và số lượng đã bán
    @product.reload
    assert_equal 8, @product.stock
    assert_equal 2, @product.sold_count

    # Giỏ hàng đã được xóa sau khi đặt hàng
    get checkout_url
    assert_redirected_to cart_path
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

    # Giả lập sản phẩm chỉ còn 1 sản phẩm sau khi đã thêm vào giỏ
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
end
