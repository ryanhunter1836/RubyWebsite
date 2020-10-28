module UsersHelper
    def get_quality_string_enum(quality)
        if quality == 0
            'Good'
        elsif quality == 1
            'Better'
        else
            'Best'
        end
    end  
end
