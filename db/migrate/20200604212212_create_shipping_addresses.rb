class CreateShippingAddresses < ActiveRecord::Migration[6.0]
  def change
    create_table :shipping_addresses do |t|
      t.string "address1"
      t.string "address2"
      t.string "city"
      t.string "state"
      t.integer "postal"
      t.belongs_to :order_option
      t.belongs_to :user
    end
  end
end
