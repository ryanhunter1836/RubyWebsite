class ShippingAddress
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks
    before_validation :upcase_state, :calc_tax

    attr_accessor :address1, :address2, :city, :state, :postal, :phone, :tax_required

    STATE_LIST = %w(ALABAMA
        ALASKA
        ARIZONA
        ARKANSAS
        CALIFORNIA
        COLORADO
        CONNECTICUT
        DELAWARE
        FLORIDA
        GEORGIA
        HAWAII
        IDAHO
        ILLINOIS
        INDIANA
        IOWA
        KANSAS
        KENTUCKY
        LOUISIANA
        MAINE
        MARYLAND
        MASSACHUSETTS
        MICHIGAN
        MINNESOTA
        MISSISSIPPI
        MISSOURI
        MONTANA
        NEBRASKA
        NEVADA
        NEW HAMPSHIRE
        NEW JERSEY
        NEW MEXICO
        NEW YORK
        NORTH CAROLINA
        NORTH DAKOTA
        OHIO
        OKLAHOMA
        OREGON
        PENNSYLVANIA
        RHODE ISLAND
        SOUTH CAROLINA
        SOUTH DAKOTA
        TENNESSEE
        TEXAS
        UTAH
        VERMONT
        VIRGINIA
        WASHINGTON
        WEST VIRGINIA
        WISCONSIN
        WYOMING,
        AL
        AK
        AZ
        AR
        CA
        CO
        CT
        DE
        DC
        FL
        GA
        HI
        ID
        IL
        IN
        IA
        KS
        KY
        LA
        ME
        MD
        MA
        MI
        MN
        MS
        MO
        MT
        NE
        NV
        NH
        NJ
        NM
        NY
        NC
        ND
        OH
        OK
        OR
        PA
        RI
        SC
        SD
        TN
        TX
        UT        
        VT 
        VI
        VA
        WA
        WV
        WI
        WY)

    validates :address1, presence: true
    validates :city, presence: true
    validates :state, presence: true, inclusion: { in: STATE_LIST, message: "is invalid" }
    validates :postal, presence: true, format: { with: /(^\d{5}$)|(^\d{5}-\d{4}$)/, message: "is invalid" }

    def upcase_state
        self.state = state.upcase
    end

    def calc_tax
        self.tax_required = (self.state == "TX" || self.state == "TEXAS") ? 1 : 0
    end

end
