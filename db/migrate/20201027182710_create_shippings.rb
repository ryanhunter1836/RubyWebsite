class CreateShippings < ActiveRecord::Migration[6.0]
  def change
    create_table :shippings do |t|
      # t.references :order_options, index: true, foreign_key: true, column: :order_option_id
      t.bigint "order_option_id"
      t.timestamp "shipped_at"
    end
  end
end
