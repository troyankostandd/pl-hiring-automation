class AddCanonicalUrlToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :canonical_url, :string
  end
end
