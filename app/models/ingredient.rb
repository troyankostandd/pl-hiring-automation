class Ingredient < ApplicationRecord
  has_many :recipe_ingredients, dependent: :delete_all
  has_many :recipes, through: :recipe_ingredients

  validates :name, presence: true, uniqueness: true

  scope :top_by_usage, ->(limit = 500) { order(usage_count: :desc).limit(limit) }
  scope :pantry_staples, -> { where(is_pantry_staple: true) }
end
