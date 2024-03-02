#Campaign_Analysis
Q1) What is the performance analysis of campaigns in terms of page views, cart additions, purchases, and abandoned actions.
Query:
with purchases as(select ci.campaign_name, sum(case when e.event_type = 2 then 1 else 0 end)as purchased
    from page_hierarchy as ph
    join campaign_identifier ci on ph.product_id = ci.product_id
    join events e on e.page_id = ph.page_id
    where exists(select visit_id from events where event_type = 3 and e.visit_id = visit_id group by 1)
	group by 1),
rate as(select ci.campaign_name, sum(case when e.event_type = 1 then 1 else 0 end)as page_views,				
	sum(case when e.event_type = 2 then 1 else 0 end) as cart_adds
	from events e 							
    join page_hierarchy p on e.page_id=p.page_id
	join campaign_identifier ci on p.product_id = ci.product_id							
	group by 1),
abandoned as (select ci.campaign_id, ci.campaign_name, count(*) as abandoned
    from page_hierarchy ph join campaign_identifier ci on ph.product_id = ci.product_id
    join events e on e.page_id = ph.page_id
    where  e.event_type = 2
    and not exists (select visit_id from events where event_type = 3 and e.visit_id = visit_id)
    group by 1,2 )
select a.campaign_id, p.campaign_name, r.page_views, r.cart_adds, p.purchased, a.abandoned
from rate r  join purchases p on r.campaign_name = p.campaign_name
join abandoned a on a.campaign_name = p.campaign_name
group by 1,2,3,4 order by 1	
.................................................................................................................................
Q2) conversion rates of  campaigns in terms of page views, cart additions, purchases, and abandoned actions.
Query:
with purchases as(select ci.campaign_name,sum(case when e.event_type = 2 then 1 else 0 end)as purchased
     from page_hierarchy as ph
     join campaign_identifier ci on ph.product_id = ci.product_id
     join events e on e.page_id = ph.page_id
     where exists(select visit_id from events where event_type = 3 and e.visit_id = visit_id group by 1)
	 group by 1),
rate as(select ci.campaign_name, sum(case when e.event_type = 1 then 1 else 0 end)as page_views,				
	 sum(case when e.event_type = 2 then 1 else 0 end) as cart_adds  from  events e 							
     join page_hierarchy p on e.page_id=p.page_id
	 join campaign_identifier ci on p.product_id = ci.product_id group by 1),
abandoned as (select ci.campaign_name, count(*) as abandoned
     from page_hierarchy ph join campaign_identifier ci on ph.product_id = ci.product_id
     join events e on e.page_id = ph.page_id where  e.event_type = 2 
     and not exists (select  1 from events where event_type = 3 and e.visit_id = visit_id) 
     group by 1 )
select a.campaign_name, (r.cart_adds/r.page_views) *100  as page_view_to_cartadd_rate, 
(p.purchased/ r.cart_adds) *100  as cart_add_to_purchase_rate,
(p.purchased/r.page_views) *100  as page_view_to_purchase_rate,
(a.abandoned/r.cart_adds) *100  as cartadd_to_abandoned_rate
from rate r  join purchases p on r.campaign_name = p.campaign_name
join abandoned a on a.campaign_name = p.campaign_name	
...............................................................................................................................
Q3) What is the breakdown of unique users, unique visitors, and total visits for each campaign.
Query:
select c.campaign_id, c.campaign_name,count(distinct u.user_id) as unique_users, 
count(distinct e.cookie_id) as unique_cookies,
count(distinct e.visit_id) as unique_visits,
count(*) as total_visits
from events as e
join users u on e.cookie_id = u.cookie_id
join page_hierarchy p on e.page_id = p.page_id
join campaign_identifier as c on p.product_id = c.product_id												
group by 1,2
.............................................................................................................................
Q4)	Distribution of products across different campaigns and number of associated products.
Query:
select ci.campaign_id, ci.campaign_name, ph.product_category,
    count(*) as total_products,
    group_concat(ph.page_name separator ' ,  ') as product_names
from campaign_identifier ci
join page_hierarchy ph on ci.product_id = ph.product_id
group by 1,2,3
..............................................................................................................................
Q5)What is the average time spent  by users on each campaign.
Query:
select campaign_name,
    avg(timestampdiff(hour, a.event_time, a.next_event_time))as avg_time_spent_hour
