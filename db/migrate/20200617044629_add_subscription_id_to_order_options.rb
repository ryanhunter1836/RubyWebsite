class AddSubscriptionIdToOrderOptions < ActiveRecord::Migration[6.0]
  def change
    add_column :order_options, :subscription_id, :string
  end
end
