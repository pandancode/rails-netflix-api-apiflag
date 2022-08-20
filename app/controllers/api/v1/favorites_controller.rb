class Api::V1::FavoritesController < ActionController::API
  require 'json'
  include RackSessionFix
  before_action :authenticate_user!

  # * RETURNS THE LIST OF FAVORITED MOVIES FOR THE CURRENT USER
  def index
    favorite_list = current_user.movies
    render json: { favorite_movies: favorite_list, status: :ok }
  end


  # * CREATES AN NEW INSTANCE OF "FAVORITE" MOVIE.
  # * RETURNS THE NEWLY CREATED INSTANCE
  def create
    res_body = JSON.parse(request.raw_post)
    new_favorite = Favorite.new(user_id: current_user.id, movie_id: res_body["movie_id"])

    if new_favorite.save!
      favorite_list = current_user.movies
      render json: { message: "Added the movie with id #{res_body["movie_id"]} as favorite for user #{current_user.email}", favorite_movies: favorite_list.to_json }, status: :ok
    else
      render json: { message: "An error occured while adding movie #{res_body["movie_id"]} for user  #{current_user.email}", favorite_movies: favorite_list.to_json }, status: :unprocessable_entity
    end
  end


  # * FINDS THE INSTANCE OF FAVORITE BASED ON ID IN THE URL AND DELETES IT
  # * RETURNS THE UPDATED FAVORITED MOVIE LIST FOR THE CURRENT USER.
  # TODO --> DON'T RETURN ANYTHING, JUST FIND THE INSTANCE IN THE REDUX STORE ARRAY AND REMOVE THE INSTANCE FROM IT BASED ON THE ID (USE FIND).
  def destroy
    movie_to_delete = Favorite.where(user_id: current_user.id).where(movie_id: params["id"])[0]
    movie_to_delete.delete
    favorite_list = current_user.movies
    render json: { message: "Movie with id #{params["id"]} deleted from favorite successfully for user #{current_user.email}", favorite_movies: favorite_list.to_json }, status: :ok
  end
end
