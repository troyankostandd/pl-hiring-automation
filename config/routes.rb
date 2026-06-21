Rails.application.routes.draw do
  root "pages#home"

  get "/recipes", to: "recipes#index", as: :recipes
  get "/recipes/:slug", to: "recipes#show", as: :recipe, constraints: { slug: /[^\/]+/ }
  get "/recipes/:slug/cook", to: "recipes#cook", as: :cook_recipe

  get "/ingredients/autocomplete", to: "ingredients#autocomplete", defaults: { format: :json }

  get "/about", to: "pages#about"
  get "/health", to: "pages#health", defaults: { format: :json }

  get "up" => "rails/health#show", as: :rails_health_check
end
