class CreateRecipeIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :recipe_ingredients do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      t.string :original_text
      t.decimal :quantity, precision: 10, scale: 3
      t.string :unit
      t.integer :position

      t.timestamps
    end

    add_index :recipe_ingredients, [:recipe_id, :ingredient_id], unique: true
    add_index :recipe_ingredients, [:recipe_id, :position]
  end
end
