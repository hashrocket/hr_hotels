#!/usr/bin/ruby

require 'bundler'

Bundler.require

DB = Sequel.postgres host: 'localhost', password: '123', user: 'dev', database: 'hr_hotels'

DB.run('truncate sections restart identity cascade')

def create_hotel
  hotels = DB[:hotels]
  hotels.insert
end

def create_section(hotel_id:, floor:, name:)
  sections = DB[:sections]
  sections.insert hotel_id: hotel_id, name: "Floor #{floor}", floor: floor
end

100.times do
  hotel_id = create_hotel
  5.times do |floor|
    create_section(hotel_id: hotel_id, floor: floor, name: "Floor #{floor}")
  end
end
