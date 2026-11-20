class AddressesController < ApplicationController
  before_action :set_address, only: %i[edit update destroy]
  before_action :load_address_options, only: %i[new create edit update]

  def index
    @addresses = Current.user.addresses.order(is_default: :desc, created_at: :desc)
  end

  def new
    @address = Current.user.addresses.new
  end

  def create
    @address = Current.user.addresses.new(address_params)
    @address.is_default = true unless Current.user.addresses.exists?

    if @address.save
      redirect_to addresses_path, notice: "Đã thêm địa chỉ giao hàng."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @address.update(address_params)
      redirect_to addresses_path, notice: "Đã cập nhật địa chỉ giao hàng."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    was_default = @address.is_default?
    @address.destroy!

    if was_default
      replacement = Current.user.addresses.order(created_at: :desc).first
      replacement&.update(is_default: true)
    end

    redirect_to addresses_path, notice: "Đã xóa địa chỉ giao hàng."
  end

  private

  def load_address_options
    @provinces = Province.order(:name)
    @communes = Commune.includes(:province).order(:name)
  end

  def set_address
    @address = Current.user.addresses.find(params[:id])
  end

  def address_params
    params.require(:address).permit(
      :label,
      :recipient_name,
      :phone,
      :province,
      :ward,
      :street_address,
      :is_default
    )
  end
end
