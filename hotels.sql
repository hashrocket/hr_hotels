-- DDL for hotels

drop table if exists reservations;
drop table if exists rooms;
drop table if exists sections;
drop table if exists hotels;
drop extension if exists btree_gist;

create extension btree_gist;  -- gist by itself does not include integer equality.  this is necssary for the reservation exclusion constraint.

create table hotels (
  id serial primary key
);

create table sections(
  hotel_id integer references hotels,
  id serial,
  name varchar,
  prefix varchar not null default '',
  floor integer not null,
  primary key (hotel_id, id)
);

create table rooms (
  hotel_id integer,
  section_id integer,
  id serial,
  name varchar,
  foreign key (hotel_id, section_id) references sections,
  primary key (hotel_id, section_id, id)
);

create table reservations (
  id serial primary key,
  hotel_id integer,
  section_id integer,
  room_id integer,
  days daterange,
  foreign key (hotel_id, section_id, room_id) references rooms,
  constraint valid_days check (days <@ daterange('1900-01-01', '2100-01-01')),
  exclude using gist (room_id with =, days with &&) -- exclude expression from being true between rows.  room_id must be unique for this daterange.
);
