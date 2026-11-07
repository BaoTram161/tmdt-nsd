Rails.application.routes.draw do
  root "home#index"

  get "up" => "rails/health#show", as: :rails_health_check

  # Sản phẩm
  resources :products, only: %i[index show]

  # Giỏ hàng
  resource :cart, only: :show

  post "cart/items/:product_id",
       to: "carts#add",
       as: :add_cart_item

  patch "cart/items/:product_id",
        to: "carts#update",
        as: :update_cart_item

  delete "cart/items/:product_id",
         to: "carts#remove",
         as: :remove_cart_item

  # Danh sách yêu thích
  resource :wishlist, only: :show

  post "wishlist/items/:product_id",
       to: "wishlists#add",
       as: :add_wishlist_item

  delete "wishlist/items/:product_id",
         to: "wishlists#remove",
         as: :remove_wishlist_item
end
