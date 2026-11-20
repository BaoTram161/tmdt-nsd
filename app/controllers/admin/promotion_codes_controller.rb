module Admin
  class PromotionCodesController < BaseController
    before_action :set_promotion_code, only: %i[edit update toggle_active]

    def index
      @promotion_codes = PromotionCode.order(created_at: :desc)

      if params[:q].present?
        keyword = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip.upcase)}%"
        @promotion_codes = @promotion_codes.where("code LIKE ?", keyword)
      end

      case params[:status]
      when "active"
        @promotion_codes = @promotion_codes.where(active: true)
      when "inactive"
        @promotion_codes = @promotion_codes.where(active: false)
      end
    end

    def new
      @promotion_code = PromotionCode.new(
        discount_type: :percentage,
        active: true,
        minimum_order_value: 0
      )
    end

    def create
      @promotion_code = PromotionCode.new(promotion_code_params)

      if @promotion_code.save
        redirect_to admin_promotion_codes_path,
                    notice: "Đã tạo mã khuyến mãi thành công."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @promotion_code.update(promotion_code_params)
        redirect_to admin_promotion_codes_path,
                    notice: "Đã cập nhật mã khuyến mãi thành công."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle_active
      @promotion_code.update!(active: !@promotion_code.active?)

      message = @promotion_code.active? ?
        "Đã kích hoạt mã khuyến mãi." :
        "Đã tạm ngưng mã khuyến mãi."

      redirect_to admin_promotion_codes_path, notice: message
    end

    private

    def set_promotion_code
      @promotion_code = PromotionCode.find(params[:id])
    end

    def promotion_code_params
      params.require(:promotion_code).permit(
        :code,
        :description,
        :discount_type,
        :discount_value,
        :minimum_order_value,
        :maximum_discount,
        :usage_limit,
        :per_user_limit,
        :starts_at,
        :expires_at,
        :active
      )
    end
  end
end
