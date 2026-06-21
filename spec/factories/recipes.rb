FactoryBot.define do
  factory :recipe do
    sequence(:title) { |n| "Recipe #{n}" }
    sequence(:slug) { |n| "recipe-#{n}" }
    sequence(:source_url) { |n| "https://example.com/recipe-#{n}" }
    description { "A delicious recipe" }
    instructions { "1. Do this\n\n2. Then do that\n\n3. Finish" }
    image_url { "https://example.com/image.jpg" }
    total_time_minutes { 30 }
    prep_time_minutes { 10 }
    cook_time_minutes { 20 }
    yields { "4 servings" }
    ratings { 4.5 }
    ratings_count { 100 }
    ingredient_count { 5 }
    category { "main" }
    cuisine { "italian" }
  end
end
