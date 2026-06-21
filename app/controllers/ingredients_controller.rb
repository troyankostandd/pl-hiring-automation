class IngredientsController < ApplicationController
  def autocomplete
    query = params[:q]&.downcase
    limit = params[:limit]&.to_i || 10

    ingredients = if query.present?
      Ingredient.where("LOWER(name) LIKE ?", "%#{query}%").limit(limit)
    else
      Ingredient.top_by_usage(limit)
    end

    render json: ingredients.map { |i| {
      id: i.id,
      name: i.name,
      display_name: i.display_name || i.name,
      usage_count: i.usage_count
    }}
  end
end
