class RecipesController < ApplicationController
  def index
    @ingredient_ids = params[:ingredients]&.split(",")&.compact_map(&:to_i) || []
    @max_missing = params[:max_missing]&.to_i || 3
    @only_cookable = params[:only_cookable] == "true"
    @sort_by = params[:sort_by] || "best_match"

    @recipes = Recipe.all
    @total_count = @recipes.count
    @recipes = @recipes.limit(25)
  end

  def show
    @recipe = Recipe.find_by_slug(params[:slug])
    return render_404 unless @recipe
  end

  def cook
    @recipe = Recipe.find_by_slug(params[:slug])
    return render_404 unless @recipe
  end

  private

  def render_404
    render file: Rails.root.join("public", "404.html"), status: 404, layout: false
  end
end
