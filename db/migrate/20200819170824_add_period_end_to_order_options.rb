class AddPeriodEndToOrderOptions < ActiveRecord::Migration[6.0]
  def change
    add_column :order_options, :cycle_anchor, :bigint
  end
end
