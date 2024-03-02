#Product_Analysis:
Q1) Distribution of user interactions across different products,considering user visits, sequences, and cookies for each product.
Query:
select p.product_id, p.page_name as product_name,
count(distinct e.sequence_number)as unique_sequences,
count(distinct u.user_id) as unique_users,
count(distinct e.cookie_id) as unique_cookies,
count(distinct e.visit_id) as unique_visits,
count(*) as total_interactions
from users u
join events e on e.cookie_id = u.cookie_id
join page_hierarchy p on p.page_id = e.page_id
where p.product_id is not null group by 1,2
.............................................................................................................................
Q2)How many Products each category have.
Query:
select product_category, count(*) as total_products,
group_concat(page_name separator ', ') as product_names				
from page_hierarchy						
where product_id is not null						
group by 1					
order by 2 desc		
............................................................................................................................
Q3) What is the analysis of product category performance in terms of page views, cart additions, purchases, abandoned actions.
Query:
with purchases as(select p.product_category ,
    sum(case when e.event_type = 2 then 1 else 0 end)as purchased
    from page_hierarchy as p  join events e on e.page_id = p.page_id
  where exists(select visit_id from events where event_type=3 and e.visit_id=visit_id group by 1)
	group by 1),
rate as(select p.product_category, sum(case when e.event_type=1 then 1 else 0 end)as page_views,				
	sum(case when e.event_type = 2 then 1 else 0 end) as cart_adds
	from  events e join page_hierarchy p on e.page_id=p.page_id
	group by 1),
abandoned as (select p.product_category, count(*) as abandoned
    from page_hierarchy p   join events e on e.page_id = p.page_id
    where  e.event_type = 2
    and not exists (select 1 from events where event_type = 3 and e.visit_id = visit_id)
    group by 1 )
select p.product_category, r.page_views, r.cart_adds, p.purchased, abandoned
from Rate r  join purchases p on r.product_category = p.product_category
join abandoned a on a.product_category = p.product_category
group by 1,2,3,4,5 order by 2 desc
.............................................................................................................................	
Q4)What is the analysis of product performance in terms of page views, cart additions, purchases, abandoned actions.
Query:
with purchases as(select p.product_id, p.page_name ,
    sum(case when e.event_type = 2 then 1 else 0 end)as purchased
    from page_hierarchy as p  join events e on e.page_id = p.page_id
   where exists(select visit_id from events where event_type=3 and e.visit_id=visit_id group by 1)
	group by 1,2),
rate as(select p.page_name, sum(case when e.event_type=1 then 1 else 0 end)as page_views,				
	sum(case when e.event_type = 2 then 1 else 0 end) as cart_adds
	from  events e join page_hierarchy p on e.page_id=p.page_id
	group by 1),
abandoned as (select p.page_name, count(*) as abandoned
    from page_hierarchy p   join events e on e.page_id = p.page_id
    where  e.event_type = 2
    and not exists (select 1 from events where event_type = 3 and e.visit_id = visit_id)
    group by 1 )
select p.product_id,p.page_name as product_name, r.page_views, r.cart_adds, p.purchased, abandoned
from Rate r  join purchases p on r.page_name = p.page_name
join abandoned a on a.page_name = p.page_name
group by 1,2,3,4,5 order by 1	
.............................................................................................................................
Q5)Conversion funnel analysis for user interactions on our platform, and how does it vary across different product pages.
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
select a.page_name as product_name,round(avg(r.cart_adds/r.page_views)*100,2)as pageview_to_cartadd_rate, 
round(avg(p.purchased / r.cart_adds)*100 ,2)  as cartadd_to_purchase_rate,
round(avg(p.purchased /r.page_views) *100,2) as pageview_to_purchase_rate,
round(avg(a.abandoned /r.cart_adds) *100,2)  as cartadd_to_abandoned_rate
from Rate r  join purchases p on r.page_name = p.page_name
join abandoned a on a.page_name = p.page_name group by 1 order by 3 desc
...............................................................................................................................
Q6)Which product was most likely to be abandoned.
Query:
with abandoned as (select ph.product_id,ph.page_name, ph.product_category, 
	count(*) as abandoned from page_hierarchy ph
    join events e on e.page_id = ph.page_id
    where  e.event_type = 2
    and not exists (select visit_id from events where event_type = 3 and e.visit_id = visit_id)
    group by 1,2,3 ),
