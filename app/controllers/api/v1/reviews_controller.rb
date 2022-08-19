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




  def update_review_likes
    # ? WHAT'S NEEDED HERE: review_id (In URL) / action_type (in body) / user = current_user (session token)
    review = Review.find(params["id"])
    reviewLike = ReviewLike.where(user_id: current_user.id, review_id: review.id)
    review_likes_counter = review.likes_counter

    if params["action_type"] == "liked"
      review.update(likes_counter: review_likes_counter += 1)

      # ! We change the value here only if there's no existing reviewLike for the current user.
      # ! We also only use it in the else block below
      reviewCreated = nil
      if reviewLike.empty?
        reviewLikeCreated = ReviewLike.create(user_id: current_user.id, review_id: review.id, action_type: "liked" )
        render json: { message: "You successfully liked the review with id #{review.id}", review: review.to_json, review_like: reviewLikeCreated.to_json }, status: :ok
      else
        review.update(dislikes_counter: review.dislikes_counter -= 1)
        reviewLike[0].update(action_type: "liked")
        render json: { message: "You successfully changed your mind and liked the review with id #{review.id}", review: review.to_json, review_like: reviewLike[0].to_json }, status: :ok
      end

    elsif params["action_type"] == "unliked"
      review.update(likes_counter: review_likes_counter -= 1)
      reviewLike.first.delete
      render json: { message: "You successfully unliked the review with id #{review.id}", review: review.to_json, review_like: reviewLike.first.to_json }, status: :ok
    else
      render json: {message: "An error occured while liking/unliking the review with id #{review.id}" }
    end
  end

  def update_review_dislikes
    # ? WHAT'S NEEDED HERE: review_id (In URL) / action_type (in body) / user = current_user (session token)

    review = Review.find(params["id"])
    reviewLike = ReviewLike.where(user_id: current_user.id, review_id: review.id)
    review_dislikes_counter = review.dislikes_counter

    if params["action_type"] == "disliked"
      review.update(dislikes_counter: review_dislikes_counter += 1)

      # ! We change the value here only if there's no existing reviewLike for the current user.
      # ! We also only use it in the else block below
      reviewCreated = nil
      if reviewLike.empty?
        reviewLikeCreated = ReviewLike.create(user_id: current_user.id, review_id: review.id, action_type: "disliked" )
        render json: { message: "You successfully disliked the review with id #{review.id}", review: review.to_json, review_like: reviewLikeCreated.to_json }, status: :ok
      else
        review.update(likes_counter: review.likes_counter -= 1)
        reviewLike[0].update(action_type: "disliked")
        render json: { message: "You successfully changed your mind and disliked the review with id #{review.id}", review: review.to_json, review_like: reviewLike[0].to_json }, status: :ok
      end

    elsif params["action_type"] == "undisliked"
      review.update(dislikes_counter: review_dislikes_counter -= 1)
      reviewLike.first.delete
      p reviewLike.first
      render json: { message: "You successfully undisliked the review with id #{review.id}", review: review.to_json, review_like: reviewLike.first.to_json }, status: :ok
    else
      render json: {message: "An error occured while liking/unliking the review with id #{review.id}" }
    end
  end


  # def update_review_dislikes
  #   review = Review.find(params["id"])
  #   reviewLike = ReviewLike.where(user_id: current_user.id, review_id: review.id)

  #   if params["action_type"] == "disliked"
  #     review_dislikes_counter = review.dislikes_counter
  #     review.update(dislikes_counter: review_dislikes_counter += 1)

  #     # ! We change the value here only if there's no existing reviewLike for the current user.
  #     # ! We also only use it in the else block below
  #     reviewCreated = nil
  #     if reviewLike.empty?
  #       reviewLikeCreated = ReviewLike.create(user_id: current_user.id, review_id: review.id, action_type: "disliked" )
  #       render json: { message: "You successfully disliked the review with id #{review.id}", review: review.to_json, review_like: reviewLikeCreated.to_json }, status: :ok
  #     else
  #       reviewLike[0].update(action_type: "disliked")
  #       render json: { message: "You successfully changed your mind and disliked the review with id #{review.id}", review: review.to_json, review_like: reviewLike.to_json }, status: :ok
  #     end
  #   elsif params["action_type"] == "undisliked"
  #     review_dislikes_counter = review.dislikes_counter
  #     review.update(dislikes_counter: review_dislikes_counter -= 1)
  #     # review_like = ReviewList.where(user_id: current_user.id, review_id: review.id).first
  #     reviewLike[0] = review_like.id
  #     review_like.delete
  #     render json: { message: "You successfully unliked the review with id #{review.id}", review: review.to_json, review_like_id: review_like_id.to_json }, status: :ok
  #   else
  #     render json: {message: "An error occured while disliking/undisliking the review with id #{review.id}" }
  #   end
  # end




  def destroy
    review = Review.find(params["id"])

    ReviewLike.where(review_id: review.id).delete_all

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
