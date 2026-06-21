FactoryBot.define do
  factory :ingredient do
    sequence(:name) { |n| "ingredient-#{n}" }
    sequence(:display_name) { |n| "Ingredient #{n}" }
    is_pantry_staple { false }
    usage_count { 50 }

    trait :pantry_staple do
      is_pantry_staple { true }
      usage_count { 500 }
    end
  end
end