from (select ci.campaign_name, e.event_time,
	lead(e.event_time) over (partition by u.user_id order by e.event_time)as next_event_time
    from events e
    join users u on e.cookie_id = u.cookie_id
    join page_hierarchy p on e.page_id = p.page_id
	join campaign_identifier ci on p.product_id=ci.product_id
) as a 
group by 1
...............................................................................................................................
Q6) campaign along with their start dates, end dates, and the duration of each campaign in days.
Query:
select distinct campaign_name, 
    date(start_date) as start_date,
    date(end_date) as end_date, 
    datediff(end_date, start_date) as campaign_duration_days
from campaign_identifier 
...............................................................................................................................
Q7) What are the average page views, cart additions, and purchases per visit for each campaign.
Query:
with purchases as (select ci.campaign_name, sum(case when e.event_type = 2 then 1 else 0 end) as purchased
	  from page_hierarchy as ph
	  join campaign_identifier ci on ph.product_id = ci.product_id
	  join events e on e.page_id = ph.page_id
     where exists (select visit_id from events where event_type = 3 and e.visit_id = visit_id group by 1)
      group by 1),
rate as (select ci.campaign_name, ci.campaign_id, count(distinct e.visit_id) as total_visits,
	sum(case when e.event_type = 1 then 1 else 0 end) as page_views,
	sum(case when e.event_type = 2 then 1 else 0 end) as cart_adds
	from events e 							
	join page_hierarchy p on e.page_id = p.page_id
	join campaign_identifier ci on p.product_id = ci.product_id							
    group by 1,2)
select r.campaign_id ,r.campaign_name,  r.page_views / r.total_visits as avg_page_views_per_visit,
    r.cart_adds / r.total_visits as avg_cart_ads_per_visit,
    p.purchased / r.total_visits as avg_purchases_per_visit
from rate r left join purchases p on r.campaign_name = p.campaign_name order by 1
.............................................................................................................................
Q8) What are the overall conversion rates per campaign, calculated as the percentage of visits that resulted in a purchase event, based on the given dataset?
Query:
select campaign_name,
    round(sum(purchased) / count(visit_id) * 100, 2)as overall_conversion_rate_of_purchase
from (select ci.campaign_name, e.visit_id,
        sum(case when e.event_type = 2 then 1 else 0 end) as purchased
      from page_hierarchy as ph
      join campaign_identifier ci on ph.product_id = ci.product_id
      join events e on e.page_id = ph.page_id
      where e.visit_id in (select visit_id from events where event_type = 3)
	  group by 1,2
)as a 
group by 1 order by 1
................................................................................................................................
9) What is the monthly engagement level, measured by unique users and total visits, across various campaigns within the dataset.
Query:
select ci.campaign_name,
       date_format( e.event_time,"%Y-%m") as month,
       count(distinct u.user_id) as users,
       count(*) as total_visits
from campaign_identifier ci
join page_hierarchy ph on ci.product_id = ph.product_id
join events e on e.page_id = ph.page_id
join users u on e.cookie_id=u.cookie_id
group by 1,2  order by 1,2
...............................................................................................................................
10) Compare the purchase rate for visits with ad clicks, visits with impressions but no clicks, and visits with &without impressions.
Query: 
with summary as (select e.visit_id,
        sum(case when e.event_type = 1 then 1 else 0 end) as page_views,
        sum(case when e.event_type = 2 then 1 else 0 end) as cart_adds,
        max(case when e.event_type = 3 then 1 else 0 end) as purchase,
        sum(case when e.event_type = 4 then 1 else 0 end) as ad_impression,
        sum(case when e.event_type = 5 then 1 else 0 end) as ad_click
    from events e group by 1),
uplift_in_purchase_rate as ( 
	    select'with_ad_click' as visit_identifier,
        round(100 * avg(purchase), 2) as uplift_purchase_rate
        from summary where ad_click > 0
union
       select 'with_ad_impression_without_ad_click' as visit_identifier,
        round(100 * avg(purchase), 2) as uplift_purchase_rate
       from summary  where ad_impression > 0 and ad_click = 0
union
        select 'with_ad_impression' as visit_identifier,
        round(100 * avg(purchase), 2) as uplift_purchase_rate
        from summary where ad_impression > 0
union
        select 'without_ad_impression' as visit_identifier,
        round(100 * avg(purchase), 2) as uplift_purchase_rate
        from summary where ad_impression = 0)
select * from uplift_in_purchase_rate
..................................................................................................................................