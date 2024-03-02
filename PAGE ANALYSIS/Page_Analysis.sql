#Page_Analysis:
Q1) Distribution of unique users, cookies, distinct visits & total visits  across different pages.
Query:
select ph.page_id, ph.page_name,count(distinct u.user_id)as unique_users,
count(distinct e.cookie_id)as unique_cookiecount,
count(distinct e.visit_id)as unique_visits,
count(*) as total_events
from events e
join users u on u.cookie_id=e.cookie_id
join page_hierarchy ph  on e.page_id = ph.page_id
group by 1,2 order by 1
......................................................................................................................
Q2) Events distributed across different pages of the website, and what are the event sequences observed on each page.
Query:
select p.page_id, p.page_name, 
count(distinct e.sequence_number)as unique_sequence_count, count(*)as total_sequences,
group_concat(distinct ei.event_name order by e.sequence_number separator', ')as event_sequence
from events e
join users u on u.cookie_id = e.cookie_id
join page_hierarchy p on e.page_id = p.page_id
join event_identifier ei on e.event_type = ei.event_type
group by 1,2
order by 1
.......................................................................................................................
Q3) calculate the average time spent by users between consecutive events on each page.
Query:
select p.page_id,p.page_name, 
round(avg(case when next_event.event_time > e.event_time 
		then timestampdiff(minute, e.event_time, next_event.event_time) 
		else null end),2) as avg_time_spent_minutes
from events e
join page_hierarchy p using (page_id)
join events next_event on e.cookie_id = next_event.cookie_id 
	 and e.sequence_number + 1 = next_event.sequence_number
group by 1,2 order by 1
.........................................................................................................................
Q4)  pages have the highest interaction rates.
Query:
select ph.page_name,
round(count(*)/count(distinct e.visit_id),2) as avg_interaction_rate
from events e
join page_hierarchy ph on e.page_id = ph.page_id
group by ph.page_name
order by avg_interaction_rate desc
..........................................................................................................................
Q5) Which pages have the high entry rates,  How do these entry rates vary across different pages.
Query:
select ph.page_name, count(*) as total_entries,
	count(distinct cookie_id) as total_users,
	round(count(*) / count(distinct cookie_id),2)as entry_rate
from events e
join page_hierarchy ph on e.page_id = ph.page_id
group by 1 
order by 4 desc
.........................................................................................................................
Q6) How does page engagement vary over different time periods.
Query:
select ph.page_id, ph.page_name,
    date_format(e.event_time, '%Y-%m') as month,
    count(*) as total_page_views
from events e
join page_hierarchy ph on e.page_id = ph.page_id
group by 1,2,3
order by 1
...........................................................................................................................
Q7) Level of user engagement with different pages  and how effectively do these pages convert visitors into engaged users.
Query:
select p.page_id,p.page_name, count(distinct u.user_id) as unique_users,
count(*) as total_page_views,
round(count(*) / count(distinct u.user_id) ,2) as conversion_rate
from events e
join users u on u.cookie_id=e.cookie_id
join page_hierarchy p on e.page_id = p.page_id
join event_identifier ei on e.event_type = ei.event_type
where ei.event_name = "Page View" 
group by 1,2
.........................................................................................................................
Q8) What is the conversion rate for adding products to the cart on each page.
Query:
select p.page_name, count(distinct u.user_id) as unique_users,
count(*) as total_cart_adds,
round(count(*) / count(distinct u.user_id) ,2) as conversion_rate
from events e
join users u on u.cookie_id=e.cookie_id
join page_hierarchy p on e.page_id = p.page_id
join event_identifier ei on e.event_type = ei.event_type
where ei.event_name = "Add to Cart" 
group by 1
.........................................................................................................................
Q9) How effective are pages in converting visitors into purchasers, and what is the overall conversion rate for each page?
Query:
select p.page_name, count(distinct u.user_id) as unique_users,
count(*) as total_purchases,
round(count(*) / count(distinct u.user_id) ,2) as conversion_rate
from events e
join users u on u.cookie_id=e.cookie_id
join page_hierarchy p on e.page_id = p.page_id
join event_identifier ei on e.event_type = ei.event_type
where ei.event_name = "Purchase" 
group by 1
.........................................................................................................................
Q10)Which pages have the highest bounce rates.(page views without subsequent product cart adds)
Query:
select page_name, count(*) as total_bounces,
round(count(*) / (select count(*) from events where event_type = 1) *100,2) as bounce_rate
from events 
join page_hierarchy on events.page_id = page_hierarchy.page_id
where not exists(select visit_id from events e2 where e2.event_type =2 and e2.visit_id = events.visit_id)
and event_type = 1
group by 1
order by 2 desc
.........................................................................................................................
Q11)  Determine the average time spent on each page by users.
Query:
select p.page_id, p.page_name, 
round(avg(minute(e.event_time)),2) as avg_time_spent_in_minutes
from events e
join page_hierarchy p on e.page_id = p.page_id
group by 1,2 order by 1
.........................................................................................................................
Q12)  Determine the most visited pages and events performed by users.
Query:
select p.page_id, p.page_name, e.event_type, ei.event_name, 
count(*) as visit_count
from events e
join event_identifier ei on e.event_type = ei.event_type
join page_hierarchy p on e.page_id = p.page_id
group by 1,2,3,4
order by 3 
............................................................................................................................