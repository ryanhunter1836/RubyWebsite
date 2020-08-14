class AddStripeProductsToOrderOptions < ActiveRecord::Migration[6.0]
  def change
    add_column :order_options, :stripe_products, :json, default: {}
  end
end
