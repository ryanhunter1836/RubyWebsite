require 'csv'

def getSize(sizeString)
  size = sizeString.split[2]
  size.first(2).to_i
end

def getWiperType(wipertypeString)
  if(wipertypeString.include? "Beam")
    0
  else
    1
  end
end

def getFrequency(interval, count)
  if(interval.include? "month")
    if(count.include? "6")
      0
    else
      1
    end
  else
    2
  end
end

User.create(
  name: "Admin",
  email: "admin@wiperstoyou.com",
  password: Rails.application.credentials.admin_password,
  password_confirmation: Rails.application.credentials.admin_password,
  admin: true,
  activated: true
)


#Seed method for vehicles
CSV.foreach(Rails.root.join('lib', 'seeds', 'wipersizes.csv'), headers: false) do |row|
  Vehicle.find_or_create_by(make: row[0],
                 model: row[1],
                 year: row[2],
                 driver_front: row[3].to_i,
                 passenger_front: row[4].to_i
  )
end

#Seed method for Stripe products
CSV.foreach(Rails.root.join('lib', 'seeds', 'prices.csv'), headers: true) do |row|
  StripeProduct.find_or_create_by(
    stripe_id: row['Price ID'],
    price: row['Amount'],
    size: getSize(row['Product Name']),
    wipertype: getWiperType(row['Product Name']),
    frequency: getFrequency(row['Interval'], row['Interval Count'])
  )
end