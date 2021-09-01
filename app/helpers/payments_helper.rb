module PaymentsHelper
    def calc_total_price(price)
        #price = price * 1.0825
        number_to_currency(price / 100)
    end
end
