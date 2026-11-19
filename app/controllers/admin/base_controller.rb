module Admin
  class BaseController < ApplicationController
    before_action :require_admin

    private

    def require_admin
      return if Current.user&.is_admin?

      redirect_to root_path,
                  alert: "Bạn không có quyền truy cập khu vực quản trị."
    end
  end
end
