module Admin
  class OrdersController < BaseController
    before_action :set_order, only: %i[show update]

    def index
      @orders = Order.includes(:user, :order_items)
                     .order(created_at: :desc)

      filter_orders
    end

    def show
    end

    def update
      new_status = order_params[:status]

      unless Order.statuses.key?(new_status)
        redirect_to admin_order_path(@order),
                    alert: "Trạng thái đơn hàng không hợp lệ."
        return
      end

      if @order.update(status: new_status)
        redirect_to admin_order_path(@order),
                    notice: "Đã cập nhật trạng thái đơn hàng."
      else
        redirect_to admin_order_path(@order),
                    alert: "Không thể cập nhật đơn hàng."
      end
    end

    private

    def filter_orders
      if Order.statuses.key?(params[:status])
        @orders = @orders.where(status: params[:status])
      end

      if Order.payment_methods.key?(params[:payment_method])
        @orders = @orders.where(payment_method: params[:payment_method])
      end

      if Order.payment_statuses.key?(params[:payment_status])
        @orders = @orders.where(payment_status: params[:payment_status])
      end

      keyword = params[:q].to_s.strip
      return if keyword.blank?

      keyword = "%#{ActiveRecord::Base.sanitize_sql_like(keyword)}%"

      @orders = @orders.where(
        "order_number LIKE :q OR recipient_name LIKE :q OR phone LIKE :q",
        q: keyword
      )
    end

    def set_order
      @order = Order.includes(:user, :order_items).find(params[:id])
    end

    def order_params
      params.require(:order).permit(:status)
    end
  end
end
