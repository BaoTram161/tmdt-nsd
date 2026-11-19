module Admin
  class CustomersController < BaseController
    def index
      @customers = User.where(is_admin: false)
                       .includes(:orders)
                       .order(created_at: :desc)

      if params[:q].present?
        keyword = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"

        @customers = @customers.where(
          "full_name LIKE :q OR email_address LIKE :q OR phone LIKE :q",
          q: keyword
        )
      end
    end
  end
end
