class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :source_url, null: false
      t.text :description
      t.text :instructions
      t.string :image_url
      t.integer :total_time_minutes
      t.integer :prep_time_minutes
      t.integer :cook_time_minutes
      t.string :yields
      t.decimal :ratings, precision: 3, scale: 2
      t.integer :ratings_count, default: 0
      t.integer :ingredient_count
      t.string :category
      t.string :cuisine

      t.timestamps
    end

    add_index :recipes, :slug, unique: true
    add_index :recipes, :source_url, unique: true
    add_index :recipes, :total_time_minutes
    add_index :recipes, :ratings
    add_index :recipes, :ingredient_count
  end
end
