
-- occupancy uses a function call to compute occupancy percentage.  The function has an optimization to read the room_count from a materialized view, which takes 7 seconds of the total time, but this isn't enough.
drop view if exists occupancy;
create view occupancy as
select s.a::date as day, chainwide_occupancy(s.a::date) as occupancy_percentage from generate_series('2050-1-1'::date, '2059-12-31'::date, '1 day') as s(a);

-- fast occupancy joins on the range inclusion expression (a @> b) and is optimized because postgres engine knows to run (select count(*) from rooms) only once
drop view if exists fast_occupancy;
create view fast_occupancy as
select s.a, count(days)::float / (select count(*) from rooms) * 100 from generate_series('2050-1-1'::date, '2059-12-31'::date, '1 day') as s(a) left join reservations on reservations.days @> s.a::date group by s.a order by s.a;

drop view if exists pivoted_prices;
create view pivoted_prices as
select generate_subscripts(ARRAY[1,2,3,4,5,6,7],1) - 1 as day, unnest(ARRAY[monday_price, tuesday_price, wednesday_price, thursday_price, friday_price, saturday_price, sunday_price]) as day_price, hotel_id, bedding_type from base_bedding_type_prices;
