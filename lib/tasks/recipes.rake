namespace :recipes do
  desc "Seed recipes from JSON file"
  task seed: :environment do
    require 'json'

    json_file = Rails.root.join("db/seeds/recipes-en.json")
    unless json_file.exist?
      puts "Error: #{json_file} not found. Download it first."
      exit 1
    end

    puts "Seeding recipes from #{json_file}..."
    count = 0
    errors = 0

    File.readlines(json_file).each_with_index do |line, index|
      begin
        recipe_data = JSON.parse(line)
        Recipe.find_or_create_by!(source_url: recipe_data["source_url"]) do |recipe|
          recipe.title = recipe_data["title"]
          recipe.slug = generate_slug(recipe_data["title"], recipe_data["source_url"])
          recipe.description = recipe_data.dig("description", 0) || ""
          recipe.instructions = format_instructions(recipe_data.dig("instructions", 0) || "")
          recipe.image_url = recipe_data.dig("image", 0) || ""
          recipe.total_time_minutes = parse_time(recipe_data.dig("total_time", 0))
          recipe.prep_time_minutes = parse_time(recipe_data.dig("prep_time", 0))
          recipe.cook_time_minutes = parse_time(recipe_data.dig("cook_time", 0))
          recipe.yields = recipe_data.dig("yields", 0) || ""
          recipe.ratings = recipe_data.dig("ratings", 0)&.to_f
          recipe.ratings_count = recipe_data.dig("ratings_count", 0)&.to_i || 0
          recipe.category = recipe_data.dig("category", 0)
          recipe.cuisine = recipe_data.dig("cuisine", 0)

          # Process ingredients
          ingredient_list = recipe_data["ingredients"] || []
          recipe.recipe_ingredients.build_associations(ingredient_list, recipe)
        end

        count += 1
        puts "Seeded #{count} recipes..." if count % 100 == 0
      rescue => e
        errors += 1
        puts "Error on line #{index}: #{e.message}" if errors <= 10
      end
    end

    puts "\nSeeding complete!"
    puts "Seeded: #{count} recipes"
    puts "Errors: #{errors}"
  end

  private

  def generate_slug(title, url)
    slug = title.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
    # Append URL hash for uniqueness
    url_hash = url.hash.abs.to_s[-4..-1] || "0000"
    "#{slug}-#{url_hash}"
  end

  def format_instructions(instructions)
    if instructions.is_a?(Array)
      instructions.join("\n\n")
    else
      instructions.to_s
    end
  end

  def parse_time(time_str)
    return nil if time_str.blank?
    time_str.to_s.match(/\d+/)&.to_s&.to_i
  end
end
