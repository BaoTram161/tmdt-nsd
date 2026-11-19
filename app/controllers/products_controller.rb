class ProductsController < ApplicationController
  allow_unauthenticated_access

  def index
    @categories = Category.roots.includes(:children).order(:id)
    @products = Product.available.includes(:category).order(:id)

    filter_by_category
    filter_by_keyword
    filter_by_price
  end

  def show
    @product = Product.available.includes(:category).find(params[:id])
  end

  private

  def filter_by_category
    return if params[:category_id].blank?

    @category = Category.find_by(id: params[:category_id])

    if @category
      @products = @products.where(
        category_id: @category.self_and_children_ids
      )
    else
      @products = @products.none
    end
  end

  def filter_by_keyword
    keyword = params[:q].to_s.strip
    return if keyword.blank?

    escaped_keyword = ActiveRecord::Base.sanitize_sql_like(
      keyword.downcase
    )

    pattern = "%#{escaped_keyword}%"

    @products = @products.where(
      "LOWER(products.name) LIKE :keyword OR LOWER(products.description) LIKE :keyword",
      keyword: pattern
    )
  end

  def filter_by_price
    @min_price = params[:min_price].to_s.strip
    @max_price = params[:max_price].to_s.strip

    min_price = parse_price(@min_price)
    max_price = parse_price(@max_price)

    invalid_min = @min_price.present? && min_price.nil?
    invalid_max = @max_price.present? && max_price.nil?

    if invalid_min || invalid_max
      @price_error = "Vui lòng nhập khoảng giá hợp lệ."
      return
    end

    if min_price && max_price && min_price > max_price
      @price_error = "Giá tối thiểu không được lớn hơn giá tối đa."
      return
    end

    @products = @products.where("products.price >= ?", min_price) if min_price
    @products = @products.where("products.price <= ?", max_price) if max_price
  end

  def parse_price(value)
    return nil if value.blank?

    price = BigDecimal(value, exception: false)

    return nil unless price&.finite? && price >= 0

    price
  end
end