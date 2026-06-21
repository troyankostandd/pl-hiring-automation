require 'rails_helper'

RSpec.describe IngredientNormalizer do
  describe "quantity parsing" do
    it "parses whole numbers" do
      result = IngredientNormalizer.call("2 cups flour")
      expect(result[:quantity]).to eq(2)
    end

    it "parses fractions" do
      result = IngredientNormalizer.call("1/2 cup milk")
      expect(result[:quantity]).to eq(0.5)
    end

    it "parses mixed numbers" do
      result = IngredientNormalizer.call("1 1/2 cups sugar")
      expect(result[:quantity]).to eq(1.5)
    end

    it "returns nil when no quantity present" do
      result = IngredientNormalizer.call("fresh basil")
      expect(result[:quantity]).to be_nil
    end
  end

  describe "unit parsing" do
    it "recognizes cups" do
      result = IngredientNormalizer.call("2 cups flour")
      expect(result[:unit]).to eq("cup")
    end

    it "recognizes tablespoons" do
      result = IngredientNormalizer.call("3 tbsp butter")
      expect(result[:unit]).to eq("tbsp")
    end

    it "recognizes grams" do
      result = IngredientNormalizer.call("500g flour")
      expect(result[:unit]).to eq("g")
    end
  end

  describe "ingredient name parsing" do
    it "extracts ingredient name" do
      result = IngredientNormalizer.call("2 cups all-purpose flour")
      expect(result[:ingredient_name]).to include("flour")
    end

    it "removes descriptors" do
      result = IngredientNormalizer.call("1 1/2 cups finely chopped fresh cilantro leaves")
      expect(result[:ingredient_name]).to eq("cilantro")
    end

    it "handles comma-separated descriptors" do
      result = IngredientNormalizer.call("400g pancetta, finely diced")
      expect(result[:ingredient_name]).to eq("pancetta")
    end
  end

  describe "pantry staple detection" do
    it "identifies salt as pantry staple" do
      result = IngredientNormalizer.call("salt to taste")
      expect(result[:is_pantry_staple]).to be true
    end

    it "identifies pepper as pantry staple" do
      result = IngredientNormalizer.call("freshly ground black pepper")
      expect(result[:is_pantry_staple]).to be true
    end

    it "identifies butter as pantry staple" do
      result = IngredientNormalizer.call("2 tbsp butter")
      expect(result[:is_pantry_staple]).to be true
    end

    it "identifies non-staple ingredients" do
      result = IngredientNormalizer.call("400g pancetta")
      expect(result[:is_pantry_staple]).to be false
    end
  end

  describe "edge cases" do
    it "handles 'plus more' phrases" do
      result = IngredientNormalizer.call("olive oil, plus more for serving")
      expect(result[:ingredient_name]).to include("oil")
    end

    it "handles optional ingredients" do
      result = IngredientNormalizer.call("optional: red pepper flakes")
      expect(result[:ingredient_name]).to include("red pepper")
    end
  end
end
