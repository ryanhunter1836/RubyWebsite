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
        if frequency == 'three_months'
            "Every 3 Months"
        else
            "Every 6 Months"
        end
    end

    def get_vehicle_name(vehicle_id)
        vehicle = Vehicle.find(vehicle_id)
        make = vehicle.make
        model = vehicle.model
        year = vehicle.year
        "#{year} #{make} #{model}"
    end
end
