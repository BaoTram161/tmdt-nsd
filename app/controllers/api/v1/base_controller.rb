module Api
  module V1
    class BaseController < ActionController::API
      private

      def authenticate_api_user!
        token = request.headers["Authorization"].to_s
                       .match(/\ABearer (.+)\z/i)&.captures&.first

        session_id = api_token_verifier.verified(
          token,
          purpose: :api_auth
        ) if token.present?

        @api_session = Session.find_by(id: session_id) if session_id.present?

        unless @api_session
          render json: {
            error: "unauthorized",
            message: "Vui lòng đăng nhập để tiếp tục."
          }, status: :unauthorized
          return
        end

        Current.session = @api_session
      end

      def api_token_verifier
        Rails.application.message_verifier(:api_auth)
      end

      def issue_api_token(session)
        api_token_verifier.generate(
          session.id,
          expires_in: 24.hours,
          purpose: :api_auth
        )
      end
    end
  end
end
