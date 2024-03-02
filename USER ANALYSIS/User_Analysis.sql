#User_Analysis:
Q1) Breakdown of unique users, unique cookies, and total interactions recorded.
Query:
select count(distinct u.user_id) as unique_users,
count(distinct u.cookie_id) as unique_cookies,
count(*) as total_interactions
from users u
join events e on e.cookie_id = u.cookie_id
..................................................................................................................................................
Q2) Analyse the user behavior of visiting the pages, also which page he is visiting the most.
Query:
select *
from ( select u.user_id, p.page_name, count(*) as count_of_visits,
row_number () over(partition by user_id order by count(*) desc) as row_no
from events as e
right join users as u on u.cookie_id = e.cookie_id
join page_hierarchy as p on p.page_id = e.page_id
where p.product_id is not null
group by 1, 2
)as s
where s.row_no = 1
.....................................................................................................................................................
Q3) User engagement variation as unique users, visit counts, and total events recorded each month.
Query:
select date_format(event_time, "%Y-%m") as date,
count(distinct u.user_id) as unique_users,
count(distinct u.cookie_id) as unique_cookies,
count(distinct visit_id) as visit_count,
count(*) as event_count
from events e
join users u on e.cookie_id = u.cookie_id
group by date order by date
................................................................................................................................................
Q4) Calculating the session count and total events triggered by each user.
Query:
select u.user_id, count(distinct e.visit_id) as session_count,
count(*) as total_events_triggered,
round (count(*)/count(distinct e.visit_id),2)as avg_events_per_session
from users u
join events e on u.cookie_id = e.cookie_id
group by u.user_id						
...............................................................................................................................................
Q5) How many cookies does each user have on average.
Query:
select avg(cookie_count)				
from (select user_id, count(cookie_id) as cookie_count				
	from users				
	group by user_id				
)as sm
............................................................................................................................................
Q6) What is the average time spent on the website per user session.
Query:
select user_id, round(avg(session_duration_seconds)/60,2) as avg_session_duration_in_minutes
from (select u.user_id,visit_id,
    max(event_time) - min(event_time) as session_duration_seconds
    from events e
    join users u on e.cookie_id = u.cookie_id
    group by 1,2
) as session_durations group by 1 
.............................................................................................................................................
Q7)  which users made purchases , what are their respective purchase counts.
Query:
select distinct u.user_id, count(*)as purchase
from users u
join events e on u.cookie_id = e.cookie_id
join event_identifier ei on e.event_type = ei.event_type
where ei.event_name = "purchase"
group by user_id 
order by 2 desc
.................................................................................................................................................
Q8) Identify users with checkout but never make a purchase.
Query:
select user_id as userid_which_checkout_but_not_purchase 
from (select u.user_id,
    max(case when ei.event_name= "Page View"and p.page_name = "Checkout"then 1 else 0 end)as checkout,
    max(case when ei.event_name= "Purchase" then 1 else 0 end) as purchase
from users u
join events e on  u.cookie_id = e.cookie_id
join event_identifier ei on ei.event_type= e.event_type
join page_hierarchy p on e.page_id = p.page_id
group by 1
having checkout = 1 and purchase= 0)as s
.............................................................................................................................................................
Q9) Distribution of time intervals between consecutive events for each user.
Query:
with event_intervals as (
select u.user_id, e.event_time,
timestampdiff(hour,lag(e.event_time) over(partition by u.user_id order by e.event_time), e.event_time) as time_interval
from events e
join users u on e.cookie_id = u.cookie_id)
select user_id, round(avg(time_interval),2) as avg_time_between_events_in_hours
from event_intervals group by user_id
....................................................................................................................................................................
Q10) How many users have added items to their cart but have not completed a purchase, and what is the frequency of their visits.
Query:
select u.user_id,count(*)as visit_count, 
count(distinct e.cookie_id) as abandoned_checkouts_count
from events e
join users u on u.cookie_id=e.cookie_id
join event_identifier ei on e.event_type=ei.event_type
where ei.event_name = "Add to Cart"
and u.cookie_id not in(
          select e.cookie_id from events e 
          join event_identifier ei on e.event_type=ei.event_type
          where ei.event_name = "Purchase")
group by u.user_id
 ....................................................................................................................................................................
Q11) user engagement and interaction pattern & how do users respond to different types of events.
Query:
select u.user_id, count(e.event_type) as total_impressions,
sum(case when e.event_type = 1 then 1 else 0 end) as page_view,
sum(case when e.event_type = 2 then 1 else 0 end) as cart_add,
sum(case when e.event_type = 3 then 1 else 0 end) as purchases,
sum(case when e.event_type = 4 then 1 else 0 end) as ad_impression,
sum(case when e.event_type = 5 then 1 else 0 end) as ad_click
from users u
join events e on u.cookie_id = e.cookie_id
group by 1
......................................................................................................................................................................
Q12)What are the most common sequences of events performed by users.
Query:
select event_sequence, count(*) as sequence_count 
from (select u.user_id,
	group_concat(distinct ei.event_name order by e.event_time separator ' >> ')as event_sequence
     from events e
     join users u on u.cookie_id = e.cookie_id
     join event_identifier ei on ei.event_type = e.event_type
     group by 1) as sa 
group by 1 order by 2 desc
........................................................................................................................................................................
Q13) Determine the most common user journey from the Home Page to the Purchase Confirmation page.
Query:
select event_sequence, count(*) as sequence_count 
from (select u.user_id,
	group_concat(distinct ei.event_name order by e.event_time separator ' >> ')as event_sequence
     from events e
     join users u on u.cookie_id = e.cookie_id
     join event_identifier ei on ei.event_type = e.event_type
     group by 1) as sa 
     where event_sequence like "%Purchase"
group by 1 order by 2 desc
.....................................................................................................................................................................
Q14) Average rates of page views to cart additions, cart additions to purchases, page views to purchases, and cart additions to abandoned actions across all pages.
Query:
with purchases as(select p.page_name,
    sum(case when e.event_type = 2 then 1 else 0 end)as purchased
    from page_hierarchy as p  join events e on e.page_id = p.page_id
   where exists(select visit_id from events where event_type=3 and e.visit_id=visit_id group by 1)
	group by 1),
rate as(select p.page_name, sum(case when e.event_type=1 then 1 else 0 end)as page_views,				
	sum(case when e.event_type = 2 then 1 else 0 end) as cart_adds
	from  events e join page_hierarchy p on e.page_id=p.page_id
	group by 1),
abandoned as (select p.page_name, count(*) as abandoned
    from page_hierarchy p  join events e on e.page_id = p.page_id 
  where e.event_type=2 and not exists(select visit_id from events where event_type=3 and e.visit_id=visit_id)
    group by 1 )
select round(avg(r.cart_adds/r.page_views)*100,2)as pageview_to_cartadd_rate, 
round(avg(p.purchased / r.cart_adds)*100 ,2)  as cartadd_to_purchase_rate,
round(avg(p.purchased /r.page_views) *100,2) as pageview_to_purchase_rate,
round(avg(a.abandoned /r.cart_adds) *100,2)  as cartadd_to_abandoned_rate
from Rate r  join purchases p on r.page_name = p.page_name
join abandoned a on a.page_name = p.page_name 
..........................................................................................................................................................................