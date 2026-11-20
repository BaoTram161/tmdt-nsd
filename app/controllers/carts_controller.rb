class CartsController < ApplicationController
  SHIPPING_FEE = 20_000

  def show
    cart = session[:cart] || {}

    products = Product.where(id: cart.keys).index_by(&:id)

    @cart_items = cart.filter_map do |product_id, quantity|
      product = products[product_id.to_i]
      [ product, quantity.to_i ] if product
    end

    @cart_total = calculate_cart_total(@cart_items)
    @shipping_fee = SHIPPING_FEE
    @discount_amount = 0.to_d

    @available_promotions = []

    if @cart_items.empty?
      session.delete(:promotion_code)
    else
      @available_promotions = PromotionCode.active.order(created_at: :desc).select do |promotion|
        promotion.eligibility_error(
          user: Current.user,
          subtotal: @cart_total
        ).nil?
      end

      if session[:promotion_code].present?
        promotion = PromotionCode.find_by(code: session[:promotion_code])

        error =
          if promotion.nil?
            "Mã khuyến mãi không tồn tại."
          else
            promotion.eligibility_error(
              user: Current.user,
              subtotal: @cart_total
            )
          end

        if error.present?
          session.delete(:promotion_code)
          flash.now[:alert] = error
        else
          @promotion_code = promotion
          @discount_amount = promotion.calculate_discount(@cart_total)
        end
      end
    end

    @grand_total = @cart_total - @discount_amount + @shipping_fee
  end

  def add
    product = Product.available.find(params[:product_id])

    quantity = parse_quantity(params[:quantity])
    unless quantity&.positive?
      return redirect_back(
        fallback_location: cart_path,
        alert: "Số lượng sản phẩm không hợp lệ."
      )
    end

    stock = product.stock.to_i
    product_id = product.id.to_s

    session[:cart] ||= {}
    current_quantity = session[:cart].fetch(product_id, 0).to_i
    new_quantity = current_quantity + quantity

    if stock <= 0
      return redirect_back(
        fallback_location: cart_path,
        alert: "Sản phẩm hiện đã hết hàng."
      )
    end

    if new_quantity > stock
      remaining = [ stock - current_quantity, 0 ].max

      return redirect_back(
        fallback_location: cart_path,
        alert: "Sản phẩm chỉ còn #{stock} sản phẩm trong kho. Bạn có thể thêm tối đa #{remaining} sản phẩm nữa."
      )
    end

    session[:cart][product_id] = new_quantity

    redirect_back fallback_location: cart_path,
                  notice: "Đã thêm #{quantity} sản phẩm vào giỏ hàng."
  end

  def update
    product_id = params[:product_id].to_s
    quantity = parse_quantity(params[:quantity])

    session[:cart] ||= {}

    if quantity.nil?
      return redirect_to cart_path,
                         alert: "Số lượng sản phẩm không hợp lệ."
    end

    if quantity <= 0
      session[:cart].delete(product_id)

      return redirect_to cart_path,
                         notice: "Đã xóa sản phẩm khỏi giỏ hàng."
    end

    product = Product.find_by(id: product_id)

    unless product
      session[:cart].delete(product_id)

      return redirect_to cart_path,
                         alert: "Sản phẩm không còn tồn tại."
    end

    stock = product.stock.to_i

    if stock <= 0
      return redirect_to cart_path,
                         alert: "Sản phẩm hiện đã hết hàng."
    end

    if quantity > stock
      return redirect_to cart_path,
                         alert: "Sản phẩm chỉ còn #{stock} sản phẩm trong kho."
    end

    session[:cart][product_id] = quantity

    redirect_to cart_path, notice: "Đã cập nhật giỏ hàng."
  end

  def remove
    session[:cart] ||= {}
    session[:cart].delete(params[:product_id].to_s)

    redirect_to cart_path,
                notice: "Đã xóa sản phẩm khỏi giỏ hàng."
  end

  def apply_promotion
    code = params[:code].to_s.strip.upcase

    if code.blank?
      return redirect_to cart_path,
                         alert: "Vui lòng chọn mã khuyến mãi."
    end

    promotion = PromotionCode.find_by(code: code)

    unless promotion
      return redirect_to cart_path,
                         alert: "Mã khuyến mãi không tồn tại."
    end

    cart = session[:cart] || {}
    products = Product.where(id: cart.keys).index_by(&:id)

    subtotal = cart.sum do |product_id, quantity|
      product = products[product_id.to_i]
      product ? product.price * quantity.to_i : 0
    end

    if subtotal <= 0
      return redirect_to cart_path,
                         alert: "Giỏ hàng của bạn đang trống."
    end

    error = promotion.eligibility_error(
      user: Current.user,
      subtotal: subtotal
    )

    if error.present?
      return redirect_to cart_path, alert: error
    end

    session[:promotion_code] = promotion.code

    redirect_to cart_path,
                notice: "Đã áp dụng mã #{promotion.code} thành công."
  end

  def remove_promotion
    session.delete(:promotion_code)

    redirect_to cart_path,
                notice: "Đã gỡ mã khuyến mãi."
  end

  private

  def calculate_cart_total(cart_items)
    cart_items.sum do |product, quantity|
      product.price * quantity
    end
  end

  def parse_quantity(value)
    return 1 if value.blank?

    Integer(value, 10)
  rescue ArgumentError, TypeError
    nil
  end
end
