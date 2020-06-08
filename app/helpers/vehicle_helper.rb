module VehicleHelper
    def get_quality_string(quality)
        if quality == 'good'
            "Good"
        elsif quality == 'better'
            "Better"
        else
            "Best"
        end
    end

    def get_frequency_string(frequency)
        if frequency == 'six_months'
            "Every 6 Months"
        else
            "Every 12 Months"
        end
    end

    def get_vehicle_name(vehicle_id)
        vehicle = Vehicle.find(vehicle_id)
        make = vehicle.make
        model = vehicle.model
        year = vehicle.year
        "#{year} #{make} #{model}"
    end
    

    def get_vehicle_make(vehicle_id)
        Vehicle.find(vehicle_id).make
    end

    def get_vehicle_model(vehicle_id)
        Vehicle.find(vehicle_id).model
    end

    def get_vehicle_year(vehicle_id)
        Vehicle.find(vehicle_id).year
    end
end
