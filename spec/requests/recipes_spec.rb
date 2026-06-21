require 'rails_helper'

RSpec.describe "Recipes", type: :request do
  describe "GET /recipes (index)" do
    let!(:recipe1) { create(:recipe, title: "Pasta Carbonara") }
    let!(:recipe2) { create(:recipe, title: "Margherita Pizza") }
    let!(:ingredient1) { create(:ingredient, name: "eggs") }
    let!(:ingredient2) { create(:ingredient, name: "tomato") }

    before do
      create(:recipe_ingredient, recipe: recipe1, ingredient: ingredient1)
      create(:recipe_ingredient, recipe: recipe2, ingredient: ingredient2)
    end

    context "without filters" do
      it "returns all recipes" do
        get recipes_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Pasta Carbonara")
        expect(response.body).to include("Margherita Pizza")
      end
    end

    context "with ingredient filter" do
      it "filters recipes by matching ingredients" do
        get recipes_path, params: { ingredients: ingredient1.id }
        expect(response).to have_http_status(:ok)
      end
    end

    context "with max_missing filter" do
      it "limits results by missing ingredients" do
        get recipes_path, params: { max_missing: 2 }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /recipes/:slug (show)" do
    let(:recipe) { create(:recipe, slug: "pasta-carbonara") }
    let(:ingredient) { create(:ingredient) }

    before do
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient)
    end

    context "with valid slug" do
      it "returns recipe details" do
        get recipe_path("pasta-carbonara")
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("pasta-carbonara")
      end

      it "displays ingredients" do
        get recipe_path("pasta-carbonara")
        expect(response.body).to include(ingredient.display_name || ingredient.name)
      end
    end

    context "with invalid slug" do
      it "returns 404" do
        get recipe_path("non-existent")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /recipes/:slug/cook (cook mode)" do
    let(:recipe) { create(:recipe, slug: "pasta-carbonara") }

    it "returns cook mode view" do
      get cook_recipe_path("pasta-carbonara")
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for invalid slug" do
      get cook_recipe_path("non-existent")
      expect(response).to have_http_status(:not_found)
    end
  end
end
