--Look at the datatypes and columns

exec sp_help sales_data.dbo.sales_data_sample;;

SELECT * 
FROM sales_data.dbo.sales_data_sample;

--All columns saved as varchar so change relevant columns to suitable datatatype. 
--Some phone numbers and addresses are mixed up
--change datatypes 

alter table sales_data.dbo.sales_data_sample
alter column QUANTITYORDERED int;

alter table sales_data.dbo.sales_data_sample
alter column PRICEEACH float;

alter table sales_data.dbo.sales_data_sample
alter column ORDERLINENUMBER int;

alter table sales_data.dbo.sales_data_sample
alter column SALES float;

alter table sales_data.dbo.sales_data_sample
alter column ORDERDATE date;

alter table sales_data.dbo.sales_data_sample
alter column QTR_ID int;

alter table sales_data.dbo.sales_data_sample
alter column MONTH_ID int;

alter table sales_data.dbo.sales_data_sample
alter column YEAR_ID int;

alter table sales_data.dbo.sales_data_sample
alter column MSRP int;

alter table sales_data.dbo.sales_data_sample
alter column ORDERLINENUMBER int;

--create new table and extract the weekdays and months from order dates

SELECT [ORDERNUMBER]
      ,[QUANTITYORDERED]
      ,[PRICEEACH]
      ,[ORDERLINENUMBER]
      ,[SALES]
      ,[ORDERDATE]
      ,[STATUS]
      ,[QTR_ID]
      ,[MONTH_ID]
      ,[YEAR_ID]
      ,[PRODUCTLINE]
      ,[MSRP]
      ,[PRODUCTCODE]
      ,[CUSTOMERNAME]
      ,[PHONE]
      ,[ADDRESSLINE1]
      ,[ADDRESSLINE2]
      ,[CITY]
      ,[STATE]
      ,[POSTALCODE]
      ,[COUNTRY]
      ,[TERRITORY]
      ,[CONTACTLASTNAME]
      ,[CONTACTFIRSTNAME]
      ,[DEALSIZE]
	  ,datename(weekday, ORDERDATE) as week_day
	  ,datename(month, ORDERDATE) as month
  INTO sales_data
  FROM [sales_data].[dbo].[sales_data_sample]


--check for duplicates

select distinct order_number, count(*) as no_duplicates
from sales_data.dbo.sales_data
group by order_number


--examine one row of duplicate more closely, ordernumber covers different products or quantities to tthe same customer on the same day
--therefore they are not duplicates

select *
from sales_data.dbo.sales_data
where order_number = 10113; 

--extract weekdayas and months and add to new table
--looking at the length of the sales table was collected, the data covered  1/2003 started and ended on 5/2005. 



--We examine change in quantity and sales year over year from 2003 to 2005. There was around 35% increase in quantity ordered from 2004 to 2003
--In 2005, there was sharp decline sales and quantityordered  of -62%. The sales in 2005 can be explained by the incomplete data in 2005.
 
WITH sum_quantity as
	(select year_id as year_id, sum(quantity_ordered) as total_qty, sum(sales) as total_sales 
	FROM sales_data.dbo.sales_data group by year_id),
 
  diff as 
	  (select year_id,  total_qty, total_qty
	  - lag(total_qty) over (order by year_id) as qty_diff, total_sales, total_sales - lag(total_sales) over (order by year_id) as diff_sales
	  from sum_quantity)
 
select year_id, total_qty, qty_diff, 
	 concat(qty_diff*100 / lag(total_qty) OVER (order by year_id),'.', qty_diff*100 % lag(total_qty) OVER (order by year_id), '%') as '%change_qty', total_sales, diff_sales,

	 concat(diff_sales*100/lag(total_sales) over (order by year_id), '%') as'%change_sales'
   
from diff
order by year_id;


--to confirm the assumpton of sales figure in 2005, we can look at sales between 01/2004 to 05/2004 and 01/2005 to 05/2005 and 
--the same month comparison (month 1 to month 5)mshows that the company made more sales and sold more quantities in 2005 than in 2004

select sum(quantity_ordered) as total_qty, sum(sales) as total_sales, year_id as year_id, rank() over (partition by year_id order by year_id)
from sales_data.dbo.sales_data
where month_id <= 5 and year_id = 2004 OR  year_id =  2005
group by year_id;


--look at the days to see if there is a pattern of sales in days or months. The lack of data for 06/2005 to 12/2005 should be considered
--Business is slow during the weekends and starts to pick by by Monday and sales continues to rise till Friday. with the highest orders on Friday
--November and October have the highest sales of products in 2003 and 2004=, the rest of the other months do not have a pattern to them

select week_day, count(week_day) as count_weekday
from sales_data.dbo.sales_data
group by week_day 
order by week_day desc;


