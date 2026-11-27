module Api
  module V1
    class ProductsController < BaseController
      def index
        products = Product.available
                          .includes(:category)
                          .order(:id)

        render json: {
          data: products.map { |product| product_json(product) },
          total: products.size
        }
      end

      def show
        product = Product.available
                          .includes(:category)
                          .find_by(id: params[:id])

        unless product
          return render json: {
            error: "not_found",
            message: "Không tìm thấy sản phẩm."
          }, status: :not_found
        end

        render json: {
          data: product_json(product)
        }
      end

      private

      def product_json(product)
        {
          id: product.id,
          name: product.name,
          description: product.description,
          price: product.price,
          original_price: product.original_price,
          image_url: product.image_url,
          origin: product.origin,
          packaging: product.packaging,
          stock: product.stock,
          sold_count: product.sold_count,
          featured: product.featured,
          on_sale: product.on_sale?,
          discount_percent: product.discount_percent,
          category: {
            id: product.category.id,
            name: product.category.name
          }
        }
      end
    end
  end
end
