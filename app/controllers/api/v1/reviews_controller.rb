class Api::V1::ReviewsController < ActionController::API
  include RackSessionFix
  before_action :authenticate_user!

  def index
    reviews = Review.where(watchlist_id: params["watchlist_id"])
    # p reviews

    render json: {message: "Here's the list of all the reviews for the watchlist with id #{params["watchlist_id"]}", reviews: reviews.to_json }, status: :ok
  end

  def create
    review = Review.new(user_id: current_user.id, username: current_user.username, watchlist_id: params["watchlist_id"], comment: params["comment"] )

    if review.save
      render json: { message: "Your review have been added successfully for the watchlist with id #{params["watchlist_id"]}", review: Review.last.to_json}, status: :ok
    else
      render json: { message: "An error occured while adding your review to the watchlist with id #{params["watchlist_id"]}: #{review.errors.messages[:comment].first}"}, status: :unprocessable_entity
    end
  end

  def update
    review = Review.find(params["id"])

    if review.update(review_permited_params)
      render json: { message: "Your review with id #{params["id"]} has been updated successfully", review: review.to_json}, status: :ok
    else
      render json: { message: "An error occured while updating your review with id #{params["id"]}"}, status: :error
    end
  end

  def destroy
    review = Review.find(params["id"])

    if review.delete
      render json: { message: "Your review have been deleted successfully for the watchlist with id #{params["watchlist_id"]}"}, status: :ok
    else
      render json: { message: "An error occured while deleting your review from the watchlist with id #{params["watchlist_id"]}"}, status: :error
    end
  end

  private

  def review_permited_params
    params.require(:review).permit(:comment, :likes, :dislikes)
  end
end
