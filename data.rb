#!/usr/bin/ruby

require 'bundler'

Bundler.require

require 'sequel/extensions/pg_range'

DB = Sequel.postgres host: 'localhost', password: '123', user: 'dev', database: 'hr_hotels'
NUMBER_OF_ROOMS = 20
ROOM_NUMBER_FORMAT = "%0.#{NUMBER_OF_ROOMS.to_s.size}d"

DB.run('truncate hotels restart identity cascade;')

def create_hotel
  hotels = DB[:hotels]
  hotels.insert
end

def create_section(hotel_id:, floor:, name:)
  sections = DB[:sections].returning(:id)
  sections.insert hotel_id: hotel_id, name: "Floor #{floor}", floor: floor
end

def create_room(hotel_id:, section_id:, name:)
  rooms = DB[:rooms].returning(:id)
  rooms.insert hotel_id: hotel_id, name: "Room #{name}", section_id: section_id
end

def create_reservation(hotel_id:, section_id:, room_id:, days:)
  reservations = DB[:reservations]
  reservations.insert hotel_id: hotel_id, section_id: section_id, room_id: room_id, days: days
end

# TODO: Needs command line output so that the user can be more aware of what this
# script is doing
100.times do
  hotel_id = create_hotel

  5.times do |floor|
    section_id = create_section(hotel_id: hotel_id, floor: floor, name: "Floor #{floor}").dig(0, :id)

    # TODO: batch insert the reservations
    NUMBER_OF_ROOMS.times do |room_number|
      room_id = create_room(hotel_id: hotel_id, section_id: section_id, name: "#{floor}#{sprintf(ROOM_NUMBER_FORMAT, room_number)}").dig(0, :id)
      range = Sequel::Postgres::PGRange.new(Date.new(2050, 1, 1), Date.new(2050, 1, 4))
      create_reservation(hotel_id: hotel_id, section_id: section_id, room_id: room_id, days: range)
    end
  end
end
