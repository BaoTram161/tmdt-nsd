Rails.application.routes.draw do
  # API V1
  namespace :api do
    namespace :v1 do
      defaults format: :json do
        # Đăng nhập và đăng xuất API
        resource :session, only: %i[create destroy]

        # Sản phẩm
        resources :products, only: %i[index show]

        # Đơn hàng của khách hàng
        resources :orders, only: %i[index show] do
          member do
            get :payment_status
          end
        end
      end
    end
  end

  # Tài khoản
  resource :registration, only: %i[new create]
  resource :session, only: %i[new create destroy]
  resources :passwords, only: %i[new create edit update], param: :token

  resource :profile, only: %i[show update], controller: "profiles"
  resources :addresses, only: %i[index new create edit update destroy]

  # Đơn hàng của khách hàng
  resources :orders, only: %i[index show] do
    member do
      get :payment_status
      get :payment
      post :retry_payment
    end
  end

  # Đánh giá của khách hàng
  resources :reviews, only: :index

  # Quản trị Admin
  namespace :admin do
    root "dashboard#index"

    # Quản lý đơn hàng
    resources :orders, only: %i[index show update]

    # Quản lý sản phẩm
    resources :products, only: %i[index new create edit update] do
      patch :toggle_active, on: :member
    end

    # Quản lý khách hàng
    resources :customers, only: %i[index show]

    # Quản lý đánh giá
    resources :reviews, only: %i[index destroy]

    # Quản lý khuyến mãi
    resources :promotion_codes, only: %i[index new create edit update] do
      patch :toggle_active, on: :member
    end
  end

  # Thanh toán VNPAY
  get "vnpay/ipn", to: "vnpay#ipn", as: :vnpay_ipn
  get "vnpay/return", to: "vnpay#payment_return", as: :vnpay_return

  # Trang chủ
  root "home#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Sản phẩm của khách hàng
  resources :products, only: %i[index show] do
    resources :reviews, only: %i[create update destroy]
  end

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

  # Mã khuyến mãi trong giỏ hàng
  post "cart/promotion",
       to: "carts#apply_promotion",
       as: :apply_cart_promotion

  delete "cart/promotion",
         to: "carts#remove_promotion",
         as: :remove_cart_promotion

  # Thanh toán
  resource :checkout, only: %i[show create]

  # Danh sách yêu thích
  resource :wishlist, only: :show

  post "wishlist/items/:product_id",
       to: "wishlists#add",
       as: :add_wishlist_item

  delete "wishlist/items/:product_id",
         to: "wishlists#remove",
         as: :remove_wishlist_item
end
