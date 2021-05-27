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
      t.integer "wipertype"
      t.datetime "created_at", precision: 6, null: false
      t.datetime "updated_at", precision: 6, null: false
      t.belongs_to :user
    end
  end
end
