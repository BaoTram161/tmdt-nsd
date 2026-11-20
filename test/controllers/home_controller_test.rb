require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  test "khách chưa đăng nhập vẫn xem được trang chủ" do
    get root_path

    assert_response :success
  end

  test "trang chủ hiển thị sản phẩm đang hoạt động" do
    product = create_home_product("Sản phẩm đang bán", true)

    get root_path

    assert_response :success
    assert_includes response.body, product.name
  end

  test "trang chủ không hiển thị sản phẩm ngừng kinh doanh" do
    product = create_home_product("Sản phẩm ngừng bán", false)

    get root_path

    assert_response :success
    assert_not_includes response.body, product.name
  end

  private

  def create_home_product(name, active)
    Product.create!(
      category: categories(:one),
      name: name,
      description: "Sản phẩm kiểm thử",
      price: 100_000,
      stock: 10,
      sold_count: 0,
      active: active
    )
  end
end
