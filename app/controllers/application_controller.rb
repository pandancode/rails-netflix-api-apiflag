class ApplicationController < ActionController::API
  include ActionController::MimeResponds

  respond_to :json

  # include ActionController::HttpAuthentication::Token::ControllerMethods
  # before_action :authenticate_user_from_token!
  # before_action :authenticate_user!
  p "Hello from application_controller"

  # private

  # def authenticate_user_from_token!
  #   authenticate_with_http_token do |token, options|
  #       user_email = options[:user_email].presence
  #       user       = user_email && User.find_by_email(user_email)

  #       if user && Devise.secure_compare(user.authentication_token, token)
  #         sign_in user, store: false
  #       end
  #     end
  # end
end
