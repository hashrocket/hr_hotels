-- DDL for hotels

drop table if exists reservations cascade;
drop table if exists rooms cascade;
drop table if exists bedding_types;
drop table if exists sections;
drop table if exists hotels;
drop table if exists customers;
drop extension if exists btree_gist;

create extension if not exists btree_gist;  -- gist by itself does not include integer equality.  this is necssary for the reservation exclusion constraint.
create extension if not exists citext; -- store and compare text in a case insensitive way, for fields like emails where C@example.com is the same as c@example.com

create table customers (
  id serial primary key,
  first_name varchar not null,
  last_name varchar not null,
  email citext not null unique, -- case insensitive
  phone_number varchar not null
);

create table hotels (
  id serial primary key
);

-- TODO: Describe reasoning for creating sections better
create table sections(
  hotel_id integer references hotels not null,
  id serial,
  name varchar not null,
  prefix varchar not null default '',
  floor integer not null,
  primary key (hotel_id, id)
);

create table bedding_types (
  name varchar primary key
);

create table rooms (
  hotel_id integer not null,
  section_id integer not null,
  id serial,
  name varchar not null,
  bedding_type varchar not null references bedding_types(name),
  foreign key (hotel_id, section_id) references sections,
  primary key (hotel_id, section_id, id)
);

create table reservations (
  id serial primary key,
  customer_id integer not null,
  hotel_id integer not null,
  section_id integer not null,
  room_id integer not null,
  days daterange not null,
  reservation_names varchar[] not null default '{}', -- only certain people can checkin for this reservation
  foreign key (hotel_id, section_id, room_id) references rooms,
  foreign key (customer_id) references customers,
  constraint valid_days check (days <@ daterange('1900-01-01', '2100-01-01')), -- days must be within this range and additionally neither bound can be null
  exclude using gist (room_id with =, days with &&) -- exclude expression from being true between rows.  room_id must be unique for this daterange.
);
