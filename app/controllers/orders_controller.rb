class OrdersController < ApplicationController
  before_action :set_order, only: :show

  def index
    @orders = Current.user.orders
                     .includes(:order_items)
                     .order(created_at: :desc)
  end

  def show
  end

  private

  def set_order
    @order = Current.user.orders
                     .includes(:order_items)
                     .find(params[:id])
  end
end
