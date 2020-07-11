require 'csv'

def getSize(sizeString)
  size = sizeString.split[2]
  size.first(2).to_i
end

def getQuality(qualityString)
  if(qualityString.include? "Good")
    0
  elsif(qualityString.include? "Better")
    1
  else
    1
  end
end

def getFrequency(interval, count)
  if(interval.include? "month")
    0
  else
    1
  end
end

# Create a main sample user.
User.create!(name:  "Example User",
             email: "example@example.com",
             password:              "foobar",
             password_confirmation: "foobar",
             admin:     true,
             activated: true,
             activated_at: Time.zone.now)

# Generate a bunch of additional users.
99.times do |n|
  name  = Faker::Name.name
  email = "example-#{n+1}@example.com"
  password = "password"
  User.create!(name:  name,
              email: email,
              password:              password,
              password_confirmation: password,
              activated: true,
              activated_at: Time.zone.now)
end

CSV.foreach(Rails.root.join('lib', 'seeds', 'sample_wipersizes.csv'), headers: false) do |row|
  Vehicle.create(make: row[0],
                 model: row[1],
                 year: row[2],
                 driver_front: row[3].to_i,
                 passenger_front: row[4].to_i
  )
end

#Seed method for Stripe products
CSV.foreach(Rails.root.join('lib', 'seeds', 'prices.csv'), headers: true) do |row|
  StripeProduct.create(
    stripe_id: row['Price ID'],
    price: row['Amount'],
    size: getSize(row['Product Name']),
    quality: getQuality(row['Product Name']),
    frequency: getFrequency(row['Interval'], row['Interval Count'])
    )
end