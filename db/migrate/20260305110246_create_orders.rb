class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :total_amount, null: false

      t.timestamps
    end

    add_check_constraint :orders, "total_amount >= 0", name: "total_amount_not_negative"
  end
end
