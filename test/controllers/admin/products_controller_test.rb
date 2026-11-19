require "test_helper"

module Admin
  class ProductsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = users(:one)
      @admin.update!(is_admin: true)
      sign_in_as(@admin)

      @category = categories(:one)
    end

    test "admin có thể xem danh sách sản phẩm" do
      product = create_product(name: "Nhân sâm đen kiểm thử")

      get admin_products_url

      assert_response :success
      assert_includes response.body, product.name
    end

    test "khách hàng không có quyền truy cập quản lý sản phẩm" do
      sign_out
      @admin.update!(is_admin: false)
      sign_in_as(@admin)

      get admin_products_url

      assert_redirected_to root_url
    end

    test "admin có thể tìm kiếm sản phẩm" do
      product = create_product(name: "Nhân sâm đen đặc biệt")
      create_product(name: "Sản phẩm khác")

      get admin_products_url, params: { q: "đặc biệt" }

      assert_response :success
      assert_includes response.body, product.name
      assert_not_includes response.body, "Sản phẩm khác"
    end

    test "admin có thể lọc sản phẩm theo danh mục" do
      product = create_product(
        name: "Sản phẩm danh mục một",
        category: categories(:one)
      )
      create_product(
        name: "Sản phẩm danh mục hai",
        category: categories(:two)
      )

      get admin_products_url, params: {
        category_id: categories(:one).id
      }

      assert_response :success
      assert_includes response.body, product.name
      assert_not_includes response.body, "Sản phẩm danh mục hai"
    end

    test "admin có thể thêm sản phẩm mới" do
      assert_difference("Product.count", 1) do
        post admin_products_url, params: {
          product: {
            name: "Nhân sâm đen mới",
            description: "Sản phẩm kiểm thử",
            price: 500_000,
            original_price: 600_000,
            stock: 20,
            sold_count: 0,
            brand: "BLACK GINSENG",
            category_id: @category.id,
            active: true,
            featured: false
          }
        }
      end

      assert_redirected_to admin_products_url

      product = Product.find_by!(name: "Nhân sâm đen mới")
      assert_equal 500_000, product.price
      assert_equal 20, product.stock
    end

    test "admin có thể chỉnh sửa sản phẩm" do
      product = create_product(name: "Sản phẩm trước khi sửa")

      patch admin_product_url(product), params: {
        product: {
          name: "Sản phẩm sau khi sửa",
          price: 750_000,
          stock: 15
        }
      }

      assert_redirected_to admin_products_url

      product.reload
      assert_equal "Sản phẩm sau khi sửa", product.name
      assert_equal 750_000, product.price
      assert_equal 15, product.stock
    end

    test "admin có thể ẩn và hiển thị lại sản phẩm" do
      product = create_product(active: true)

      patch toggle_active_admin_product_url(product)

      assert_redirected_to admin_products_url
      assert_not product.reload.active?

      patch toggle_active_admin_product_url(product)

      assert_redirected_to admin_products_url
      assert product.reload.active?
    end

    private

    def create_product(attributes = {})
      Product.create!(
        {
          name: "Sản phẩm kiểm thử #{SecureRandom.hex(4)}",
          description: "Sản phẩm dùng trong kiểm thử Admin",
          price: 100_000,
          stock: 10,
          sold_count: 0,
          featured: false,
          active: true,
          brand: "BLACK GINSENG",
          category: @category
        }.merge(attributes)
      )
    end
  end
end
