class AddPaymentMethodIdToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :paymentMethodId, :string
  end
end
