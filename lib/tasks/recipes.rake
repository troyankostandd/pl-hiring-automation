namespace :recipes do
  desc "Seed recipes from the english-language dataset (db/seeds/recipes-en.json)"
  task seed: :environment do
    require "json"

    json_file = Rails.root.join("db/seeds/recipes-en.json")
    unless json_file.exist?
      puts "Error: #{json_file} not found."
      puts "Download it with:"
      puts "  curl -O https://pennylane-interviewing-assets-20220328.s3.eu-west-1.amazonaws.com/recipes-en.json.gz"
      puts "  gzip -dc recipes-en.json.gz > db/seeds/recipes-en.json"
      exit 1
    end

    puts "Loading #{json_file}..."
    recipes = JSON.parse(File.read(json_file))
    puts "Parsed #{recipes.size} recipes. Seeding..."

    # Clear existing data for a clean, repeatable seed.
    RecipeIngredient.delete_all
    Recipe.delete_all
    Ingredient.delete_all

    # In-memory cache of canonical ingredient name => Ingredient record,
    # so we normalize/create each canonical ingredient only once.
    ingredient_cache = {}
    created = 0
    skipped = 0
    errors = 0

    recipes.each_with_index do |data, index|
      begin
        title = data["title"].to_s.strip
        next (skipped += 1) if title.empty?

        prep = data["prep_time"].to_i
        cook = data["cook_time"].to_i

        recipe = Recipe.create!(
          title: title,
          slug: generate_slug(title, index),
          source_url: "https://www.allrecipes.com/recipe/#{index}",
          description: "",
          instructions: "",
          image_url: direct_image_url(data["image"].to_s),
          total_time_minutes: prep + cook,
          prep_time_minutes: prep,
          cook_time_minutes: cook,
          yields: "",
          ratings: data["ratings"]&.to_f,
          ratings_count: 0,
          category: data["category"].presence,
          cuisine: data["cuisine"].presence
        )

        rows = []
        seen = {}
        position = 0
        Array(data["ingredients"]).each do |line|
          parsed = IngredientNormalizer.call(line.to_s)
          name = parsed[:ingredient_name].to_s.strip
          next if name.empty? || name.length > 100
          next if seen[name] # de-dupe canonical ingredient within a recipe

          ingredient = ingredient_cache[name] ||= Ingredient.create_or_find_by!(name: name) do |i|
            i.display_name = name.split.map(&:capitalize).join(" ")
            i.is_pantry_staple = parsed[:is_pantry_staple]
          end

          seen[name] = true
          rows << {
            recipe_id: recipe.id,
            ingredient_id: ingredient.id,
            original_text: parsed[:original_text].to_s[0, 255],
            quantity: parsed[:quantity],
            unit: parsed[:unit],
            position: (position += 1),
            created_at: recipe.created_at,
            updated_at: recipe.updated_at
          }
        end

        RecipeIngredient.insert_all(rows) if rows.any?
        recipe.update_column(:ingredient_count, rows.size)

        created += 1
        puts "Seeded #{created} recipes..." if created % 500 == 0
      rescue => e
        errors += 1
        puts "Error on recipe #{index} (#{data['title']}): #{e.message}" if errors <= 10
      end
    end

    puts "Updating ingredient usage counts..."
    ActiveRecord::Base.connection.execute(<<~SQL)
      UPDATE ingredients SET usage_count = sub.cnt
      FROM (
        SELECT ingredient_id, COUNT(*) AS cnt
        FROM recipe_ingredients GROUP BY ingredient_id
      ) sub
      WHERE ingredients.id = sub.ingredient_id
    SQL

    puts "\nSeeding complete!"
    puts "Recipes:     #{Recipe.count}"
    puts "Ingredients: #{Ingredient.count}"
    puts "Links:       #{RecipeIngredient.count}"
    puts "Pantry staples: #{Ingredient.pantry_staples.count}"
    puts "Skipped: #{skipped}, Errors: #{errors}"
  end

  private

  # The dataset's images are wrapped in a meredith image proxy that returns 400
  # for our requests; the inner onecms URL it points at works directly.
  def direct_image_url(url)
    return url if url.blank?
    if url.include?("imagesvc.meredithcorp.io")
      inner = Rack::Utils.parse_query(URI.parse(url).query.to_s)["url"]
      return inner if inner.present?
    end
    url
  rescue URI::InvalidURIError
    url
  end

  def generate_slug(title, index)
    base = title.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
    base = "recipe" if base.empty?
    "#{base}-#{index}"
  end
end
