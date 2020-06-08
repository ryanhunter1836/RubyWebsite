class CreateStripeProducts < ActiveRecord::Migration[6.0]
  def change
    create_table :stripe_products do |t|
      t.string "stripe_id"
      t.integer "price"
      t.integer "size"
      t.integer "quality"
      t.integer "frequency"
    end
  end
end
