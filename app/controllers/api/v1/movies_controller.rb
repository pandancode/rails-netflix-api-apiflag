class Api::V1::MoviesController < ActionController::API
  include RackSessionFix
  # before_action :authenticate_user!
  before_action :authenticate_user!
  p "Hello from movies controller"

  def index
    # current_user = get_user_from_token
    p current_user
    # request.header
    p "hello from movies controller#index"
    # p Movie.all
    render json: Movie.all
  end

  # private

  # def get_user_from_token
  #   p "Hello from get_user_from_token"
  #   p request.headers["Authorization"].split(" ")[1]
  #   p JWT.decode
  #   jwt_payload = JWT.decode(request.headers["Authorization"].split(" ")[1],
  #                             ENV['DEVISE_JWT_SECRET_KEY']).first
  #   user_id = jwt_payload["sub"]
  #   user = User.find(user_id.to_s)
  #   p user
  # end
end
