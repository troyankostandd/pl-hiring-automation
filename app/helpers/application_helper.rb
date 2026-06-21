module ApplicationHelper
  def checked_if(condition)
    condition ? 'checked' : nil
  end

  def selected_if(condition)
    condition ? 'selected' : nil
  end

  # Renders a 5-star rating string (filled/empty) for an Allrecipes-style display.
  def star_rating(value)
    full = value.to_f.round.clamp(0, 5)
    ("★" * full) + ("☆" * (5 - full))
  end

  # Allrecipes-style slug for a title (apostrophes dropped, the rest hyphenated).
  # e.g. "Connie's Southern Style" => "connies-southern-style"
  def allrecipes_slug(title)
    title.to_s.downcase.gsub(/['’]/, "").gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
  end

  # Link straight to the recipe's detail page on Allrecipes. Uses the exact
  # resolved URL (with its numeric id) when we have it, otherwise a slug-based
  # recipe URL derived from the title.
  def allrecipes_url(recipe)
    recipe.canonical_url.presence || "https://www.allrecipes.com/recipe/#{allrecipes_slug(recipe.title)}/"
  end

  # Returns the search results URL to go "back" to, preserving the pantry,
  # filters, sort, and page. Falls back to a bare results page. Only accepts
  # local /recipes paths to avoid open-redirect-style links.
  def back_to_results_url
    back = params[:back].to_s
    back.start_with?("/recipes") ? back : recipes_path
  end

  # URL for the current page with some query params overridden.
  def page_url(overrides = {})
    recipes_path(request.query_parameters.merge(overrides))
  end

  # Hidden inputs that carry the current filter params through a pagination form,
  # so changing page size / jumping to a page preserves pantry, sort, and filters.
  def hidden_query_fields(only:)
    safe_join(
      only.filter_map do |key|
        value = params[key]
        hidden_field_tag(key, value) if value.present?
      end
    )
  end

  # A windowed list of page numbers around the current page, with :gap markers
  # standing in for skipped ranges, e.g. [1, :gap, 4, 5, 6, :gap, 20].
  def page_window(current, total, window: 2)
    return (1..total).to_a if total <= 7

    pages = [1, total]
    ((current - window)..(current + window)).each { |p| pages << p if p > 1 && p < total }
    pages = pages.uniq.sort

    pages.each_with_object([]) do |p, out|
      out << :gap if out.last.is_a?(Integer) && p - out.last > 1
      out << p
    end
  end
end
