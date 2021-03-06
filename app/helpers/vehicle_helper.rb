module VehicleHelper
    include ActionView::Helpers::NumberHelper
    require 'date'

    def get_wipertype_string(wipertype)
        if wipertype == 'beam'
            "Beam"
        else
            "Hybrid"
        end
    end

    def get_frequency_string(frequency)
        if frequency == 'six_months'
            "Every 6 Months"
        elsif frequency == 'nine_months'
            "Every 9 Months"
        else
            "Every 12 Months"
        end
    end

    def get_shipping_string(shipping_address)
        result = shipping_address.address1 + " "
        result += shipping_address.address2 + "<br/>"
        result += shipping_address.city + " "
        result += shipping_address.state + " "
        result += shipping_address.postal.to_s
        result.html_safe
    end

    def get_vehicle_name(vehicle_id)
        vehicle = Vehicle.find(vehicle_id)
        make = vehicle.make
        model = vehicle.model
        year = vehicle.year
        "#{year} #{make} #{model}"
    end

    def get_vehicle_details(vehicle_id)
        vehicle = Vehicle.find(vehicle_id)
        hash = {:make => vehicle.make, :model => vehicle.model, :year => vehicle.year}
    end

    #This is a shim until I can figure out a more proper way to do it
    #Returns every id for the make
    def get_dropdown_value_make(make)
        Vehicle.select('DISTINCT ON ("make") id').where(make: make).pluck(:id)
    end

    def get_dropdown_value_model(make, model)
        Vehicle.where(make: make, model: model).select('DISTINCT ON ("model") id, model').pluck(:id)
    end

    def get_dropdown_value_year(make, model, year)
        Vehicle.where(make: make, model: model, year: year).select('DISTINCT ON ("year") id, year').pluck(:id)
    end

    def pretty_amount(amount_in_cents)
        number_to_currency(amount_in_cents / 100)
    end

    def epoch_to_datetime(epoch) 
        Time.at(epoch).to_datetime
    end
end
