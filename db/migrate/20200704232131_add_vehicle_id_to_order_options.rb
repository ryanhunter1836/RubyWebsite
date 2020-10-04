class AddVehicleIdToOrderOptions < ActiveRecord::Migration[6.0]
  def change
    add_column :order_options, :vehicle_id, :int
  end
end
