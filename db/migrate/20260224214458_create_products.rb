class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.integer :price, null: false
      t.integer :stock, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :products, "lower(name)", unique: true

    add_check_constraint :products, "char_length(name) > 1", name: "name_min_length_2"
    add_check_constraint :products, "price > 0", name: "price_must_be_positive"
    add_check_constraint :products, "stock >= 0", name: "stock_must_not_be_negative"
  end
end
