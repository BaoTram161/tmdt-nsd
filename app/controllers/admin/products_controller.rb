module Admin
  class ProductsController < BaseController
    before_action :set_product, only: %i[edit update toggle_active]

    def index
      @products = Product.includes(:category).order(created_at: :desc)
      @categories = Category.includes(:parent).order(:name)

      if params[:q].present?
        keyword = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"

        @products = @products.left_joins(:category).where(
          "products.name LIKE :q OR products.brand LIKE :q OR categories.name LIKE :q",
          q: keyword
        )
      end

      if params[:category_id].present?
        @products = @products.where(category_id: params[:category_id])
      end

      case params[:active]
      when "active"
        @products = @products.where(active: true)
      when "inactive"
        @products = @products.where(active: false)
      end
    end

    def new
      @product = Product.new(stock: 0, active: true, featured: false)
      load_categories
    end

    def create
      @product = Product.new(product_params)

      if @product.save
        redirect_to admin_products_path, notice: "Đã thêm sản phẩm thành công."
      else
        load_categories
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_categories
    end

    def update
      if @product.update(product_params)
        redirect_to admin_products_path, notice: "Đã cập nhật sản phẩm thành công."
      else
        load_categories
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle_active
      @product.update!(active: !@product.active?)

      message = @product.active? ? "Đã hiển thị sản phẩm." : "Đã ẩn sản phẩm."

      redirect_to admin_products_path, notice: message
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def load_categories
      @categories = Category.includes(:parent).order(:name)
    end

    def product_params
      params.require(:product).permit(
        :name,
        :description,
        :price,
        :original_price,
        :image_url,
        :origin,
        :packaging,
        :stock,
        :featured,
        :active,
        :category_id,
        :brand
      )
    end
  end
end
