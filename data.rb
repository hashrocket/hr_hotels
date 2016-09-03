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

BEDDING_TYPES = {
  "No Bed" => -0.5,
  "1 Full" => -0.2,
  "1 Double" => -0.1,
  "2 Double" => 0,
  "1 Twin" => -0.2,
  "2 Twins" => -0.05,
  "1 Queen" => 0.2,
  "2 Queen" => 0.3,
  "1 King" => 0.5,
  "2 Kings" => 1.0,
  "3 Kings" => 1.5,
  "Murphy" => -0.3,
  "Sofa Bed" => -0.2
}.freeze

CITIES = [
 ["New York City", "NY", "10044", "40.7573214", "-73.9552445"],
 ["Los Angeles", "CA", "90012", "34.0520776", "-118.243539"],
 ["Chicago", "IL", "60068", "42.0106255", "-87.8337624"],
 ["Houston", "TX", "77030", "29.6960378", "-95.413679"],
 ["Philadelphia", "PA", "17959", "40.740465", "-76.108836"],
 ["Phoenix", "AZ", "85323", "33.4294283", "-112.3497684"],
 ["San Antonio", "TX", "78148", "29.5357728", "-98.2805999"],
 ["San Diego", "CA", "92173", "32.5525999", "-117.0440642"],
 ["Dallas", "TX", "75226", "32.7856717", "-96.77326"],
 ["San Jose", "CA", "95035", "37.430804", "-121.906629"],
 ["Austin", "TX", "78703", "30.309392", "-97.7599296"],
 ["Jacksonville", "FL", "32202", "30.3263996", "-81.6578901"],
 ["Indianapolis", "IN", "46077", "39.9512661", "-86.2621834"],
 ["San Francisco", "CA", "94105", "37.79267", "-122.3962999"],
 ["Columbus", "OH", "43215", "39.9561108", "-82.9997986"],
 ["Fort Worth", "TX", "76102", "32.7569117", "-97.3328142"],
 ["Charlotte", "NC", "28134", "35.0852351", "-80.88676"],
 ["Detroit", "MI", "48079", "42.906364", "-82.5075248"],
 ["El Paso", "TX", "79901", "31.7597461", "-106.489256"],
 ["Memphis", "TN", "38103", "35.1447121", "-90.0526055"],
 ["Boston", "MA", "02129", "42.3725612", "-71.0619687"],
 ["Seattle", "WA", "98104", "47.60005", "-122.3359447"],
 ["Denver", "CO", "80103", "39.7162672", "-104.2214014"],
 ["Nashville-Davidson", "TN", "37213", "36.1700252", "-86.7727044"],
 ["Baltimore", "MD", "21222", "39.2409945", "-76.5112916"],
 ["Louisville/Jefferson", "KY", "40202", "38.2560556", "-85.751587"],
 ["Portland", "OR", "97214", "45.5137835", "-122.6663235"],
 ["Oklahoma", "OK", "73102", "35.467567", "-97.513029"],
 ["Milwaukee", "WI", "53018", "43.0593953", "-88.4137626"],
 ["Las Vegas", "NV", "89101", "36.1717422", "-115.1463553"],
 ["Albuquerque", "NM", "87002", "34.6616028", "-106.7764428"],
 ["Tucson", "AZ", "85701", "32.2229917", "-110.9754819"],
 ["Fresno", "CA", "93722", "36.7777626", "-119.8553126"],
 ["Sacramento", "CA", "95838", "38.6546348", "-121.473447"],
 ["Long Beach", "CA", "92648", "33.738887", "-118.106623"],
 ["Kansas", "MO", "64152", "39.189086", "-94.684262"],
 ["Mesa", "AZ", "85201", "33.415424", "-111.831961"],
 ["Virginia Beach", "VA", "23601", "37.0290213", "-76.4637178"],
 ["Atlanta", "GA", "30297", "33.6300049", "-84.3847184"],
 ["Colorado Springs", "CO", "80832", "39.121159", "-104.1677499"],
 ["Raleigh", "NC", "27601", "35.7769003", "-78.6389015"],
 ["Omaha", "NE", "68067", "42.1483804", "-96.4856201"],
 ["Miami", "FL", "33023", "26.005428", "-80.2123515"],
 ["Oakland", "CA", "94504", "44.4481008", "-64.4002649"],
 ["Tulsa", "OK", "74103", "36.1554962", "-95.992161"],
 ["Minneapolis", "MN", "55401", "44.9873046", "-93.2596435"],
 ["Cleveland", "OH", "44024", "41.5830212", "-81.2038266"],
 ["Wichita", "KS", "67202", "37.6856917", "-97.3381542"],
 ["Arlington", "TX", "76010", "32.7367822", "-97.1081617"],
 ["New Orleans", "LA", "70130", "29.9497486", "-90.0642621"],
 ["Bakersfield", "CA", "93307", "35.223292", "-118.9144592"],
 ["Tampa", "FL", "33609", "27.940761", "-82.53242"],
 ["Honolulu", "HI", "96818", "21.3502576", "-157.9375658"],
 ["Anaheim", "CA", "92802", "33.810642", "-117.9189748"],
 ["Aurora", "CO", "80016", "39.6020714", "-104.7094797"],
 ["Santa Ana", "CA", "92701", "33.7546429", "-117.8677442"],
 ["St. Louis", "MO", "63070", "38.287389", "-90.399001"],
 ["Riverside", "CA", "92501", "34.0192268", "-117.3625379"],
 ["Corpus Christi", "TX", "78362", "27.8531599", "-97.2189516"],
 ["Pittsburgh", "PA", "15215", "40.5021144", "-79.9197971"],
 ["Lexington-Fayette", "KY", "40361", "38.2136719", "-84.2486732"],
 ["Anchorage municipality", "AK", "99587", "60.9409885", "-149.1699794"],
 ["Stockton", "CA", "94530", "49.5892197", "-99.4527179"],
 ["Cincinnati", "OH", "41018", "39.1338087", "-84.7023189"],
 ["St. Paul", "MN", "55376", "45.2099682", "-93.6645509"],
 ["Toledo", "OH", "43605", "41.6509563", "-83.5261146"],
 ["Newark", "NJ", "07105", "40.7290429", "-74.148374"],
 ["Greensboro", "NC", "27282", "35.9940333", "-79.9358213"],
 ["Plano", "TX", "75035", "33.1522617", "-96.7371284"],
 ["Henderson", "NV", "89015", "36.0304257", "-114.970892"],
 ["Lincoln", "NE", "68434", "40.9068986", "-97.0920452"],
 ["Buffalo", "NY", "14203", "42.8761472", "-78.8773901"],
 ["Fort Wayne", "IN", "46802", "41.0802802", "-85.1398093"],
 ["Jersey", "NJ", "07724", "40.3047551", "-74.0601191"],
 ["Chula Vista", "CA", "92173", "32.5525999", "-117.0440642"],
 ["Orlando", "FL", "34786", "28.5028563", "-81.537921"],
 ["St. Petersburg", "FL", "34601", "28.5546882", "-82.3880854"],
 ["Norfolk", "VA", "23510", "36.8469378", "-76.2940605"],
 ["Chandler", "AZ", "85225", "33.3063097", "-111.8416646"],
 ["Laredo", "TX", "78040", "27.5008211", "-99.5124145"],
 ["Madison", "WI", "53703", "43.0739723", "-89.3830336"],
 ["Durham", "NC", "27701", "35.9909465", "-78.8933085"],
 ["Lubbock", "TX", "79403", "33.7373581", "-101.837178"],
 ["Winston-Salem", "NC", "27101", "36.0947011", "-80.2433915"],
 ["Garland", "TX", "75040", "32.9122385", "-96.631217"],
 ["Glendale", "AZ", "85335", "33.6225261", "-112.3346365"],
 ["Hialeah", "FL", "33014", "25.913153", "-80.3093058"],
 ["Reno", "NV", "89442", "39.6313573", "-119.2808646"],
 ["Irvine", "CA", "92661", "33.6014036", "-117.8996988"],
 ["Chesapeake", "VA", "23701", "36.8154147", "-76.3441484"],
 ["Irving", "TX", "75060", "32.8136561", "-96.9461863"],
 ["Scottsdale", "AZ", "85323", "33.4294283", "-112.3497684"],
 ["North Las Vegas", "NV", "89101", "36.1717422", "-115.1463553"],
 ["Fremont", "CA", "95035", "37.430804", "-121.906629"],
 ["San Bernardino", "CA", "92501", "34.0192268", "-117.3625379"],
 ["Boise", "ID", "83702", "43.6115693", "-116.1954601"],
 ["Birmingham", "AL", "35214", "33.6392228", "-86.9167098"],
 ["Dayton", "OH", "45402", "39.7602496", "-84.191991"],
 ["Akron", "OH", "44311", "41.0715173", "-81.5257022"],
 ["Youngstown", "OH", "44514", "41.022915", "-80.615596"]
]

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
  city, state, postal_code, lat, lng = CITIES[index]
  address = '10 Main st.'

  id = DB["insert into hotels (address1, city, state, zipcode, coordinates) values ('#{address}', '#{city}', '#{state}', '#{postal_code}', ST_SetSRID(ST_MakePoint(#{lat},#{lng}), 4326)) returning id;"]

  return id[:id][:id]