cp as(select  ph.product_id,sum(case when e.event_type = 2 then 1 else 0 end)as cart_add
from events e
join page_hierarchy ph on ph.page_id = e.page_id
where ph.product_id is not null group by 1
)
select a.product_id, a.page_name as product_name, a.product_category, 
(a.abandoned/cp.cart_add)*100 as cartadd_to_abandaned_rate
from cp  join abandoned a on a.product_id = cp.product_id  
order by 4 desc limit 1
...............................................................................................................................
Q7)Which product had the highest count of purchases each month.
Query:
select * from(select 
    month, product_name, product_category, purchased_count,
    row_number() over(partition by month order by purchased_count desc) as row_num
from (select date_format(e.event_time,"%Y-%m")as month, ph.page_name as product_name,
      ph.product_category, sum(case when e.event_type = 2 then 1 else 0 end) as purchased_count
    from page_hierarchy ph 
    join events e on e.page_id = ph.page_id
    where ph.product_id is not null
    and exists(select 1 from events where event_type = 3 and e.visit_id=visit_id group by visit_id)
    group by 1,2,3
)as s 
)as m where m.row_num <= 1
...............................................................................................................................
Q8)Least & Most viewed product.
Query:
select * from
       (select ph.page_name as product_name, ph.product_category,
       count(*)as total_views,rank() over(order by count(*))as Most_and_Least_Recomended
       from events e			
       left join page_hierarchy ph on ph.page_id = e.page_id			
       where ph.product_category is not null			
       group by 1,2 order by 3 desc
       )as s 
where s.Most_and_Least_Recomended=1  or s.Most_and_Least_Recomended=9 
............................................................................................................................
Q9)Average Time Spent on Each Product page.
Query:
select product_id,page_name,
round(avg(timestampdiff(minute, event_time, next_event_time)),2)as avg_time_spent_minute
from(select 
    e.page_id,e.event_time,
	lead(e.event_time) over (partition by e.page_id order by e.event_time)as next_event_time
	from events e)as time_spent 
join page_hierarchy p on time_spent.page_id = p.page_id where p.product_id is not null
group by product_id,page_name
............................................................................................................................
Q10)Analyzing Patterns in Product Views Impacting Purchases.
Query:
select p.product_category,
       hour(e.event_time) as hour_of_day, count(*) as page_views,
       sum(case when e2.event_type = 3 then 1 else 0 end)as purchases
from page_hierarchy p
left join events e on p.page_id = e.page_id
left join events e2 on e.visit_id = e2.visit_id and e2.event_type = 3 
where e.event_type = 1 and product_id is not null
group by 1,2 order by 1
................................................................................................................................
Q11)How does the monthly user engagement vary across different product pages on our website.
Query:
select ph.product_id, ph.page_name,
date_format(e.event_time,"%Y-%m")as month, 
count(distinct e.visit_id)as unique_visits, count(*) as total_events
from events e
join page_hierarchy ph on e.page_id = ph.page_id where product_id is not null
group by 1,2,3 order by 3 
...............................................................................................................................
Q12) Analyze common sequences of products added to the cart.
Query:
select first_product, next_product, count(*) as sequence_count  
from (select ph.page_name as first_product,
    lead(ph.page_name) over(partition by e.visit_id order by e.sequence_number)as next_product
    from events e
    join page_hierarchy ph on e.page_id = ph.page_id
    join event_identifier ei on e.event_type = ei.event_type
    where ei.event_name = 'Add to Cart'
)as sa
where next_product is not null
group by first_product, next_product
order by sequence_count desc
...............................................................................................................................
Q13) What are the sequences of products added to the cart during each user visit, along with the visit ID & user ID.
Query:
select * from 
     ( select e.visit_id, u.user_id, count(*) as product_count,
    group_concat(case when e.event_type = 2 then ph.page_name else null end
	   order by e.sequence_number separator' >> ') as cart_sequence
    from events e
    left join page_hierarchy ph on e.page_id = ph.page_id
    join users u on e.cookie_id = u.cookie_id
    where e.event_type = 2 
    group by e.visit_id,  u.user_id
) as s
...............................................................................................................................