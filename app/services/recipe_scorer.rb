class RecipeScorer
  def initialize(pantry_ingredient_ids, max_missing_default = 3)
    @pantry_ingredient_ids = Set.new(pantry_ingredient_ids)
    @max_missing_default = max_missing_default
  end

  def self.call(recipe, pantry_ingredient_ids)
    new(pantry_ingredient_ids).score_recipe(recipe)
  end

  def score_recipe(recipe)
    non_staple_ingredients = recipe.recipe_ingredients.reject { |ri| ri.ingredient.is_pantry_staple }
    total = non_staple_ingredients.count
    matched = non_staple_ingredients.count { |ri| @pantry_ingredient_ids.include?(ri.ingredient_id) }
    missing = total - matched

    {
      recipe: recipe,
      total: total,
      matched: matched,
      missing: missing,
      match_ratio: total.zero? ? 0.0 : matched.to_f / total,
      is_fully_cookable: missing.zero?,
      within_threshold: missing <= @max_missing_default
    }
  end

  def self.rank_recipes(recipes, pantry_ingredient_ids, max_missing = 3, sort_by = "best_match")
    scores = recipes.map { |r| new(pantry_ingredient_ids, max_missing).score_recipe(r) }

    case sort_by
    when "quickest"
      scores.sort_by { |s| s[:recipe].total_time_minutes || Float::INFINITY }
    when "highest_rated"
      scores.sort_by { |s| -(s[:recipe].ratings || 0) }
    else # "best_match"
      scores
        .select { |s| s[:within_threshold] }
        .sort_by { |s| [s[:missing], -s[:match_ratio], s[:recipe].total_time_minutes || Float::INFINITY] }
    end
  end
end
