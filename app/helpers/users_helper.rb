module UsersHelper
    def get_wipertype_string_enum(wipertype)
        if wipertype == 0
            'Beam'
        else
            'Hybrid'
        end
    end  
end
