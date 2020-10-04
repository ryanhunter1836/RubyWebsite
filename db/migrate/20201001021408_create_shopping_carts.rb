class CreateShoppingCarts < ActiveRecord::Migration[6.0]
  def change
    create_table :shopping_carts do |t|
      t.integer "order_options_ids", array: true, default: []
      t.timestamps
    end
  end
end
