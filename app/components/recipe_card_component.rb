class RecipeCardComponent < ViewComponent::Base
  def initialize(recipe, score: nil)
    @recipe = recipe
    @score = score || { matched: 0, total: 0, missing: 0, match_ratio: 0 }
  end

  def missing_ingredients
    if @recipe.recipe_ingredients.count > 0
      @recipe.recipe_ingredients
        .reject { |ri| ri.ingredient.is_pantry_staple }
        .last(3)
        .map { |ri| ri.ingredient.display_name || ri.ingredient.name }
    else
      []
    end
  end

  def has_more_missing?
    non_staple_count = @recipe.recipe_ingredients.reject { |ri| ri.ingredient.is_pantry_staple }.count
    non_staple_count > 3
  end

  def more_count
    non_staple_count = @recipe.recipe_ingredients.reject { |ri| ri.ingredient.is_pantry_staple }.count
    non_staple_count - 3
  end
end
