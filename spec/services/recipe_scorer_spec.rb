require 'rails_helper'

RSpec.describe RecipeScorer do
  let(:recipe) { create(:recipe) }
  let(:ingredient1) { create(:ingredient, name: "eggs", is_pantry_staple: false) }
  let(:ingredient2) { create(:ingredient, name: "flour", is_pantry_staple: true) }
  let(:ingredient3) { create(:ingredient, name: "butter", is_pantry_staple: true) }

  before do
    create(:recipe_ingredient, recipe: recipe, ingredient: ingredient1)
    create(:recipe_ingredient, recipe: recipe, ingredient: ingredient2)
    create(:recipe_ingredient, recipe: recipe, ingredient: ingredient3)
  end

  describe "#score_recipe" do
    context "when user has all non-staple ingredients" do
      let(:pantry_ids) { [ingredient1.id] }

      it "returns fully cookable recipe" do
        score = RecipeScorer.new(pantry_ids).score_recipe(recipe)
        expect(score[:is_fully_cookable]).to be true
        expect(score[:missing]).to eq(0)
        expect(score[:matched]).to eq(1)
      end
    end

    context "when user has some ingredients" do
      let(:pantry_ids) { [] }

      it "returns partial match" do
        score = RecipeScorer.new(pantry_ids).score_recipe(recipe)
        expect(score[:is_fully_cookable]).to be false
        expect(score[:missing]).to eq(1)
        expect(score[:match_ratio]).to eq(0.0)
      end
    end
  end

  describe ".rank_recipes" do
    let(:recipe2) { create(:recipe, total_time_minutes: 20) }
    let(:recipe3) { create(:recipe, total_time_minutes: 30, ratings: 4.5) }

    before do
      create(:recipe_ingredient, recipe: recipe2, ingredient: ingredient1)
      create(:recipe_ingredient, recipe: recipe3, ingredient: ingredient1)
    end

    context "best_match sorting" do
      it "ranks by missing ingredients" do
        recipes = [recipe, recipe2, recipe3]
        ranked = RecipeScorer.rank_recipes(recipes, [ingredient1.id])
        expect(ranked.first[:missing]).to be <= ranked.last[:missing]
      end
    end

    context "quickest sorting" do
      it "ranks by total_time_minutes" do
        recipes = [recipe, recipe2, recipe3]
        ranked = RecipeScorer.rank_recipes(recipes, [ingredient1.id], 3, "quickest")
        times = ranked.map { |r| r[:recipe].total_time_minutes || Float::INFINITY }
        expect(times).to eq(times.sort)
      end
    end
  end
end
