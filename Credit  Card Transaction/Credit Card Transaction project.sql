select exp_type
from credit_card_transcations
group by exp_type
order by transaction_date


select distinct card_type 
from credit_card_transcations

select min(transaction_date), max(transaction_date) 
from credit_card_transcations;


---1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends.
select top 5 city, highest_spends, round((highest_spends/total_spend)*100, 2) as perc 
from 
(
select city, sum(amount) as highest_spends, (
select sum(amount) from credit_card_transcations) as total_spend
from credit_card_transcations 
group by city ) m
order by highest_spends desc;




---2- write a query to print highest spend month and amount spent in that month for each card type
with cte as (
	select card_type,
	datepart(year,transaction_date) as yo, 
	datename(MONTH,transaction_date) as mo,
	sum(amount) as monthly_expense
from credit_card_transcations
group by 
	card_type,
	datepart(year,transaction_date), 
	datename(MONTH,transaction_date))
select * from
	(select *, rank() over(partition by card_type order by monthly_expense desc) as rn
	from cte) A
where rn=1;




---/3- write a query to print the transaction details(all columns from the table) for each card type 
--when it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
select * from(
		select *,rank() over(partition by card_type order by cum_sum asc) as rn
from (
	select *,sum(amount) over(partition by card_type order by transaction_date,transaction_id) as cum_sum
	from credit_card_transcations
----order by card_type,transaction_date, transaction_id
 ) A
where cum_sum>=1000000
 ) B
where rn=1




---4- write a query to find city which had lowest percentage spend for gold card type
select city,sum(amount) as total_spend 
, sum(case when card_type='Gold' then amount else 0  end) as gold_spend
, sum(case when card_type='Gold' then amount else 0  end)*1.0/ sum(amount)*100 as gold_contribution
from credit_card_transcations
group by city
having sum(case when card_type='Gold' then amount else 0  end)>0
order by gold_contribution




---5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with cte as (
    select city, exp_type, SUM(amount) AS total_spend
    from credit_card_transcations
   group by city, exp_type
),
cte2 as (
    select 
        city,
        exp_type,
        total_spend,
        rank() over (partition by city order by total_spend desc) as rn_high,
        RANK() over (partition by city order by total_spend desc) as rn_low
    from cte
)
select city,
    max(case when rn_high = 1 then exp_type end) as highest_expense_type,
    max(case when rn_high = 1 then total_spend end) as highest_total_spend,
    max(case when rn_high = 1 then exp_type end) as lowest_expense_type
    max(case when rn_low = 1 then total_spend end) as lowest_total_spend
from cte2
group by city;




---6- write a query to find percentage contribution of spends by females for each expense type
select exp_type,SUM(amount) as total_spend 
	, SUM(case when gender='F' then amount else 0  end) as female_spend
	, SUM(case when gender='F' then amount else 0  end)*1.0/ SUM(amount)*100 as female_contribution
from credit_card_transcations
group by exp_type
order by female_contribution




---7- which card and expense type combination saw highest month over month growth in Jan-2014
with m as 
 (
	 select card_type, exp_type, datepart(year, transaction_date) as year,
	 datepart(month, transaction_date) as current_month, sum(amount) as current_spend
	 from credit_card_transcations 
	 group by card_type, exp_type, datepart(year, transaction_date), datepart(month, transaction_date)
 ), abc as 
 (
	 select *, lag(current_spend, 1) over(partition by card_type,exp_type order by year, current_month asc) as prev_spend
	 from m 
 )
	 select top 1 card_type, exp_type, (current_spend - prev_spend) as mom_growth 
	 from abc 
 where year = '2014' and current_month = 1
 order by mom_growth desc
 
 
 
 
 ---8- During weekends which city has highest total spend to total no of transcations ratio 
 select city,sum(amount)*1.0/COUNT(*) as ratio
 from credit_card_transcations
 where DATEPART(weekday,transaction_date) in (1,7)
 group by city
 order by ratio desc




 ---9- which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as (
    select city,transaction_date,transaction_id,
    row_number() over (partition by city order by transaction_date, transaction_id) as rn
    from credit_card_transcations
)
select city,
    min(transaction_date) AS first_transaction,
    max(transaction_date) AS last_transaction,
    datediff(day, min(transaction_date), max(transaction_date)) as days_to_500
from cte
where rn IN (1, 500)
group by city
having count(*) = 2
order by city
