class ProductsController < ApplicationController
  def index
    @categories = Category.roots.includes(:children).order(:id)
    @products = Product.available.includes(:category).order(:id)

    if params[:category_id].present?
      @category = Category.find_by(id: params[:category_id])

      if @category
        @products = @products.where(
          category_id: @category.self_and_children_ids
        )
      else
        @products = @products.none
      end
    end

    if params[:q].present?
      keyword = "%#{params[:q].strip.downcase}%"

      @products = @products.where(
        "LOWER(products.name) LIKE :keyword OR LOWER(products.description) LIKE :keyword",
        keyword: keyword
      )
    end
  end

  def show
    @product = Product.available.includes(:category).find(params[:id])
  end
end