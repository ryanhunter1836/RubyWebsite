module ReturnHelper
    def get_reason(reason)
        if reason == 0
            "Wipers are the wrong size"
        elsif reason == 1
            "Wipers don't fit my vehicle"
        elsif reason == 2
            "Wipers are damaged"
        else
            "Don't need the wipers"
        end
    end
end
