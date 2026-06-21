class RecipesController < ApplicationController
  before_action :set_recipe, only: [:show, :cook]

  def index
    @ingredient_ids = params[:ingredients]&.split(",")&.map(&:strip) || []
    @max_missing = params[:max_missing]&.to_i || 3
    @only_cookable = params[:only_cookable] == "true"
    @sort_by = params[:sort_by] || "best_match"
    @page = params[:page]&.to_i || 1

    result = RecipeMatcher.call(@ingredient_ids, {
      max_missing: @max_missing,
      only_cookable: @only_cookable,
      sort_by: @sort_by,
      page: @page,
      per_page: 25
    })

    @total_count = result[:total_count]
    @recipes = result[:results].map { |r| r[:recipe] }
    @scored_recipes = result[:results]
    @pantry_count = result[:pantry_count]
    @total_pages = (@total_count.to_f / 25).ceil
  end

  def show
    return render_404 unless @recipe

    @recipe_ingredients = @recipe.recipe_ingredients.includes(:ingredient)
    @instructions = @recipe.instructions&.split("\n\n")&.map(&:strip) || []
  end

  def cook
    return render_404 unless @recipe

    @instructions = @recipe.instructions&.split("\n\n")&.map(&:strip) || []
    @recipe_ingredients = @recipe.recipe_ingredients.includes(:ingredient)
  end

  private

  def set_recipe
    @recipe = Recipe.find_by_slug(params[:slug])
  end

  def render_404
    render file: Rails.root.join("public", "404.html"), status: 404, layout: false
  end
end
