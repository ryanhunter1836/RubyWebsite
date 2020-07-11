class CreateVehicle < ActiveRecord::Migration[6.0]
  def change
    create_table :vehicles do |t|
      t.string "make"
      t.string "model"
      t.integer "year"
      t.integer "driver_front"
      t.integer "passenger_front"
      t.integer "rear"
    end
    create_table :order_options do |t|
      t.integer "frequency"
      t.integer "quality"
      t.datetime "created_at", precision: 6, null: false
      t.datetime "updated_at", precision: 6, null: false
      t.datetime "next_delivery", precision: 6
      t.belongs_to :user
    end
  end
end
