module Api
  module V1
    class SessionsController < BaseController
      before_action :authenticate_api_user!, only: :destroy

      def create
        user = User.authenticate_by(
          params.permit(:email_address, :password)
        )

        unless user
          return render json: {
            error: "unauthorized",
            message: "Email hoặc mật khẩu không chính xác."
          }, status: :unauthorized
        end

        api_session = user.sessions.create!(
          user_agent: request.user_agent,
          ip_address: request.remote_ip
        )

        render json: {
          message: "Đăng nhập thành công.",
          token_type: "Bearer",
          access_token: issue_api_token(api_session),
          expires_in: 24.hours.to_i,
          user: {
            id: user.id,
            email_address: user.email_address,
            full_name: user.full_name
          }
        }, status: :created
      end

      def destroy
        @api_session.destroy!

        render json: {
          message: "Đăng xuất thành công."
        }, status: :ok
      end
    end
  end
end
