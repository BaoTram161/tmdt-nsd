require "test_helper"

class WishlistsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)

    @product = Product.create!(
      category: categories(:one),
      name: "Sản phẩm yêu thích kiểm thử",
      description: "Sản phẩm dùng để kiểm thử wishlist",
      price: 100_000,
      image_url: "/test-product.jpg",
      stock: 10,
      sold_count: 0,
      featured: false,
      active: true
    )
  end

  test "hiển thị danh sách yêu thích" do
    post add_wishlist_item_url(@product)

    get wishlist_url

    assert_response :success
    assert_includes response.body, @product.name
  end

  test "thêm sản phẩm vào danh sách yêu thích" do
    post add_wishlist_item_url(@product)

    assert_redirected_to wishlist_path
    assert_includes session[:wishlist], @product.id.to_s
  end

  test "không thêm sản phẩm trùng lặp" do
    post add_wishlist_item_url(@product)
    post add_wishlist_item_url(@product)

    assert_equal 1, session[:wishlist].count(@product.id.to_s)
  end

  test "xóa sản phẩm khỏi danh sách yêu thích" do
    post add_wishlist_item_url(@product)

    assert_difference -> { session[:wishlist].length }, -1 do
      delete remove_wishlist_item_url(@product)
    end

    assert_redirected_to wishlist_path
  end

  test "không thêm sản phẩm đã ngừng kinh doanh" do
    @product.update!(active: false)

    post add_wishlist_item_url(@product)

    assert_response :not_found
  end

  # HIỂN THỊ DANH SÁCH

  test "hiển thị danh sách yêu thích trống" do
    get wishlist_url

    assert_response :success
    assert_not_includes response.body, @product.name
  end

  test "không hiển thị sản phẩm đã ngừng kinh doanh" do
    post add_wishlist_item_url(@product)
    @product.update!(active: false)

    get wishlist_url

    assert_response :success
    assert_not_includes response.body, @product.name
  end

  # XÓA SẢN PHẨM

  test "xóa sản phẩm không có trong danh sách không gây lỗi" do
    delete remove_wishlist_item_url(@product)

    assert_redirected_to wishlist_path
    assert_response :redirect
  end
end
