module Admin
  class DashboardController < BaseController
    def index
      @total_orders = Order.count
      @pending_orders = Order.pending.count
      @total_products = Product.count
      @total_customers = User.where(is_admin: false).count

      @recent_orders = Order.includes(:user)
                            .order(created_at: :desc)
                            .limit(5)
    end
  end
end
