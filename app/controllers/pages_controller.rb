class PagesController < ApplicationController
  def home
    @recipe_count = Recipe.count
  end

  def about
  end

  def health
    render json: {
      status: "ok",
      recipes: Recipe.count,
      ingredients: Ingredient.count,
      timestamp: Time.current
    }
  end
end