select month, count(month) as no_month, year_id, rank () over (partition by year_id order by year_id)
from sales_data.dbo.sales_data
group by year_id, month
order by year_id, no_month desc;

--despite the lack of data for 06/2005 - 12/2005, we see the 4th quarter having more sales than other quarters, this can be attributed to november and octer as seen in months
--the third quarter has the next highest sales for 2003 aand 2004, however for all years, it is the 1st quarter

select qtr_id, year_id, count(qtr_id) as number_of_sales
from sales_data.dbo.sales_data
group by qtr_id, year_id
order by year_id, qtr_id;



--Finding out the number of products sold, ordered, and their quantities, the percentage of total quantityordered,
--the productline column list the products sold by A company. 
--Most quantities sold come from classic cars around 38%, foolowed by vintage cars at approximately 21% with trains being the least purchased  at 2.7% 

with cte as

	(select product_line,  sum(quantity_ordered) as total_qty, sum(sales) as total_sales, sum(msrp * quantity_ordered) as total_msrp
	from sales_data.dbo.sales_data
	group by product_line 
	),

tq as
	(select sum(total_qty) as p
	from cte)

select cte.product_line, cte.total_sales, cte.total_sales - cte.total_msrp as diff_price, cte.total_msrp, cte.total_qty,
	concat(cte.total_qty*100 /tq.p,'.',cte.total_qty*100 % tq.p, '%') as '%qty'
from cte, tq;


--the A company has a total of 92 customers and most customers come from the USA

select distinct customer_name, country, sum(sales) as total_sales
from sales_data.dbo.sales_data
group by customer_name, country
order by total_sales desc;

--calculating total_sales by customers

select distinct  country, sum(sales) as total_sales
from sales_data.dbo.sales_data
group by  country
order by total_sales desc;



--order status by year, the order status is divided into 6 status with the A company mangaing to fufill most of its order, with year 2005 
--having the highest resolved and disputed orders. the high in processs, and on hold status can be expplained by incomplete information

select month_id, year_id, 
    count(case when status = 'Shipped' then 1 end) as Shipped,
    count(case when status = 'Resolved' then 1 end) as Resolved,
    count(case when status = 'Cancelled' then 1 end) as Cancelled,
	count(case when status = 'On Hold' then 1 end) as  'On Hold',
	count(case when status = 'Disputed' then 1 end) as Dsiputed,
	count(case when status = 'In Process' then 1 end) as 'In Process'
 
from sales_data.dbo.sales_data 
 
group by month_id,year_id
order by year_id;

--filtering the results by month shows that most of the on hold, disputed and in process status comes from the last two months of 2005, 04/2005 - 05/2005 
select month_id, month, count(case when status = 'Shipped' then 1 end) as Shipped,
    count(case when status = 'Resolved' then 1 end) as Resolved,
    count(case when status = 'Cancelled' then 1 end) as Cancelled,
	count(case when status = 'On Hold' then 1 end) as  'On Hold',
	count(case when status = 'Disputed' then 1 end) as Dsiputed,
	count(case when status = 'In Process' then 1 end) as 'In Process'

 from sales_data.dbo.sales_data 
 where year_id = 2005
 group by month, month_id;



--Calculate the difference between actual sales price and msrp, msrp is the manufacturer suggested retail price

with cte as 
	(select distinct product_code, product_line, msrp, price_each, msrp - price_each as diff_price, 
		price_each * quantity_ordered as price, msrp * quantity_ordered as msrp_sales
	from sales_data.dbo.sales_data)

select product_code, product_line, msrp, price_each, diff_price, price, msrp_sales, msrp_sales - price as loss_profit
from cte
order by loss_profit desc;


--calculate the amount lost/gained for selling at own price instead of manufacturer suggested retail price (msrp)
--A company lost a total of $-1304339.23 for selling below msrp

with cte as 
	(select distinct product_code, product_line, msrp, price_each, price_each - msrp as diff_price, 
		price_each * quantity_ordered as price, msrp * quantity_ordered as msrp_sales
	from sales_data.dbo.sales_data),

cat as 
	(select product_code, product_line, msrp, price_each, diff_price, price, msrp_sales, price - msrp_sales as loss_profit
	from cte)

select sum(loss_profit)
from cat
where msrp_sales < price;

--grouping customer's by products ordered
select customer_name, 
	 count(case when product_line = 'Classic Cars' then 1 end) as classic_cars,
	count(case when product_line = 'Vintage Cars' then 1 end) as vintage_cars,
	count(case when product_line = 'Motorcycles' then 1 end) as  motorcycles,
	count(case when product_line = 'Trains' then 1 end) as trains,
	count(case when product_line = 'Ships' then 1 end) as ships,
	count(case when product_line = 'Truck and Buses' then 1 end) as trucks_bus,
	count(case when product_line = 'Planes' then 1 end) as planes

from sales_data.dbo.sales_data
group by customer_name



