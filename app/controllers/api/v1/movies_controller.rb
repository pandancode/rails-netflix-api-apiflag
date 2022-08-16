class Api::V1::MoviesController < ActionController::API
  before_action :authenticate_user!, only: [ :index ]

  def index
    render json: Movie.all
  end
end
