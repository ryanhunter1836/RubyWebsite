class AddAccountCreatedToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :accountCreated, :boolean
  end
end
