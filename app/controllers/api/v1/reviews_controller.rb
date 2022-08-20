class Api::V1::ReviewsController < ActionController::API
  include RackSessionFix
  before_action :authenticate_user!

  # * RETURNS THE LIST OF ALL THE REVIEWS FOR THE SPECIFIED WATCHLIST
  def index
    reviews = Review.where(watchlist_id: params["watchlist_id"])

    render json: {message: "Here's the list of all the reviews for the watchlist with id #{params["watchlist_id"]}", reviews: reviews.to_json }, status: :ok
  end


  # * CREATES A NEW REVIEW FOR THE CURRENT USER AND FOR THE WATCHLIST SPECIFIED AS PARAMS
  # * RETURNS THE NEWLY CREATED REVIEW FOR THIS USER AND WATCHLIST / ERROR IF FAIL TO SAVE THE NEW INSTANCE
  def create
    review = Review.new(user_id: current_user.id, username: current_user.username, watchlist_id: params["watchlist_id"], comment: params["comment"] )

    if review.save
      render json: { message: "Your review have been added successfully for the watchlist with id #{params["watchlist_id"]}", review: Review.last.to_json}, status: :ok
    else
      render json: { message: "An error occured while adding your review to the watchlist with id #{params["watchlist_id"]}: #{review.errors.messages[:comment].first}"}, status: :unprocessable_entity
    end
  end


  # * UPDATED THE SELECTED REVIEW
  # * RETURNS THE UPDATED REVIEW / ERROR IF FAIL TO UPDATE THE NEW INSTANCE
  def update
    review = Review.find(params["id"])

    if review.update(review_permited_params)
      render json: { message: "Your review with id #{params["id"]} has been updated successfully", review: review.to_json}, status: :ok
    else
      render json: { message: "An error occured while updating your review with id #{params["id"]}"}, status: :error
    end
  end


  # ! IF params["action_type"] = "liked"
  # *   - WE UPDATE THE LIKE COUNTER FOR THE REVIEW --> +1 TO "LIKES_COUNTER"
  # *   - WE CHECK IF THE USER ALREADY INTERACTED WITH THE REVIEW
  # *     - IF NO, THIS MEANS IT'S THE FIRST TIME THE USER INTERACTS WITH THE REVIEW --> WE CREATE A NEW REVIEW_LIKE INSTANCE WITH "action_type" SET TO "LIKED"
  # *     - WE RETURN THE WHOLE REVIEW (BECAUSE THE LIKES_COUNTER CHANGED) AND THE NEWLY CREATED REVIEW_LIKE INSTANCE
  # *     - IF YES, THIS MEANS THAT THE USER DISLIKED THE REVIEW -- > WE THEN UPDATE THE "action_type" FROM "DISLIKED" TO "LIKED"
  # *     - WE RETURN THE WHOLE REVIEW (BECAUSE THE LIKES_COUNTER CHANGED) AND THE UPDATED REVIEW_LIKE INSTANCE
  # * ------------------------------------------------------------------------------------------------------------------
  # ! IF params["action_type"] = "unliked" (DIFFERENT TO DISLIKE. THE USER REMOVES ITS LIKE IN THIS SCENARIO)
  # *   - WE UPDATE THE LIKE COUNTER FOR THE REVIEW --> -1 TO "LIKES_COUNTER"
  # *   - WE DELETE THE REVIEW_LIKE INSTANCE FOR THE CURRENT USER AND THE SPECIFIED REVIEW
  # *   - WE RETURN THE WHOLE REVIEW (BECAUSE THE LIKES_COUNTER CHANGED) AND THE DELETED REVIEW_LIKE INSTANCE
  # *     - IN THE CLIENT SIDE, MAKE SURE TO USE THE ID OF THIS REVIEW TO FIND IN IN THE ARRAY OF USER'S LIKED REVIEWS AND REMOVE IT FROM IT.
  # *     - THIS STEP IS NECESSARY TO UPDATE THE STATE OF THE THUMBS UP ICON (OUTLINE / FILLED IN)
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


  # ! IF params["action_type"] = "disliked"
  # *   - WE UPDATE THE DISLIKE COUNTER FOR THE REVIEW --> +1 TO "DISLIKES_COUNTER"
  # *   - WE CHECK IF THE USER ALREADY INTERACTED WITH THE REVIEW
  # *     - IF NO, THIS MEANS IT'S THE FIRST TIME THE USER INTERACTS WITH THE REVIEW --> WE CREATE A NEW REVIEW_LIKE INSTANCE WITH "action_type" SET TO "DISLIKED"
  # *     - WE RETURN THE WHOLE REVIEW (BECAUSE THE DISLIKES_COUNTER CHANGED) AND THE NEWLY CREATED REVIEW_LIKE INSTANCE
  # *     - IF YES, THIS MEANS THAT THE USER LIKED THE REVIEW -- > WE THEN UPDATE THE "action_type" FROM "LIKED" TO "DISLIKED"
  # *     - WE RETURN THE WHOLE REVIEW (BECAUSE THE DISLIKES_COUNTER CHANGED) AND THE UPDATED REVIEW_LIKE INSTANCE
  # * ------------------------------------------------------------------------------------------------------------------
  # ! IF params["action_type"] = "undisliked" (DIFFERENT TO LIKE. THE USER REMOVES ITS DISLIKE IN THIS SCENARIO)
  # *   - WE UPDATE THE LIKE COUNTER FOR THE REVIEW --> -1 TO "DISLIKES_COUNTER"
  # *   - WE DELETE THE REVIEW_LIKE INSTANCE FOR THE CURRENT USER AND THE SPECIFIED REVIEW
  # *   - WE RETURN THE WHOLE REVIEW (BECAUSE THE DISLIKES CHANGED) AND THE DELETED REVIEW_LIKE INSTANCE
  # *     - IN THE CLIENT SIDE, MAKE SURE TO USE THE ID OF THIS REVIEW TO FIND IN IN THE ARRAY OF USER'S DISLIKED REVIEWS AND REMOVE IT FROM IT.
  # *     - THIS STEP IS NECESSARY TO UPDATE THE STATE OF THE THUMBS DOWN ICON (OUTLINE / FILLED IN)
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
      render json: { message: "You successfully undisliked the review with id #{review.id}", review: review.to_json, review_like: reviewLike.first.to_json }, status: :ok
    else
      render json: {message: "An error occured while liking/unliking the review with id #{review.id}" }
    end
  end


  # * FINDS THE INSTANCE OF REVIEW BASED ON ID IN THE URL AND DELETES IT
  # * IN CLIENT SIDE, MAKE SURE TO USE THE ID OF THIS REVIEW TO UPDATE THE REVIEWS ARRAY FOR THE USER BY DELETING THIS ENTRY.
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
