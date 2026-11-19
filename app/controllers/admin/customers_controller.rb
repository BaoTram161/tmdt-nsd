module Admin
  class CustomersController < BaseController
    before_action :set_customer, only: :show

    def index
      @customers = User.where(is_admin: false)
                       .includes(:orders)
                       .order(created_at: :desc)

      return unless params[:q].present?

      keyword = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"

      @customers = @customers.where(
        "full_name LIKE :q OR email_address LIKE :q OR phone LIKE :q",
        q: keyword
      )
    end

    def show
      @addresses = @customer.addresses.order(
        is_default: :desc,
        created_at: :desc
      )

      @orders = @customer.orders
                         .includes(:order_items)
                         .order(created_at: :desc)
    end

    private

    def set_customer
      @customer = User.where(is_admin: false).find(params[:id])
    end
  end
end
