class AddStripeIdToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :stripeCustomerId, :string
  end
end
