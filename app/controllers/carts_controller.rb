class CartsController < ApplicationController
  def show
    cart = session[:cart] || {}

    products = Product.where(id: cart.keys).index_by(&:id)

    @cart_items = cart.filter_map do |product_id, quantity|
      product = products[product_id.to_i]
      [ product, quantity.to_i ] if product
    end

    @cart_total = @cart_items.sum do |product, quantity|
      product.price * quantity
    end
  end

  def add
    product = Product.available.find(params[:product_id])

    quantity = params[:quantity].to_i
    quantity = 1 unless quantity.positive?

    session[:cart] ||= {}
    product_id = product.id.to_s

    session[:cart][product_id] =
      session[:cart].fetch(product_id, 0).to_i + quantity

    redirect_back fallback_location: cart_path,
                  notice: "Đã thêm #{quantity} sản phẩm vào giỏ hàng."
  end

  def update
    product_id = params[:product_id].to_s
    quantity = params[:quantity].to_i

    session[:cart] ||= {}

    if quantity <= 0
      session[:cart].delete(product_id)
    else
      session[:cart][product_id] = quantity
    end

    redirect_to cart_path, notice: "Đã cập nhật giỏ hàng."
  end

  def remove
    session[:cart] ||= {}
    session[:cart].delete(params[:product_id].to_s)

    redirect_to cart_path,
                notice: "Đã xóa sản phẩm khỏi giỏ hàng."
  end
end
