class CartsController < ApplicationController
  def show
    cart = session[:cart] || {}

    products = Product.where(id: cart.keys).index_by(&:id)

    @cart_items = cart.filter_map do |product_id, quantity|
      product = products[product_id.to_i]
      [product, quantity.to_i] if product
    end

    @cart_total = @cart_items.sum do |product, quantity|
      product.price * quantity
    end
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
      remaining = [stock - current_quantity, 0].max

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

  private

  def parse_quantity(value)
    return 1 if value.blank?

    Integer(value, 10)
  rescue ArgumentError, TypeError
    nil
  end
end