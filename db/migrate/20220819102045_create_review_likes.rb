class CreateReviewLikes < ActiveRecord::Migration[7.0]
  def change
    create_table :review_likes do |t|
      t.string :action_type
      t.references :user, null: false, foreign_key: true
      t.references :review, null: false, foreign_key: true

      t.timestamps
    end
  end
end
