class RecipeCardComponent < ViewComponent::Base
  def initialize(recipe, score: nil, back_to: nil)
    @recipe = recipe
    @score = score || { matched: 0, total: 0, missing: 0, match_ratio: 0 }
    @back_to = back_to
  end

  def missing_ingredients
    missing_ingredient_names.first(3)
  end

  def has_more_missing?
    missing_ingredient_names.size > 3
  end

  def more_count
    missing_ingredient_names.size - 3
  end

  private

  # Prefer the genuinely-missing ingredients computed by the scorer (pantry-aware).
  # Fall back to the recipe's non-staple ingredients when rendered without a score.
  def missing_ingredient_names
    @missing_ingredient_names ||=
      @score[:missing_names] ||
      non_staple_ingredients.map { |ri| ri.ingredient.display_name || ri.ingredient.name }
  end

  # Operates on the already-loaded association to avoid extra COUNT queries.
  def non_staple_ingredients
    @non_staple_ingredients ||=
      @recipe.recipe_ingredients.to_a.reject { |ri| ri.ingredient.is_pantry_staple }
  end
end
