class AddPaymentMethodIdToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :payment_method_id, :string
  end
end
