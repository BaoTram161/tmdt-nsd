module Admin
  class ReviewsController < BaseController
    before_action :set_review, only: :destroy

    def index
      @reviews = Review.includes(:user, :product)
                       .joins(:user, :product)
                       .order(created_at: :desc)

      if params[:q].present?
        keyword = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip.downcase)}%"

        @reviews = @reviews.where(
          "LOWER(users.full_name) LIKE :q OR " \
          "LOWER(users.email_address) LIKE :q OR " \
          "LOWER(products.name) LIKE :q OR " \
          "LOWER(reviews.content) LIKE :q",
          q: keyword
        )
      end

      if params[:rating].present? && (1..5).cover?(params[:rating].to_i)
        @reviews = @reviews.where(rating: params[:rating].to_i)
      end

      @total_reviews = Review.count
      @average_rating = Review.average(:rating)&.round(1)
      @filtered_reviews_count = @reviews.size
    end

    def destroy
      @review.destroy

      redirect_to admin_reviews_path(
        q: params[:q],
        rating: params[:rating]
      ), notice: "Đánh giá đã được xóa thành công."
    end

    private

    def set_review
      @review = Review.find(params[:id])
    end
  end
end
