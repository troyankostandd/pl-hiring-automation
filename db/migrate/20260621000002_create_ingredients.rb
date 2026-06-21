class CreateIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :ingredients do |t|
      t.string :name, null: false
      t.string :display_name
      t.boolean :is_pantry_staple, default: false
      t.integer :usage_count, default: 0

      t.timestamps
    end

    add_index :ingredients, :name, unique: true
  end
end
