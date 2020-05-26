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
