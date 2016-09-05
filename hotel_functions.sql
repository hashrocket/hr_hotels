-- what is the occupancy percentage across the entire hotel chain on a given day.
CREATE or REPLACE FUNCTION chainwide_occupancy(date)
RETURNS Float AS $$
DECLARE occupancy_percentage Float;
BEGIN

  -- its a bad practice to create a materialized view without a way to call 'refresh materialized view'
  create materialized view if not exists room_count as select count(*) as c from rooms;

  -- If there is no data then let the developer know
  assert (select c from room_count) > 0, 'This hotel system has no rooms';

  select (count(*)::float / (select c from room_count)) * 100 into occupancy_percentage from reservations where days @> $1;

  RETURN occupancy_percentage;
END;
$$  LANGUAGE plpgsql;

CREATE or REPLACE FUNCTION stay_days(date, date)
RETURNS table(dow int) AS $$
BEGIN
  return query select date_part('dow', a.x)::integer as dow from generate_series($1, $2, '1 day') as a(x);
END;
$$  LANGUAGE plpgsql;

CREATE or REPLACE FUNCTION create_reservations(room_id int, start_date date, end_date date)
RETURNS VOID AS $$
DECLARE
  next_date date;
  rest_days int;
  stay_days int;
  stay_start_date date;
  stay_end_date date;
  stay_range daterange;
  reservation_hotel_id int;
  reservation_section_id int;
  customer_id int;
BEGIN
  next_date := start_date;

  WHILE (next_date < end_date)
  LOOP
      rest_days := ceil(random() * 3) + ceil(random() * 3) + ceil(random() * 3);
      stay_days := ceil(random() * 2) + ceil(random() * 2) + ceil(random() * 2);
      stay_start_date := next_date + (rest_days || ' days')::interval;
      stay_end_date := stay_start_date + (stay_days || ' days')::interval;
      next_date := stay_end_date;
      stay_range := daterange(stay_start_date, stay_end_date);

      select hotel_id into reservation_hotel_id from rooms where id = room_id;
      select section_id into reservation_section_id from rooms where id = room_id;

      customer_id := ceil(random() * 1000);

      IF ( stay_end_date < end_date) THEN
        insert into reservations(hotel_id, section_id, room_id, days, customer_id) values
        (reservation_hotel_id, reservation_section_id, room_id, stay_range, customer_id);
      END IF;
  END LOOP;
END;
$$  LANGUAGE plpgsql;

CREATE or REPLACE FUNCTION create_rooms(hotel_id int, start_date date, end_date date)
RETURNS VOID AS $$
DECLARE
  next_date date;
  rest_days int;
  stay_days int;
  stay_start_date date;
  stay_end_date date;
  stay_range daterange;
  reservation_hotel_id int;
  reservation_section_id int;
  customer_id int;
BEGIN
  next_date := start_date;

  WHILE (next_date < end_date)
  LOOP
      rest_days := ceil(random() * 3) + ceil(random() * 3) + ceil(random() * 3);
      stay_days := ceil(random() * 2) + ceil(random() * 2) + ceil(random() * 2);
      stay_start_date := next_date + (rest_days || ' days')::interval;
      stay_end_date := stay_start_date + (stay_days || ' days')::interval;
      next_date := stay_end_date;
      stay_range := daterange(stay_start_date, stay_end_date);

      select hotel_id into reservation_hotel_id from rooms where id = room_id;
      select section_id into reservation_section_id from rooms where id = room_id;

      customer_id := ceil(random() * 1000);

      IF ( stay_end_date < end_date) THEN
        insert into reservations(hotel_id, section_id, room_id, days, customer_id) values
        (reservation_hotel_id, reservation_section_id, room_id, stay_range, customer_id);
      END IF;
  END LOOP;
END;
$$  LANGUAGE plpgsql;
