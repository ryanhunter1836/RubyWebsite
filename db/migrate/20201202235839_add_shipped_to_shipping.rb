class AddShippedToShipping < ActiveRecord::Migration[6.0]
  def change
    add_column :shippings, :shipped, :bool, default: false
    add_column :shippings, :order_number, :string
    add_column :shippings, :scheduled_date, :datetime
  end
end
