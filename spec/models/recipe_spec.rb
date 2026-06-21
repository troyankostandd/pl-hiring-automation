require 'rails_helper'

RSpec.describe Recipe, type: :model do
  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:source_url) }
    it { should validate_uniqueness_of(:slug) }
    it { should validate_uniqueness_of(:source_url) }
  end

  describe "associations" do
    it { should have_many(:recipe_ingredients).dependent(:delete_all) }
    it { should have_many(:ingredients).through(:recipe_ingredients) }
  end

  describe ".find_by_slug" do
    let(:recipe) { create(:recipe, slug: "pasta-carbonara") }

    it "finds recipe by slug" do
      expect(Recipe.find_by_slug("pasta-carbonara")).to eq(recipe)
    end

    it "returns nil for non-existent slug" do
      expect(Recipe.find_by_slug("non-existent")).to be_nil
    end
  end
end
