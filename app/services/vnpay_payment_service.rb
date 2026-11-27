require "openssl"
require "uri"

class VnpayPaymentService
  PAYMENT_URL = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html"
  TIME_ZONE = "Asia/Ho_Chi_Minh"
  PAYMENT_DURATION = 15.minutes

  class ConfigurationError < StandardError; end

  def initialize(order:, ip_address:, return_url:)
    @order = order
    @ip_address = ip_address
    @return_url = return_url
    @credentials = Rails.application.credentials.dig(:vnpay) || {}
  end

  def payment_url
    validate_configuration!

    query = URI.encode_www_form(payment_params.sort)
    signature = OpenSSL::HMAC.hexdigest(
      "SHA512",
      @credentials.fetch(:hash_secret),
      query
    )

    "#{gateway_url}?#{query}&vnp_SecureHash=#{signature}"
  end

  private

  def payment_params
    now = Time.current.in_time_zone(TIME_ZONE)
    expires_at = @order.payment_expires_at || PAYMENT_DURATION.from_now

    {
      "vnp_Version" => "2.1.0",
      "vnp_Command" => "pay",
      "vnp_TmnCode" => @credentials.fetch(:tmn_code),
      "vnp_Amount" => (@order.total.to_d * 100).to_i.to_s,
      "vnp_CurrCode" => "VND",
      "vnp_TxnRef" => @order.order_number,
      "vnp_OrderInfo" => "Thanh toan don hang #{@order.order_number}",
      "vnp_OrderType" => "other",
      "vnp_Locale" => "vn",
      "vnp_ReturnUrl" => @return_url,
      "vnp_IpAddr" => @ip_address,
      "vnp_CreateDate" => now.strftime("%Y%m%d%H%M%S"),
      "vnp_ExpireDate" => expires_at.in_time_zone(TIME_ZONE).strftime("%Y%m%d%H%M%S")
    }
  end

  def gateway_url
    @credentials[:payment_url].presence || PAYMENT_URL
  end

  def validate_configuration!
    required_values = %i[tmn_code hash_secret]

    missing_values = required_values.select do |key|
      @credentials[key].blank?
    end

    return if missing_values.empty?

    raise ConfigurationError,
          "VNPAY chưa được cấu hình đầy đủ: #{missing_values.join(', ')}"
  end
end
