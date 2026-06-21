require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET / (home)" do
    it "returns home page" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Cook from what you already have")
    end

    it "displays recipe count" do
      create_list(:recipe, 5)
      get root_path
      expect(response.body).to include("5 recipes ready")
    end
  end

  describe "GET /about" do
    it "returns about page" do
      get about_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("How matching works")
    end
  end

  describe "GET /health" do
    before { create_list(:recipe, 3); create_list(:ingredient, 2) }

    it "returns health check JSON" do
      get health_path
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/json")
    end

    it "includes recipe and ingredient counts" do
      get health_path
      json = JSON.parse(response.body)
      expect(json["recipes"]).to eq(3)
      expect(json["ingredients"]).to eq(2)
      expect(json["status"]).to eq("ok")
    end
  end
end
