class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :unit_price, null: false

      t.timestamps
    end

    add_index :order_items, [ :order_id, :product_id ], unique: true
    
    add_check_constraint :order_items, "quantity >= 1", name: "quantity_min_1"
    add_check_constraint :order_items, "unit_price > 0", name: "unit_price_positive"
  end
end
