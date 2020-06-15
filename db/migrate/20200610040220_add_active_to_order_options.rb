class AddActiveToOrderOptions < ActiveRecord::Migration[6.0]
  def change
    add_column :order_options, :active, :boolean
  end
end
