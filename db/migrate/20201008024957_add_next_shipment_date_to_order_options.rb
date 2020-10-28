class AddNextShipmentDateToOrderOptions < ActiveRecord::Migration[6.0]
  def change
    add_column :order_options, :next_shipment_date, :datetime, default: -> { 'CURRENT_TIMESTAMP' }
  end
end
