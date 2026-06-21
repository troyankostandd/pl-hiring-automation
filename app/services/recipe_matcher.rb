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
    @only_cookable = [true, "true"].include?(filters[:only_cookable])
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
    tokens =
      case ingredients
      when Array then ingredients
      when String then ingredients.split(",")
      else []
      end

    tokens.map { |t| t.to_s.strip }.reject(&:blank?).flat_map { |t| resolve_token(t) }.uniq
  end

  # A pantry token may be a numeric ingredient id (from autocomplete) or a
  # free-text ingredient name (from the search box). Resolve both to ids.
  def resolve_token(token)
    return [token.to_i] if token.match?(/\A\d+\z/)

    name = token.downcase
    exact = Ingredient.where("LOWER(name) = ?", name).pluck(:id)
    return exact if exact.any?

    # Fall back to the most-used ingredient whose name contains the token.
    Ingredient.where("LOWER(name) LIKE ?", "%#{name}%")
              .order(usage_count: :desc)
              .limit(1)
              .pluck(:id)
  end

  def find_potential_recipes
    if @pantry_ingredient_ids.empty?
      Recipe.includes(recipe_ingredients: :ingredient).all
    else
      Recipe
        .joins(:recipe_ingredients)
        .where("recipe_ingredients.ingredient_id IN (?)", @pantry_ingredient_ids)
        .includes(recipe_ingredients: :ingredient)
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