end

def create_section(hotel_id:, floor:, name:)
  sections = DB[:sections].returning(:id)
  sections.insert hotel_id: hotel_id, name: "Floor #{floor}", floor: floor
end

def create_room(hotel_id:, section_id:, name:)
  rooms = DB[:rooms].returning(:id)
  rooms.insert hotel_id: hotel_id, name: "Room #{name}", section_id: section_id, bedding_type: BEDDING_TYPES.keys.sample
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

def progress_bar
  @progress_bar ||= ProgressBar.create(format: '%t - %B> %p%%')
end

def progressify(progress_bar, title, total)
  progress_bar.title = title
  progress_bar.total = total
  yield progress_bar
  progress_bar.reset
end

progressify(progress_bar, 'Bedding Types', BEDDING_TYPES.count) do |progress|
  BEDDING_TYPES.keys.each do |bt|
    progress.increment
    types = DB[:bedding_types]
    types.insert(name: bt)
  end
end

progressify(progress_bar, 'Customers', CUSTOMER_SIZE) do |progress|
  CUSTOMER_SIZE.times do
    progress.increment
    first_name = FFaker::Name.first_name
    last_name = FFaker::Name.last_name
    email = FFaker::Internet.email
    phone_number = FFaker::PhoneNumber.short_phone_number

    create_customer(first_name: first_name, last_name: last_name, email: email, phone_number: phone_number)
  end
