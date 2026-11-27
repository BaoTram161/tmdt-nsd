class CheckoutsController < ApplicationController
  SHIPPING_FEE = 20_000
  PAYMENT_METHODS = %w[cod vnpay].freeze

  class CheckoutError < StandardError; end

  def show
    quantities = normalized_cart

    if quantities.empty?
      return redirect_to cart_path, alert: "Giỏ hàng của bạn đang trống."
    end

    products = Product.where(id: quantities.keys).index_by(&:id)

    if products.size != quantities.size
      raise CheckoutError, "Một số sản phẩm trong giỏ hàng không còn tồn tại."
    end

    @cart_items = quantities.map do |product_id, quantity|
      product = products[product_id]

      unless product.active?
        raise CheckoutError, "#{product.name} hiện không còn kinh doanh."
      end

      if quantity > product.stock.to_i
        raise CheckoutError, "#{product.name} không đủ số lượng trong kho."
      end

      [ product, quantity ]
    end

    @addresses = Current.user.addresses.order(
      is_default: :desc,
      created_at: :desc
    )

    @selected_address_id =
      params[:address_id].presence ||
      @addresses.find_by(is_default: true)&.id ||
      @addresses.first&.id

    @selected_payment_method =
      PAYMENT_METHODS.include?(params[:payment_method]) ?
        params[:payment_method] : "cod"

    @subtotal = calculate_subtotal(@cart_items)
    @shipping_fee = SHIPPING_FEE
    @discount_amount = 0.to_d
    @promotion_code = nil

    if session[:promotion_code].present?
      promotion = PromotionCode.find_by(code: session[:promotion_code])

      error = if promotion.nil?
        "Mã khuyến mãi không còn tồn tại."
      else
        promotion.eligibility_error(
          user: Current.user,
          subtotal: @subtotal
        )
      end

      if error.present?
        session.delete(:promotion_code)
        return redirect_to cart_path, alert: error
      end

      @promotion_code = promotion
      @discount_amount = promotion.calculate_discount(@subtotal)
    end

    @total = @subtotal - @discount_amount + @shipping_fee
  rescue CheckoutError => e
    redirect_to cart_path, alert: e.message
  end

  def create
    address = Current.user.addresses.find_by(id: params[:address_id])

    unless address
      return redirect_to checkout_path,
                         alert: "Vui lòng chọn địa chỉ giao hàng."
    end

    payment_method = params[:payment_method].presence || "cod"

    unless PAYMENT_METHODS.include?(payment_method)
      return redirect_to checkout_path,
                         alert: "Phương thức thanh toán không hợp lệ."
    end

    quantities = normalized_cart

    if quantities.empty?
      return redirect_to cart_path, alert: "Giỏ hàng của bạn đang trống."
    end

    ActiveRecord::Base.transaction do
      products = Product.lock.where(id: quantities.keys).index_by(&:id)

      if products.size != quantities.size
        raise CheckoutError, "Một số sản phẩm không còn tồn tại."
      end

      cart_items = quantities.map do |product_id, quantity|
        product = products[product_id]

        unless product.active?
          raise CheckoutError, "#{product.name} hiện không còn kinh doanh."
        end

        if product.stock.to_i < quantity
          raise CheckoutError,
                "#{product.name} chỉ còn #{product.stock} sản phẩm trong kho."
        end

        [ product, quantity ]
      end

      subtotal = calculate_subtotal(cart_items)
      promotion = nil
      discount_amount = 0.to_d

      if session[:promotion_code].present?
        promotion = PromotionCode.lock.find_by(
          code: session[:promotion_code]
        )

        unless promotion
          raise CheckoutError, "Mã khuyến mãi không còn tồn tại."
        end

        error = promotion.eligibility_error(
          user: Current.user,
          subtotal: subtotal
        )

        raise CheckoutError, error if error.present?

        discount_amount = promotion.calculate_discount(subtotal)
      end

      payment_expires_at =
        payment_method == "vnpay" ?
          VnpayPaymentService::PAYMENT_DURATION.from_now : nil

      @order = Current.user.orders.create!(
        recipient_name: address.recipient_name,
        phone: address.phone,
        province: address.province,
        ward: address.ward,
        street_address: address.street_address,
        subtotal: subtotal,
        shipping_fee: SHIPPING_FEE,
        promotion_code: promotion&.code,
        discount_amount: discount_amount,
        total: subtotal - discount_amount + SHIPPING_FEE,
        payment_method: payment_method,
        payment_status: :unpaid,
        payment_expires_at: payment_expires_at,
        status: :pending,
        note: params[:note].to_s.strip.presence
      )

      cart_items.each do |product, quantity|
        unit_price = product.price

        @order.order_items.create!(
          product: product,
          product_name: product.name,
          product_image: product.image_url,
          quantity: quantity,
          unit_price: unit_price,
          total_price: unit_price * quantity
        )

        product.update!(
          stock: product.stock - quantity,
          sold_count: product.sold_count + quantity
        )
      end

      promotion.increment!(:used_count) if promotion

      if payment_method == "vnpay"
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

    session.delete(:cart)
    session.delete(:promotion_code)

    if payment_method == "vnpay"
      redirect_to payment_order_path(@order)
    else
      render :create, status: :created
    end
  rescue CheckoutError => e
    redirect_to checkout_path, alert: e.message
  rescue VnpayPaymentService::ConfigurationError => e
    redirect_to checkout_path, alert: e.message
  rescue ActiveRecord::RecordInvalid => e
    redirect_to checkout_path,
                alert: "Không thể tạo đơn hàng: #{e.record.errors.full_messages.to_sentence}"
  end

  private

  def normalized_cart
    cart = session[:cart] || {}

    cart.each_with_object({}) do |(product_id, quantity), result|
      id = Integer(product_id, 10)
      amount = Integer(quantity)

      if id <= 0 || amount <= 0
        raise CheckoutError, "Số lượng sản phẩm không hợp lệ."
      end

      result[id] = amount
    rescue ArgumentError, TypeError
      raise CheckoutError, "Thông tin giỏ hàng không hợp lệ."
    end
  end

  def calculate_subtotal(cart_items)
    cart_items.sum do |product, quantity|
      product.price * quantity
    end
  end
end
