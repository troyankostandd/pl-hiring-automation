class Recipe < ApplicationRecord
  has_many :recipe_ingredients, dependent: :delete_all
  has_many :ingredients, through: :recipe_ingredients

  validates :title, :slug, :source_url, presence: true
  validates :slug, :source_url, uniqueness: true

  scope :by_best_match, -> { order(created_at: :desc) }

  def self.find_by_slug(slug)
    find_by(slug: slug)
  end
end
