module Admin
  class OrdersController < BaseController
    before_action :set_order, only: %i[show update]

    def index
      @orders = Order.includes(:user, :order_items)
                     .order(created_at: :desc)

      if params[:status].present? && Order.statuses.key?(params[:status])
        @orders = @orders.where(status: params[:status])
      end

      keyword = params[:q].to_s.strip

      if keyword.present?
        keyword = "%#{ActiveRecord::Base.sanitize_sql_like(keyword)}%"

        @orders = @orders.where(
          "order_number LIKE :q OR recipient_name LIKE :q OR phone LIKE :q",
          q: keyword
        )
      end
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

    def set_order
      @order = Order.includes(:user, :order_items).find(params[:id])
    end

    def order_params
      params.require(:order).permit(:status)
    end
  end
end
