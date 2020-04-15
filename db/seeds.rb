# Create a main sample user.
User.create!(name:  "Example User",
             email: "example@railstutorial.org",
             password:              "foobar",
             password_confirmation: "foobar",
             admin:     true,
             activated: true,
             activated_at: Time.zone.now)

# Generate a bunch of additional users.
99.times do |n|
  name  = Faker::Name.name
  email = "example-#{n+1}@railstutorial.org"
  password = "password"
  User.create!(name:  name,
              email: email,
              password:              password,
              password_confirmation: password,
              activated: true,
              activated_at: Time.zone.now)
end

10.times do |n|
  make = Faker::Name.name
  5.times do |m|
    model = Faker::Name.name
    5.times do |o|
    year = (2010 + o)
      Vehicle.create(make: make,
                      model: model,
                      year: year,
                      driver_front: 20,
                      passenger_front: 21,
                      rear: 10)
    end
  end
end