end

progressify(progress_bar, 'Hotels', 100) do |progress|
  100.times do |hotel_index|
    progress.increment
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

    hotel_price_adjustor = 1.5

    BEDDING_TYPES.each do |bt, adjustor|
      start = Date.new(2050,6,1)
      finish = Date.new(2050,9,1)

      weekday_price = 100 * hotel_price_adjustor
      weekend_price = 150 * hotel_price_adjustor
      sunday_price = 50 * hotel_price_adjustor

      weekday_price += weekday_price * adjustor
      weekend_price += weekend_price * adjustor
      sunday_price += sunday_price * adjustor

      create_bedding_price_type(hotel_id: hotel_id,
                                bedding_type: bt,
                                applied_period: Sequel::Postgres::PGRange.new(start, finish),
                                monday_price: weekday_price,
                                tuesday_price: weekday_price,
                                wednesday_price: weekday_price,
                                thursday_price: weekday_price,
                                friday_price: weekend_price,
                                saturday_price: weekend_price,
                                sunday_price: sunday_price
                               )
    end

    BEDDING_TYPES.each do |bt, adjustor|
      weekday_price = 100
      weekend_price = 150
      sunday_price = 50

      weekday_price += weekday_price * adjustor
      weekend_price += weekend_price * adjustor
      sunday_price += sunday_price * adjustor

      create_base_bedding_price_type(hotel_id: hotel_id,
                                     bedding_type: bt,
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
end
