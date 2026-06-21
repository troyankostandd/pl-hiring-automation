class RecipeSearchQuery
  def initialize(ingredient_ids = [], max_missing = 3, sort_by = "best_match")
    @ingredient_ids = ingredient_ids.compact.map(&:to_i)
    @max_missing = max_missing.to_i
    @sort_by = sort_by
  end

  def relation
    if @ingredient_ids.empty?
      Recipe.all
    else
      Recipe.select(recipe_select_clause)
        .joins(:recipe_ingredients)
        .joins(:ingredients)
        .where(ingredients: { is_pantry_staple: false })
        .group("recipes.id")
        .having("COUNT(DISTINCT recipe_ingredients.ingredient_id) FILTER (WHERE recipe_ingredients.ingredient_id IN (?)) > 0", @ingredient_ids)
        .order(order_clause)
    end
  end

  private

  def recipe_select_clause
    <<-SQL
      recipes.*,
      COUNT(DISTINCT CASE WHEN recipe_ingredients.ingredient_id IN (#{@ingredient_ids.empty? ? 'NULL' : @ingredient_ids.join(',')}) THEN recipe_ingredients.ingredient_id END) as matched_count,
      COUNT(DISTINCT recipe_ingredients.ingredient_id) as total_count
    SQL
  end

  def order_clause
    case @sort_by
    when "quickest"
      "recipes.total_time_minutes ASC NULLS LAST"
    when "highest_rated"
      "recipes.ratings DESC NULLS LAST"
    else # "best_match"
      "(total_count - matched_count) ASC, (matched_count::float / NULLIF(total_count, 0)) DESC"
    end
  end
end
