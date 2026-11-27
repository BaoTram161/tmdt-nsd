module Api
  module V1
    class OrdersController < BaseController
      before_action :authenticate_api_user!
      before_action :set_order, only: %i[show payment_status]

      def index
        orders = Current.user.orders
                        .includes(:order_items)
                        .order(created_at: :desc)

        render json: {
          data: orders.map { |order| order_json(order) },
          total: orders.size
        }
      end

      def show
        render json: {
          data: order_json(@order)
        }
      end

      def payment_status
        render json: {
          order_number: @order.order_number,
          payment_method: @order.payment_method,
          payment_status: @order.payment_status,
          order_status: @order.status,
          paid: @order.paid?,
          expired: @order.payment_expires_at&.past? || false,
          expires_at: @order.payment_expires_at&.iso8601
        }
      end

      private

      def set_order
        @order = Current.user.orders
                        .includes(:order_items)
                        .find_by(id: params[:id])

        return if @order

        render json: {
          error: "not_found",
          message: "Không tìm thấy đơn hàng."
        }, status: :not_found
      end

      def order_json(order)
        {
          id: order.id,
          order_number: order.order_number,
          recipient_name: order.recipient_name,
          phone: order.phone,
          province: order.province,
          ward: order.ward,
          street_address: order.street_address,
          status: order.status,
          payment_method: order.payment_method,
          payment_status: order.payment_status,
          subtotal: order.subtotal,
          shipping_fee: order.shipping_fee,
          discount_amount: order.discount_amount,
          total: order.total,
          created_at: order.created_at.iso8601,
          items: order.order_items.map do |item|
            {
              product_id: item.product_id,
              product_name: item.product_name,
              quantity: item.quantity,
              unit_price: item.unit_price,
              total_price: item.total_price
            }
          end
        }
      end
    end
  end
end
