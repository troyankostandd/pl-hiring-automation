FactoryBot.define do
  factory :recipe_ingredient do
    recipe
    ingredient
    original_text { "2 cups ingredient" }
    quantity { 2 }
    unit { "cup" }
    position { 1 }
  end
end
