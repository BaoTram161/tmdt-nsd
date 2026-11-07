class WishlistsController < ApplicationController
  def show
    wishlist_ids = session[:wishlist] || []

    @products = Product.available
                       .includes(:category)
                       .where(id: wishlist_ids)
  end

  def add
    product = Product.available.find(params[:product_id])

    session[:wishlist] ||= []
    session[:wishlist] |= [product.id.to_s]

    redirect_back fallback_location: wishlist_path,
                  notice: "Đã thêm sản phẩm vào danh sách yêu thích."
  end

  def remove
    session[:wishlist] ||= []
    session[:wishlist].delete(params[:product_id].to_s)

    redirect_back fallback_location: wishlist_path,
                  notice: "Đã xóa sản phẩm khỏi danh sách yêu thích."
  end
end