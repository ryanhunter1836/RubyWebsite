require 'csv'

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

CSV.foreach(Rails.root.join('lib', 'seeds', 'sample_wipersizes.csv'), headers: true) do |row|
  Vehicle.create(make: row[0],
                 model: row[1],
                 year: row[2],
                 driver_front: row[3].to_i,
                 passenger_front: row[4].to_i
  )
end

wiperSizes = [12,13,14,16,17,18,19,20,21,22,24,26,28]
quality = [0,1,2]
frequency = [0,1]

wiperSizes.each_with_index do |f, wiperIndex|
  quality.each_with_index do |g, qualityIndex|
    frequency.each_with_index do |h, frequencyIndex|
      StripeProduct.create(stripe_id: 'price_1GrDNNK9cC716JE2Xn39tnIP',
                           price: 2000,
                           size: wiperSizes[wiperIndex],
                           quality: quality[qualityIndex],
                           frequency: frequency[frequencyIndex],            
      )
    end
  end
end