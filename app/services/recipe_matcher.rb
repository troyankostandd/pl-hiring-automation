class RecipeMatcher
  PANTRY_STAPLES = %w[
    salt black pepper water oil olive oil butter sugar all-purpose flour
  ].freeze

  def self.call(pantry_ingredients, filters = {})
    new(pantry_ingredients, filters).match
  end

  def initialize(pantry_ingredients, filters = {})
    @pantry_ingredients = pantry_ingredients
    @pantry_ingredient_ids = resolve_ingredient_ids(pantry_ingredients)
    @max_missing = filters[:max_missing]&.to_i || 3
    @only_cookable = filters[:only_cookable] == "true"
    @exclusions = filters[:exclusions]&.split(",")&.map(&:strip) || []
    @sort_by = filters[:sort_by] || "best_match"
    @page = filters[:page]&.to_i || 1
    @per_page = filters[:per_page]&.to_i || 25
  end

  def match
    all_recipes = find_potential_recipes
    scored_recipes = RecipeScorer.rank_recipes(
      all_recipes,
      @pantry_ingredient_ids,
      @max_missing,
      @sort_by
    )

    filtered_recipes = filter_results(scored_recipes)

    {
      total_count: filtered_recipes.count,
      results: paginate(filtered_recipes),
      page: @page,
      per_page: @per_page,
      pantry_count: @pantry_ingredient_ids.count
    }
  end

  private

  def resolve_ingredient_ids(ingredients)
    case ingredients
    when Array
      ingredients.compact.map(&:to_i)
    when String
      ingredients.split(",").compact.map(&:strip).map(&:to_i)
    else
      []
    end
  end

  def find_potential_recipes
    if @pantry_ingredient_ids.empty?
      Recipe.all
    else
      Recipe
        .joins(:recipe_ingredients)
        .where("recipe_ingredients.ingredient_id IN (?)", @pantry_ingredient_ids)
        .distinct
    end
  end

  def filter_results(scored_recipes)
    scored_recipes
      .select { |s| @only_cookable ? s[:is_fully_cookable] : true }
      .select { |s| s[:within_threshold] }
      .reject { |s| has_excluded_ingredients?(s[:recipe]) }
  end

  def has_excluded_ingredients?(recipe)
    return false if @exclusions.empty?

    recipe_ingredients = recipe.ingredients.map { |i| i.name.downcase }
    @exclusions.any? { |excl| recipe_ingredients.any? { |ing| ing.include?(excl.downcase) } }
  end

  def paginate(results)
    start_idx = (@page - 1) * @per_page
    results[start_idx, @per_page] || []
  end
end
