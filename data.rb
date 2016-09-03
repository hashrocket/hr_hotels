#!/usr/bin/ruby
# frozen_string_literal: true

require 'bundler'

Bundler.require

require 'sequel/extensions/pg_range'

DB = Sequel.postgres host: 'localhost', database: 'hr_hotels'
NUMBER_OF_ROOMS = 20
ROOM_NUMBER_FORMAT = "%0.#{NUMBER_OF_ROOMS.to_s.size}d"
CUSTOMER_SIZE = 1000

srand(1234) # seed the global random instance used by FFaker
RANDOM = Random.new(1234) #seed our own random instance

DB.run('truncate bedding_types, customers, hotels restart identity cascade;')

BEDDING_TYPES = [
  "No Bed",
  "1 Full",
  "1 Double",
  "2 Double",
  "1 Twin",
  "2 Twins",
  "1 Queen",
  "2 Queen",
  "1 King",
  "2 Kings",
  "3 Kings",
  "Murphy",
  "Sofa Bed"
].freeze

CITIES = [
'New York City, New York',
'Los Angeles, California',
'Chicago, Illinois',
'Houston, Texas',
'Philadelphia, Pennsylvania',
'Phoenix, Arizona',
'San Antonio, Texas',
'San Diego, California',
'Dallas, Texas',
'San Jose, California',
'Austin, Texas',
'Jacksonville, Florida',
'Indianapolis, Indiana',
'San Francisco, California',
'Columbus, Ohio',
'Fort Worth, Texas',
'Charlotte, North Carolina',
'Detroit, Michigan',
'El Paso, Texas',
'Memphis, Tennessee',
'Boston, Massachusetts',
'Seattle, Washington',
'Denver, Colorado',
'Nashville-Davidson, Tennessee',
'Baltimore, Maryland',
'Louisville/Jefferson, Kentucky',
'Portland, Oregon',
'Oklahoma , Oklahoma',
'Milwaukee, Wisconsin',
'Las Vegas, Nevada',
'Albuquerque, New Mexico',
'Tucson, Arizona',
'Fresno, California',
'Sacramento, California',
'Long Beach, California',
'Kansas , Missouri',
'Mesa, Arizona',
'Virginia Beach, Virginia',
'Atlanta, Georgia',
'Colorado Springs, Colorado',
'Raleigh, North Carolina',
'Omaha, Nebraska',
'Miami, Florida',
'Oakland, California',
'Tulsa, Oklahoma',
'Minneapolis, Minnesota',
'Cleveland, Ohio',
'Wichita, Kansas',
'Arlington, Texas',
'New Orleans, Louisiana',
'Bakersfield, California',
'Tampa, Florida',
'Honolulu, Hawaii',
'Anaheim, California',
'Aurora, Colorado',
'Santa Ana, California',
'St. Louis, Missouri',
'Riverside, California',
'Corpus Christi, Texas',
'Pittsburgh, Pennsylvania',
'Lexington-Fayette, Kentucky',
'Anchorage municipality, Alaska',
'Stockton, California',
'Cincinnati, Ohio',
'St. Paul, Minnesota',
'Toledo, Ohio',
'Newark, New Jersey',
'Greensboro, North Carolina',
'Plano, Texas',
'Henderson, Nevada',
'Lincoln, Nebraska',
'Buffalo, New York',
'Fort Wayne, Indiana',
'Jersey , New Jersey',
'Chula Vista, California',
'Orlando, Florida',
'St. Petersburg, Florida',
'Norfolk, Virginia',
'Chandler, Arizona',
'Laredo, Texas',
'Madison, Wisconsin',
'Durham, North Carolina',
'Lubbock, Texas',
'Winston-Salem, North Carolina',
'Garland, Texas',
'Glendale, Arizona',
'Hialeah, Florida',
'Reno, Nevada',
'Irvine, California',
'Chesapeake, Virginia',
'Irving, Texas',
'Scottsdale, Arizona',
'North Las Vegas, Nevada',
'Fremont, California',
'San Bernardino, California',
'Boise, Idaho',
'Birmingham, Alabama',
'Dayton, Ohio',
'Akron, Ohio',
'Youngstown, Ohio'
]

