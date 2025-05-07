select * from [credit_card_transcations ilaps];
--finding min, max transaction date 
select min(transaction_date), max(transaction_date)
from [credit_card_transcations ilaps]					-- 2013-10-04 TO 2015-05-26

--finding different card types available in dataset
select distinct card_type
from [credit_card_transcations ilaps]					-- Silver, Signature, Gold, Platinum

--finding different expense type available
select distinct exp_type
from [credit_card_transcations ilaps]					-- Entertainment, Food, Bills, Fuel, Travel, Grocery

--finding how many cities are present in dataset
select distinct city
from [credit_card_transcations ilaps]					-- 986 diff cities

;
-----------------------------------------------------------------------------------------------------------------------------------------

--Query 1
--write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends
with cte1 AS (
	select city, sum(amount) as total_spend
	from [credit_card_transcations ilaps]
	group by city
)
select top 5 *, round(total_spend/(select sum(amount) from [credit_card_transcations ilaps]) * 100, 1) as percent_contribution from cte1
order by total_spend desc
;

--Q2. write a query to print highest spend month and amount spent in that month for each card type
WITH cte AS (
	select card_type ,DATEPART(MONTH, transaction_date) as transaction_month, DATEPART(YEAR, transaction_date) as transaction_year
		, sum(amount) as total_spend
	from [credit_card_transcations ilaps]
	group by card_type, DATEPART(MONTH, transaction_date), DATEPART(YEAR, transaction_date)
)
select card_type, transaction_month, transaction_year, total_spend
from (select *, RANK() over (partition by card_type order by total_spend desc) as rnk from cte) a
where rnk = 1


--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of  1,000,000 total spends(We should have 4 rows in the o/p one for each card type)

with cte as (
select *,sum(amount) over(partition by card_type order by transaction_date,transaction_id) as total_spend
from [credit_card_transcations ilaps]
)
select * from (select *, rank() over(partition by card_type order by total_spend) as rn  
from cte where total_spend >= 1000000) a where rn=1


-- 4- write a query to find city which had lowest percentage spend for gold card type
with cte as (
select top 1 city,card_type,sum(amount) as amount
,sum(case when card_type='Gold' then amount end) as gold_amount
from [credit_card_transcations ilaps]
group by city,card_type)
select 
city,sum(gold_amount)*1.0/sum(amount) as gold_ratio
from cte
group by city
having count(gold_amount) > 0 and sum(gold_amount)>0
order by gold_ratio;


-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with cte as (
select city,exp_type, sum(amount) as total_amount from [credit_card_transcations ilaps]
group by city,exp_type)
select
city , max(case when rn_asc=1 then exp_type end) as lowest_exp_type
, min(case when rn_desc=1 then exp_type end) as highest_exp_type
from
(select *
,rank() over(partition by city order by total_amount desc) rn_desc
,rank() over(partition by city order by total_amount asc) rn_asc
from cte) A
group by city;


-- 6- write a query to find percentage contribution of spends by females for each expense type
select exp_type,
sum(case when gender='F' then amount else 0 end)*1.0/sum(amount) as percentage_female_contribution
from [credit_card_transcations ilaps]
group by exp_type
order by percentage_female_contribution desc;


-- 7- which card and expense type combination show highest month over month growth in Jan-2014
with cte as (
select card_type,exp_type,datepart(year,transaction_date) yt
,datepart(month,transaction_date) mt,sum(amount) as total_spend
from [credit_card_transcations ilaps]
group by card_type,exp_type,datepart(year,transaction_date),datepart(month,transaction_date)
)
select  top 1 *, (total_spend-prev_mont_spend) as mom_growth
from (
select *
,lag(total_spend,1) over(partition by card_type,exp_type order by yt,mt) as prev_mont_spend
from cte) A
where prev_mont_spend is not null and yt=2014 and mt=1
order by mom_growth desc;


-- 8- during weekends which city has highest total spend to total no of transcations ratio 
select top 1 city , sum(amount)*1.0/count(1) as ratio
from [credit_card_transcations ilaps]
where datepart(weekday,transaction_date) in (1,7)
group by city
order by ratio desc;


-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as (
	select *
	,row_number() over(partition by city order by transaction_date,transaction_id) as rn
	from [credit_card_transcations ilaps]
)
select top 1 city,datediff(day,min(transaction_date),max(transaction_date)) as date_diff1
from cte
where rn=1 or rn=500
group by city
having count(1)=2
order by date_diff1 
