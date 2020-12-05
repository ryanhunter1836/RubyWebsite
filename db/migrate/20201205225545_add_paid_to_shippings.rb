class AddPaidToShippings < ActiveRecord::Migration[6.0]
  def change
    add_column :shippings, :paid, :boolean, default: false
  end
end