STATE_ABBRS = {
  "Alaska" => "AK",
  "Alabama" => "AL",
  "Arkansas" => "AR",
  "American Samoa" => "AS",
  "Arizona" => "AZ",
  "California" => "CA",
  "Colorado" => "CO",
  "Connecticut" => "CT",
  "District of Columbia" => "DC",
  "Delaware" => "DE",
  "Florida" => "FL",
  "Georgia" => "GA",
  "Guam" => "GU",
  "Hawaii" => "HI",
  "Iowa" => "IA",
  "Idaho" => "ID",
  "Illinois" => "IL",
  "Indiana" => "IN",
  "Kansas" => "KS",
  "Kentucky" => "KY",
  "Louisiana" => "LA",
  "Massachusetts" => "MA",
  "Maryland" => "MD",
  "Maine" => "ME",
  "Michigan" => "MI",
  "Minnesota" => "MN",
  "Missouri" => "MO",
  "Mississippi" => "MS",
  "Montana" => "MT",
  "North Carolina" => "NC",
  "North Dakota" => "ND",
  "Nebraska" => "NE",
  "New Hampshire" => "NH",
  "New Jersey" => "NJ",
  "New Mexico" => "NM",
  "Nevada" => "NV",
  "New York" => "NY",
  "Ohio" => "OH",
  "Oklahoma" => "OK",
  "Oregon" => "OR",
  "Pennsylvania" => "PA",
  "Puerto Rico" => "PR",
  "Rhode Island" => "RI",
  "South Carolina" => "SC",
  "South Dakota" => "SD",
  "Tennessee" => "TN",
  "Texas" => "TX",
  "Utah" => "UT",
  "Virginia" => "VA",
  "Virgin Islands" => "VI",
  "Vermont" => "VT",
  "Washington" => "WA",
  "Wisconsin" => "WI",
  "West Virginia" => "WV",
  "Wyoming" => "WY"
}

require 'faraday'
require 'faraday_middleware'

CONN = Faraday.new(url: 'http://maps.googleapis.com') do |faraday|
  faraday.adapter Faraday.default_adapter
  faraday.response :json
end

def get_address_extras(address, city, state)
  response = CONN.get('/maps/api/geocode/json', address: "#{address},#{city},#{state}")
  location = response.body['results'][0]['geometry']['location']
  postal_code = response.body['results'][0]['address_components'].find {|group| group['types'] == ['postal_code']}['short_name']
  return location, postal_code
end

def create_hotel(index)
  hotels = DB[:hotels]
  city = CITIES[index].split(?,)[0]
  state = STATE_ABBRS[CITIES[index].split(?,)[1].strip]
  address = '10 Main st.'

  location, postal_code = get_address_extras(address, city, state)

  lat = location["lat"]
  lng = location["lng"]

  id = DB["insert into hotels (address1, city, state, zipcode, coordinates) values ('#{address}', '#{city}', '#{state}', '#{postal_code}', ST_SetSRID(ST_MakePoint(#{lat},#{lng}), 4326)) returning id;"]

  return id[:id][:id]
end

def create_section(hotel_id:, floor:, name:)
  sections = DB[:sections].returning(:id)
  sections.insert hotel_id: hotel_id, name: "Floor #{floor}", floor: floor
end

def create_room(hotel_id:, section_id:, name:)
  rooms = DB[:rooms].returning(:id)
  rooms.insert hotel_id: hotel_id, name: "Room #{name}", section_id: section_id, bedding_type: BEDDING_TYPES.sample
end

def create_reservation(hotel_id:, section_id:, room_id:, days:)
  reservations = DB[:reservations]
  reservations.insert hotel_id: hotel_id, section_id: section_id, room_id: room_id, days: days, customer_id: RANDOM.rand(CUSTOMER_SIZE) + 1
end

def two_day_stay_in_january_2050
  start = Date.new(2050, 1, RANDOM.rand(25) + 5)
  finish = (start + 2)
  Sequel::Postgres::PGRange.new(start, finish)
end

