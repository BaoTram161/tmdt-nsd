class ReviewsController < ApplicationController
  before_action :set_product, only: %i[create update destroy]
  before_action :require_delivered_order, only: :create
  before_action :set_review, only: %i[update destroy]

  def index
    @reviews = Current.user.reviews
                      .includes(:product)
                      .order(created_at: :desc)
  end

  def create
    @review = Current.user.reviews.new(review_params)
    @review.product = @product

    if @review.save
      redirect_to product_path(@product, anchor: "reviews"),
                  notice: "Cảm ơn bạn đã đánh giá sản phẩm."
    else
      redirect_to product_path(@product, anchor: "reviews"),
                  alert: @review.errors.full_messages.to_sentence
    end
  end

  def update
    if @review.update(review_params)
      redirect_to product_path(@product, anchor: "reviews"),
                  notice: "Đánh giá đã được cập nhật."
    else
      redirect_to product_path(@product, anchor: "reviews"),
                  alert: @review.errors.full_messages.to_sentence
    end
  end

  def destroy
    @review.destroy

    redirect_to product_path(@product, anchor: "reviews"),
                notice: "Đánh giá đã được xóa."
  end

  private

  def set_product
    @product = Product.available.find(params[:product_id])
  end

  def set_review
    @review = Current.user.reviews.find_by!(
      id: params[:id],
      product_id: @product.id
    )
  end

  def require_delivered_order
    return if delivered_order_exists?

    redirect_to product_path(@product),
                alert: "Bạn chỉ có thể đánh giá sản phẩm sau khi đơn hàng đã được giao."
  end

  def delivered_order_exists?
    Current.user.orders
           .joins(:order_items)
           .where(status: :delivered, order_items: { product_id: @product.id })
           .exists?
  end

  def review_params
    params.require(:review).permit(:rating, :content)
  end
end
