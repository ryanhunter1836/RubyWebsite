# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_06_10_040220) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "order_options", force: :cascade do |t|
    t.integer "frequency"
    t.integer "quality"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "next_delivery", precision: 6
    t.bigint "shopping_cart_id"
    t.bigint "user_id"
    t.bigint "vehicle_id"
    t.string "stripe_product", default: [], array: true
    t.integer "total_price"
    t.boolean "active"
    t.index ["shopping_cart_id"], name: "index_order_options_on_shopping_cart_id"
    t.index ["user_id"], name: "index_order_options_on_user_id"
    t.index ["vehicle_id"], name: "index_order_options_on_vehicle_id", unique: true
  end

  create_table "shipping_addresses", force: :cascade do |t|
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.integer "postal"
    t.bigint "order_option_id"
    t.bigint "user_id"
    t.index ["order_option_id"], name: "index_shipping_addresses_on_order_option_id"
    t.index ["user_id"], name: "index_shipping_addresses_on_user_id"
  end

  create_table "shopping_carts", force: :cascade do |t|
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_shopping_carts_on_user_id"
  end

  create_table "stripe_products", force: :cascade do |t|
    t.string "stripe_id"
    t.integer "price"
    t.integer "size"
    t.integer "quality"
    t.integer "frequency"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.boolean "admin", default: false
    t.string "activation_digest"
    t.boolean "activated", default: false
    t.datetime "activated_at"
    t.string "reset_digest"
    t.datetime "reset_sent_at"
    t.string "stripeCustomerId"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "make"
    t.string "model"
    t.integer "year"
    t.integer "driver_front"
    t.integer "passenger_front"
    t.integer "rear"
  end

  add_foreign_key "order_options", "vehicles"
end
