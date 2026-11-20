require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product = Product.create!(
      category: categories(:one),
      name: "Nhân sâm đen kiểm thử",
      description: "Sản phẩm dùng để kiểm thử",
      price: 100_000,
      image_url: "/test-product.jpg",
      stock: 10,
      sold_count: 0,
      featured: false,
      active: true
    )
  end

  test "hiển thị danh sách sản phẩm đang bán" do
    get products_url

    assert_response :success
    assert_includes response.body, @product.name
  end

  test "hiển thị chi tiết sản phẩm" do
    get product_url(@product)

    assert_response :success
    assert_includes response.body, @product.name
  end

  test "tìm kiếm sản phẩm theo từ khóa" do
    get products_url, params: { q: "Nhân sâm đen kiểm thử" }

    assert_response :success
    assert_includes response.body, @product.name
  end

  test "lọc sản phẩm theo khoảng giá" do
    get products_url, params: {
      min_price: "50000",
      max_price: "150000"
    }

    assert_response :success
    assert_includes response.body, @product.name
  end

  test "không hiển thị sản phẩm ngừng kinh doanh" do
    inactive_product = Product.create!(
      category: categories(:one),
      name: "Sản phẩm đã ngừng bán",
      description: "Sản phẩm không hoạt động",
      price: 100_000,
      image_url: "/test-product.jpg",
      stock: 10,
      sold_count: 0,
      featured: false,
      active: false
    )

    get products_url

    assert_response :success
    assert_not_includes response.body, inactive_product.name
  end

  test "không tìm thấy sản phẩm không còn khả dụng" do
    @product.update!(active: false)

    get product_url(@product)

    assert_response :not_found
  end

  # LỌC DANH MỤC

  test "lọc sản phẩm theo danh mục" do
    get products_url, params: { category_id: categories(:one).id }

    assert_response :success
    assert_includes response.body, @product.name
  end

  test "không hiển thị sản phẩm khi danh mục không tồn tại" do
    get products_url, params: { category_id: -1 }

    assert_response :success
    assert_not_includes response.body, @product.name
  end

  # LỌC GIÁ

  test "không lọc khi giá tối thiểu lớn hơn giá tối đa" do
    get products_url, params: {
      min_price: "200000",
      max_price: "100000"
    }

    assert_response :success
    assert_includes response.body, "Giá tối thiểu không được lớn hơn giá tối đa."
  end

  test "hiển thị lỗi khi giá nhập không hợp lệ" do
    get products_url, params: { min_price: "abc" }

    assert_response :success
    assert_includes response.body, "Vui lòng nhập khoảng giá hợp lệ."
  end

  test "không chấp nhận giá âm" do
    get products_url, params: { min_price: "-100" }

    assert_response :success
    assert_includes response.body, "Vui lòng nhập khoảng giá hợp lệ."
  end

  # TÌM KIẾM

  test "tìm kiếm không phân biệt chữ hoa chữ thường" do
    get products_url, params: { q: "NHÂN SÂM ĐEN KIỂM THỬ" }

    assert_response :success
    assert_includes response.body, @product.name
  end
end
