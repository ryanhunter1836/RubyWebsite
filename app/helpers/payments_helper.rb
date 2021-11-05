module PaymentsHelper
    def format_price(price)
        number_to_currency(price / 100)
    end
end
