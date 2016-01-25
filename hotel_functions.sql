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
$$  LANGUAGE plpgsql