def create_customer(first_name:, last_name:, email:, phone_number:)
  customers = DB[:customers]
  customers.insert first_name: first_name, last_name: last_name, email: email, phone_number: phone_number
end

def create_bedding_price_type(hotel_id:, bedding_type:, applied_period:, monday_price: 10, tuesday_price: 10, wednesday_price: 10, thursday_price: 10, friday_price: 100, saturday_price: 100, sunday_price: 1)
  bedding_type_prices = DB[:bedding_type_prices]
  bedding_type_prices.insert(
    hotel_id: hotel_id,
    bedding_type: bedding_type,
    applied_period: applied_period,
    monday_price: monday_price,
    tuesday_price: tuesday_price,
    wednesday_price: wednesday_price,
    thursday_price: thursday_price,
    friday_price: friday_price,
    saturday_price: saturday_price,
    sunday_price: sunday_price
  )
end

def create_base_bedding_price_type(hotel_id:, bedding_type:, monday_price: 10, tuesday_price: 10, wednesday_price: 10, thursday_price: 10, friday_price: 100, saturday_price: 100, sunday_price: 1)
  bedding_type_prices = DB[:base_bedding_type_prices]
  bedding_type_prices.insert(
    hotel_id: hotel_id,
    bedding_type: bedding_type,
    monday_price: monday_price,
    tuesday_price: tuesday_price,
    wednesday_price: wednesday_price,
    thursday_price: thursday_price,
    friday_price: friday_price,
    saturday_price: saturday_price,
    sunday_price: sunday_price
  )
end

BEDDING_TYPES.each do |bt|
  types = DB[:bedding_types]
  types.insert(name: bt)
end

CUSTOMER_SIZE.times do
  first_name = FFaker::Name.first_name
  last_name = FFaker::Name.last_name
  email = FFaker::Internet.email
  phone_number = FFaker::PhoneNumber.short_phone_number

  create_customer(first_name: first_name, last_name: last_name, email: email, phone_number: phone_number)
end

# TODO: Needs command line output so that the user can be more aware of what this
# script is doing
100.times do |hotel_index|
  hotel_id = create_hotel hotel_index

  5.times do |floor|
    section_id = create_section(hotel_id: hotel_id, floor: floor, name: "Floor #{floor}").dig(0, :id)

    # TODO: batch insert the reservations
    NUMBER_OF_ROOMS.times do |room_number|
      room_id = create_room(hotel_id: hotel_id, section_id: section_id, name: "#{floor}#{sprintf(ROOM_NUMBER_FORMAT, room_number)}").dig(0, :id)
      range = Sequel::Postgres::PGRange.new(Date.new(2050, 1, 1), Date.new(2050, 1, 4))
      create_reservation(hotel_id: hotel_id, section_id: section_id, room_id: room_id, days: range)
      create_reservation(hotel_id: hotel_id, section_id: section_id, room_id: room_id, days: two_day_stay_in_january_2050)
    end
  end

  BEDDING_TYPES.each do |bt|
    start = Date.new(2050,6,1)
    finish = Date.new(2050,9,1)
    weekday_price = 100 * 1.5
    weekend_price = 150 * 1.5
    sunday_price = 50 * 1.5
    create_bedding_price_type(hotel_id: hotel_id, bedding_type: bt, applied_period: Sequel::Postgres::PGRange.new(start, finish),
                                monday_price: weekday_price,
                                tuesday_price: weekday_price,
                                wednesday_price: weekday_price,
                                thursday_price: weekday_price,
                                friday_price: weekend_price,
                                saturday_price: weekend_price,
                                sunday_price: sunday_price
                             )
  end

  BEDDING_TYPES.each do |bt|
    weekday_price = 100
    weekend_price = 150
    sunday_price = 50
    create_base_bedding_price_type(hotel_id: hotel_id, bedding_type: bt,
                                monday_price: weekday_price,
                                tuesday_price: weekday_price,
                                wednesday_price: weekday_price,
                                thursday_price: weekday_price,
                                friday_price: weekend_price,
                                saturday_price: weekend_price,
                                sunday_price: sunday_price
                             )
  end
end
