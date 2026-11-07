class HomeController < ApplicationController
  def index
    @categories = Category.roots.includes(:children).order(:id)

    @featured_products = Product.available.includes(:category).order(:id)

    @latest_products = Product.available.latest.includes(:category).limit(8)
  end
end
