class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false, limit: 254
      t.integer :role, null: false, default: 0

      t.timestamps
    end

    add_index :users, "lower(email)", unique: true

    add_check_constraint :users, "char_length(name) >= 2", name: "name_min_length_2"
    add_check_constraint :users, "char_length(email) >= 6", name: "email_min_length_6"
  end
end
