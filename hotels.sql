-- DDL for hotels

drop table if exists reservations cascade;
drop table if exists rooms cascade;
drop table if exists bedding_type_prices;
drop table if exists base_bedding_type_prices;
drop table if exists bedding_types;
drop table if exists sections;
drop table if exists hotels;
drop table if exists customers;
drop extension if exists btree_gist;
drop extension if exists citext;

create extension btree_gist;  -- gist by itself does not include integer equality.  this is necssary for the reservation exclusion constraint.
create extension citext; -- store and compare text in a case insensitive way, for fields like emails where C@example.com is the same as c@example.com
create extension postgis;

create table customers (
  id serial primary key,
  first_name varchar not null,
  last_name varchar not null,
  email citext not null unique, -- case insensitive
  phone_number varchar not null
);

create table hotels (
  id serial primary key,
  address1 varchar not null,
  address2 varchar,
  city varchar not null,
  state varchar not null,
  zipcode varchar not null,
  coordinates geometry(POINT, 4326) not null
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

-- 1/1 - 12/31
-- 3/25 - 4/1
-- 3/24 - 3/25
create table bedding_type_prices (
  hotel_id integer not null,
  bedding_type varchar not null references bedding_types(name),
  applied_period daterange not null,
  monday_price numeric(8,2) not null,
  tuesday_price numeric(8,2) not null,
  wednesday_price numeric(8,2) not null,
  thursday_price numeric(8,2) not null,
  friday_price numeric(8,2) not null,
  saturday_price numeric(8,2) not null,
  sunday_price numeric(8,2) not null,
  primary key (hotel_id, bedding_type, applied_period),
  exclude using gist (hotel_id with =, bedding_type with =, applied_period with &&)
);

create table base_bedding_type_prices (
  hotel_id integer not null,
  bedding_type varchar not null references bedding_types(name),
  monday_price numeric(8,2) not null,
  tuesday_price numeric(8,2) not null,
  wednesday_price numeric(8,2) not null,
  thursday_price numeric(8,2) not null,
  friday_price numeric(8,2) not null,
  saturday_price numeric(8,2) not null,
  sunday_price numeric(8,2) not null,
  primary key (hotel_id, bedding_type)
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
