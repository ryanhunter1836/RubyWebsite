class AddAccountCreatedToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :account_created, :boolean
  end
end
