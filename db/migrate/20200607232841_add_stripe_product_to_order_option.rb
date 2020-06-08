class AddStripeProductToOrderOption < ActiveRecord::Migration[6.0]
  def change
    add_column :order_options, :stripe_products, :string, array:true, default: []
  end
end
