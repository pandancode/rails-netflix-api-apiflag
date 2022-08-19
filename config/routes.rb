Rails.application.routes.draw do
  root to: "pages#home"
  get 'reviews/index'
  get 'reviews/create'
  get 'reviews/update'
  get 'reviews/delete'
  get 'watchlist_movies/create'
  get 'watchlist_movies/update'
  get 'watchlist_movies/delete'
  get 'watchlists/index'
  get 'watchlists/create'
  get 'watchlists/update'
  get 'watchlists/delete'
  resources :movies

  devise_for :users,
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  get '/member-data', to: 'members#show'

  namespace :api do
    namespace :v1 do
      resources :movies, only: [ :index ]
      resources :favorites, only: [ :index, :create, :destroy ]
      resources :watchlists
      resources :reviews, only: [ :index, :create, :update, :destroy ] do
        member do
          patch "update_review_likes", to: "reviews#update_review_likes"
          patch "update_review_dislikes", to: "reviews#update_review_dislikes"
        end
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
end
