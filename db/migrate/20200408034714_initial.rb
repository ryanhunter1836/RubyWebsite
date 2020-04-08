class Initial < ActiveRecord::Migration[6.0]
  def change
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
      t.index ["email"], name: "index_users_on_email", unique: true
    end
  end
end
