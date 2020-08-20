class AddPeriodEndToOrderOptions < ActiveRecord::Migration[6.0]
  def change
    add_column :order_options, :period_end, :bigint
  end
end
