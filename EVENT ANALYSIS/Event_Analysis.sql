#Event_Analysis:
Q1) count of unique users, unique cookies, distinct sequences, total visits, and total events.
Query:
select count(distinct e.sequence_number) as distinct_sequences,
count(distinct u.user_id) as distinct_users,
count(distinct u.cookie_id) as distinct_cookies, 
count(distinct e.visit_id) as distinct_visits,
count(*) as total_events
from events e
join users u on e.cookie_id = u.cookie_id
............................................................................................................................
Q2) Counts of distinct sequences, unique users, unique cookies, and total events recorded for each event type.
Query:
select ei.event_type, ei.event_name,
count(distinct e.sequence_number) as distinct_sequences,
count(distinct u.user_id) as distinct_users,
 count(distinct e.cookie_id) as distinct_cookies,
 count(distinct e.visit_id) as distinct_visits,
count(*) as event_count 
from events e join users u on u.cookie_id=e.cookie_id
join event_identifier ei on e.event_type=ei.event_type
group by 1,2
.............................................................................................................................
Q3) Distribution of event counts, unique users, unique cookies, and unique visits across different months.
Query:
select date_format(event_time,"%Y-%m") as month,
count(distinct u.user_id) as distinct_users,
count(distinct e.cookie_id) as distinct_cookies,
count(distinct e.visit_id) as distinct_visits,
count(*) as event_count   
from events e 
join users u on u.cookie_id=e.cookie_id
group by month order by month
...............................................................................................................................
Q4) Percentage of visits which view the checkout page but do not have a purchase event.
Query:
select round((1-s.purchase/s.checkout) *100, 2)as percentage						
from(select 
sum(case when ei.event_name="Page View" and p.page_name="Checkout"then 1 else 0 end)as checkout,						
sum(case when ei.event_name = "Purchase" then 1 else 0 end)as purchase from events e
join event_identifier ei on ei.event_type = e.event_type
join page_hierarchy p on p.page_id = e.page_id
)as s
................................................................................................................................
Q5)What is the percentage of visits which have a purchase event?
select round(100 * sum(purchase) / count(*), 2) as purchase_percentage
from (select e.visit_id,
      sum(case when ei.event_name ="Purchase" then 1 else 0 end) as purchase
	  from events e
      join event_identifier ei on ei.event_type = e.event_type
      group by e.visit_id
) as s
.............................................................................................................................
Q6)Question: Page View, Cart Adds & Purchase counts over months.
Query:
select date_format(e.event_time, '%Y-%m') as month,
    sum(case when ei.event_name = "Page View"   then 1 else 0 end) as page_views,
    sum(case when ei.event_name = "Add to Cart"  then 1 else 0 end) as cart_adds,
    sum(case when ei.event_name = "Purchase"     then 1 else 0 end ) as purchases,
	sum(case when ei.event_name = "Ad Impression" then 1 else 0 end ) as ad_impressions,
	sum(case when ei.event_name = "Ad Click"        then 1 else 0 end ) as ad_clicks
from events e
join event_identifier ei on e.event_type = ei.event_type
group by month order by month
............................................................................................................................
Q7) Average sequence number of events for each event type, and how does it vary across different event names.
Query:
select e.event_type, ei.event_name,
round(avg(e.sequence_number),2)
from events e
join event_identifier ei on ei.event_type= e.event_type
group by 1,2
...............................................................................................................................
Q8) What is the average time gap between consecutive events for each event type recorded in the dataset.
Query:
with event_sequence as (
	select ei.event_name, e.event_time, e.sequence_number,
  lag(sequence_number) over(partition by e.cookie_id order by sequence_number)as prev_sequence_number
    from events e
    join event_identifier ei on e.event_type = ei.event_type
)
select event_name, round(avg(sequence_number - prev_sequence_number), 2) as avg_event_gap
from event_sequence
where prev_sequence_number is not null
group by 1
................................................................................................................................
Q9)What is the impact of ad impressions on user engagement and conversion rates within our dataset.
Query:
with all_events as (select visit_id,
	sum(case when event_type = 1 then 1 else 0 end) as page_views,
    sum(case when event_type = 2 then 1 else 0 end) as cart_adds,
    sum(case when event_type = 3 then 1 else 0 end) as purchase,
    sum(case when event_type = 4 then 1 else 0 end) as ad_impression,
    sum(case when event_type = 5 then 1 else 0 end) as ad_click
    from events  group by 1),
with_ad_impression as ( select 'with_ad_impression' as impression_type,
   round(avg(page_views), 2) as page_views, round(avg(cart_adds), 2) as cart_adds,
    round(avg(purchase), 2) as purchase 
    from all_events  where ad_impression > 0),
without_ad_impression as ( select 'without_ad_impression' as impression_type,
   round(avg(page_views), 2) as page_views, round(avg(cart_adds), 2) as cart_adds,
	round(avg(purchase), 2) as purchase 
    from all_events  where ad_impression = 0 )
select * from with_ad_impression
union all 
select * from without_ad_impression
...............................................................................................................................
Q10) What is the impact of ad clicks on user engagement and conversion rates within our dataset.
Query:
with all_events as (select visit_id,
	sum(case when event_type = 1 then 1 else 0 end) as page_views,
    sum(case when event_type = 2 then 1 else 0 end) as cart_adds,
    sum(case when event_type = 3 then 1 else 0 end) as purchase,
    sum(case when event_type = 4 then 1 else 0 end) as ad_impression,
    sum(case when event_type = 5 then 1 else 0 end) as ad_click
    from events  group by 1),
with_ad_click as ( select 'with_ad_click' as impression_type,
    round(avg(page_views),2) as page_views, round(avg(cart_adds),2)as cart_adds,
    round(avg(purchase),2) as purchase 
    from all_events  where ad_click > 0),
without_ad_click as ( select 'without_ad_click' as impression_type,
    round(avg(page_views),2) as page_views, round(avg(cart_adds),2)as cart_adds,
	round(avg(purchase),2) as purchase 
    from all_events  where ad_click = 0 )
select * from with_ad_click
union all 
select * from without_ad_click
..............................................................................................................................
Q11)Determine the average time spent by users between consecutive events.
Query:
with sequence_of_events as (
select cookie_id, event_time,sequence_number,
lag(sequence_number) over (partition by cookie_id order by sequence_number) 
as prev_sequence_number
from events
)
select avg(sequence_number - prev_sequence_number) as avg_event_gap
from sequence_of_events
where prev_sequence_number is not null
................................................................................................................................