class VnpayController < ApplicationController
  allow_unauthenticated_access only: %i[ipn payment_return]

  def ipn
    credentials = Rails.application.credentials.dig(:vnpay) || {}
    params = request.query_parameters

    unless VnpaySignatureService.valid?(
      params,
      secret: credentials[:hash_secret]
    )
      return render_ipn_response("97", "Invalid signature")
    end

    unless params["vnp_TmnCode"] == credentials[:tmn_code]
      return render_ipn_response("97", "Invalid merchant")
    end

    response = nil

    ActiveRecord::Base.transaction do
      order = Order.lock.find_by(order_number: params["vnp_TxnRef"])

      if order.nil? || order.payment_method != "vnpay"
        response = [ "01", "Order not found" ]
      elsif order.payment_status != "unpaid" || order.cancelled?
        response = [ "02", "Order already confirmed" ]
      elsif valid_amount?(order, params["vnp_Amount"])
        if successful_transaction?(params)
          transaction_no = params["vnp_TransactionNo"]

          if transaction_no.blank?
            response = [ "99", "Missing transaction number" ]
          else
            order.update!(
              payment_status: :paid,
              vnpay_transaction_no: transaction_no,
              paid_at: Time.current
            )

            response = [ "00", "Confirm Success" ]
          end
        else
          cancel_failed_order!(order)
          response = [ "00", "Confirm Success" ]
        end
      else
        response = [ "04", "Invalid amount" ]
      end
    end

    render_ipn_response(*response)
  rescue StandardError => e
    Rails.logger.error(
      "VNPAY IPN error: #{e.class} - #{e.message}"
    )

    render_ipn_response("99", "Unknown error")
  end

  def payment_return
    resume_session

    credentials = Rails.application.credentials.dig(:vnpay) || {}
    params = request.query_parameters

    unless VnpaySignatureService.valid?(
      params,
      secret: credentials[:hash_secret]
    )
      return redirect_to root_path,
                         alert: "Thông tin thanh toán không hợp lệ."
    end

    unless params["vnp_TmnCode"] == credentials[:tmn_code]
      return redirect_to root_path,
                         alert: "Thông tin Merchant không hợp lệ."
    end

    unless Current.user
      return redirect_to new_session_path,
                         alert: "Vui lòng đăng nhập để xem đơn hàng."
    end

    order = Current.user.orders.find_by(
      order_number: params["vnp_TxnRef"],
      payment_method: :vnpay
    )

    unless order
      return redirect_to root_path,
                         alert: "Không tìm thấy đơn hàng."
    end

    if order.payment_status == "paid"
      redirect_to order_path(order),
                  notice: "Thanh toán đơn hàng thành công."
    else
      redirect_to order_path(order),
                  alert: "Thanh toán chưa hoàn tất. Vui lòng kiểm tra trạng thái đơn hàng."
    end
  end

  private

  def valid_amount?(order, received_amount)
    amount = Integer(received_amount, 10)
    expected_amount = (order.total.to_d * 100).to_i

    amount == expected_amount
  rescue ArgumentError, TypeError
    false
  end

  def successful_transaction?(params)
    params["vnp_ResponseCode"] == "00" &&
      params["vnp_TransactionStatus"] == "00"
  end

  def cancel_failed_order!(order)
    order.update!(
      payment_status: :failed,
      status: :cancelled
    )

    order.order_items.order(:id).includes(:product).each do |item|
      product = item.product
      next unless product

      product.with_lock do
        product.update!(
          stock: product.stock.to_i + item.quantity,
          sold_count: [
            product.sold_count.to_i - item.quantity,
            0
          ].max
        )
      end
    end

    promotion = PromotionCode.lock.find_by(
      code: order.promotion_code
    )

    if promotion && promotion.used_count.to_i.positive?
      promotion.decrement!(:used_count)
    end
  end

  def render_ipn_response(code, message)
    render json: {
      RspCode: code,
      Message: message
    }
  end
end
