class AddSubscriptionItemIdToOrderOptions < ActiveRecord::Migration[6.0]
  def change
    add_column :order_options, :subscription_item_id, :string, array:true, default: []
  end
end
