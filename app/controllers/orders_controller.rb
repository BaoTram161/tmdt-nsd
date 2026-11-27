class OrdersController < ApplicationController
  PAYMENT_DURATION = 15.minutes

  before_action :set_order,
                only: %i[show payment payment_status retry_payment]

  def index
    @orders = Current.user.orders
                     .includes(:order_items)
                     .order(created_at: :desc)
  end

  def show
  end

  def payment
    unless @order.vnpay? && @order.unpaid? && @order.pending?
      return redirect_to order_path(@order),
                         alert: "Đơn hàng không thể thực hiện thanh toán VNPAY."
    end

    if @order.payment_expires_at&.past?
      @payment_expired = true
      return render :payment
    end

    @payment_url = build_payment_url

    @qr_svg = RQRCode::QRCode.new(@payment_url).as_svg(
      module_size: 6,
      color: "123D2B",
      fill: "FFFFFF",
      standalone: true,
      use_path: true
    )
  rescue VnpayPaymentService::ConfigurationError => e
    redirect_to order_path(@order), alert: e.message
  end

  def payment_status
    render json: {
      payment_status: @order.payment_status,
      order_status: @order.status,
      paid: @order.paid?,
      expired: @order.payment_expires_at&.past? || false,
      expires_at: @order.payment_expires_at&.iso8601
    }
  end

  def retry_payment
    @order.with_lock do
      unless @order.vnpay? && @order.unpaid? && @order.pending?
        return redirect_to order_path(@order),
                           alert: "Đơn hàng không thể thanh toán lại."
      end

      if @order.payment_expires_at.present? &&
         @order.payment_expires_at.future?
        return redirect_to payment_order_path(@order),
                           alert: "Phiên thanh toán hiện tại vẫn còn hiệu lực."
      end

      @order.update!(
        payment_expires_at: PAYMENT_DURATION.from_now
      )
    end

    redirect_to payment_order_path(@order),
                notice: "Đã tạo phiên thanh toán VNPAY mới."
  rescue ActiveRecord::RecordInvalid
    redirect_to order_path(@order),
                alert: "Không thể tạo phiên thanh toán mới."
  end

  private

  def set_order
    @order = Current.user.orders
                    .includes(:order_items)
                    .find(params[:id])
  end

  def build_payment_url
    VnpayPaymentService.new(
      order: @order,
      ip_address: request.remote_ip,
      return_url: vnpay_return_url(
        host: request.host,
        protocol: request.scheme
      )
    ).payment_url
  end
end
