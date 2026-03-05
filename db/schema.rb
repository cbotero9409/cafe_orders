# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_03_184338) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "price", null: false
    t.integer "stock", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_products_on_lower_name", unique: true
    t.check_constraint "char_length(name::text) > 1", name: "name_min_length_2"
    t.check_constraint "price > 0", name: "price_must_be_positive"
    t.check_constraint "stock >= 0", name: "stock_must_not_be_negative"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", limit: 254, null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.check_constraint "char_length(email::text) >= 6", name: "email_min_length_6"
    t.check_constraint "char_length(name::text) >= 2", name: "name_min_length_2"
  end
end
