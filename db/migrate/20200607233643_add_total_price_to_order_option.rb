class AddTotalPriceToOrderOption < ActiveRecord::Migration[6.0]
  def change
    add_column :order_options, :total_price, :int
  end
end
