-- Choose database
use [sql project]

-- Q1. Select order_id, order_date, order_quantity, value, profit from Orders table
--- Create new column: order_quantity*unit_price*(1-discount) as revenue
---------------------- product_base_margin*unit_price+shipping_cost as total_cost
---------------------- revenue - total_cost as net_profit
With A as
	(Select order_id, order_date, order_quantity, value, profit, 
		order_quantity*unit_price*(1-discount) as revenue,
		product_base_margin*unit_price+shipping_cost as total_cost
	From Orders) 
Select A.*, revenue - total_cost as net_profit From A

-- Q2. Select information from Orders table that meet the below conditions
--- 1. region is 'West', order_priority is not 'Critical', 
Select * From Orders
	Where lower(region) = 'west' and lower(order_priority) != 'critical'  

--- 2. province contains 'new', shipping_mode isn't contain 'air', value is lower than 500
Select * From Orders
	Where lower(province) like '%new%'
		and lower(shipping_mode) not like '%air%' 
		and value < 500

--- 3. product_subcategory starts with 'Co', customer_segment ends with 'e', order_quantity is bigger than 10
Select * From Orders
	Where lower(product_subcategory) like 'co%' 
		and customer_segment like '%e' and order_quantity > 10

-- Q3. Select top 10 customer making highest profit from Nunavut (provice)
Select Top 10 province, customer_name, sum(profit) as total_profit
	From Orders
	Where lower(province) = 'nunavut'
	Group by province, customer_name
	Order by sum(profit) desc

-- Q4. From Orders and Returns table, calculate total order_quantity, value, profit of all returned order
Select O.order_id as order_id_return, O.order_date, sum(O.order_quantity) as total_order_quantity, 
	sum(O.value) as total_value, sum(O.profit) as sum_profit, R.returned_date
		From Returns as R 
		Left Join Orders as O on O.order_id = R.order_id
		Where lower(R.status) = 'returned'
		Group by O.order_id, O.order_date, R.returned_date

-- Q5. From Orders and Profiles, calculate total of order_quantity, value, profit of each manager and add grand total row at the end.
Select P.manager, sum(O.order_quantity) as total_order_quantity, sum(O.value) as total_value, sum(O.profit) as total_profit
	From Profiles as P 
	Left join Orders as O on O.province = P.province
	Group by P.manager
	Having (sum(O.order_quantity) > 0) 
Union all
Select 'Total' as manager, sum(O.order_quantity) as total_order_quantity, sum(O.value) as total_value, sum(O.profit) as total_profit
	From Orders as O

-- Q6. From Orders table, select product_name contains 'newell',
---- create range_value column (if value < 200: low, value < 1000: medium, value > 1000: high) 
---- and create Thickness column (extract from product_name column)
Select *, 
	Case when value < 200 then 'low' when value < 1000 then 'medium' else 'high' end as range_value,
	Right(product_name, Len(product_name)-Charindex(' ',product_name)) + ' mm' as Thickness
	From Orders 
	Where lower(product_name) like '%newell %'

-- Q7. From Orders table, calculate total order number, value, profit, quantity by year (chắc bỏ)
Select year(order_date) as year, count(distinct(order_id)) as count_orders, sum(order_quantity) as total_order_quantity,
	sum(value) as total_value, sum(profit) as total_profit 
		From Orders
		Group by year(order_date)
		Order by year(order_date) desc

-- Q8. From Orders and Returns table, calculate total orders & returns (number, value, profit) by year and month and add a grand total row on top
With A as
	(Select year(O.order_date) as year, month(O.order_date) as month, 
		count(distinct(O.order_id)) as total_orders, sum(O.value) as total_value, sum(profit) as total_profit 
			From Orders as O
			Group by year(O.order_date), month(O.order_date)),
	B as
	(Select year(R.returned_date) as year, month(R.returned_date) as month,
		count(distinct(R.order_id)) as total_returns, sum(O.value) as total_value_return, sum(O.profit) as total_profit_return
			From Returns as R
			Left join Orders as O on O.order_id = R.order_id
			Group by year(R.returned_date), month(R.returned_date))
Select A.year, A.month, A.total_orders, B.total_returns, A.total_value, B.total_value_return, A.total_profit, B.total_profit_return
	From A 
	Left join B on A.year = B.year and A.month = B.month
Union all
Select '' as year, '' as month, sum(A.total_orders) as total_orders, sum(B.total_returns) as total_returns,
	sum(A.total_value) as total_value, sum(B.total_value_return) as total_value_return, 
	sum(A.total_profit) as total_profit, sum(B.total_profit_return) as total_profit_return
		From A, B

-- Q9. Select total remain order (order-return) information in 2012 of each manager
---- With CTE
With A as
	(Select M.*, R.status, O.order_id, O.order_quantity, O.value, O.profit
	From Orders as O
	Left join Returns as R on R.order_id = O.order_id
	Left join Profiles as P on P.province = O.province 
	Left join Managers as M on M.manager_name = P.manager
	Where year(order_date) = 2012 and R.status is null)
Select manager_name, manager_level, manager_id, 
	count(distinct(order_id)) as total_orders, sum(order_quantity) as total_quantity, sum(value) as total_value, sum(profit) as total_profit
	From A
	Group by manager_name, manager_level, manager_id

---- Without CTE
Select M.manager_name, M.manager_level, M.manager_id, 
	count(distinct(O.order_id)) as total_orders, sum(O.order_quantity) as total_quantity, sum(O.value) as total_value, sum(O.profit) as total_profit
		From Orders as O
		Left join Returns as R on R.order_id = O.order_id
		Left join Profiles as P on P.province = O.province 
		Left join Managers as M on M.manager_name = P.manager
		Where year(order_date) = 2012 and R.status is null
		Group by M.manager_name, M.manager_level, M.manager_id

-- Q10. From Orders table, calculate profit of each customer divided by product category (optional: add grand total column and row)
Select customer_name, Isnull("Office Supplies", 0) as "Office Supplies", 
	Isnull("Furniture", 0) as "Furniture", Isnull("Technology", 0) as "Technology", -- add isnull to replace null value with 0
	Isnull("Office Supplies", 0) + Isnull("Furniture", 0) + Isnull("Technology", 0) as "Grand Total" -- add grand total column
		From (Select customer_name, product_category, profit From Orders) as Input
		Pivot (Sum(profit) For product_category in ("Office Supplies", "Furniture", "Technology")) as Finish
Union all -- add grand total row
Select 'Grand total' as customer_name, "Office Supplies", "Furniture", "Technology",
	"Office Supplies" + "Furniture" + "Technology" as "Grand Total"
		From (Select profit, product_category From Orders) as Input
		Pivot(Sum(Profit) For product_category In ("Office Supplies", "Furniture", "Technology")) as Finish

-- Q11. From Orders table, calculate value of each province divided by order_priority (optional: add grand total column and row)
With A as
	(Select province, Isnull("Not Specified", 0) as "Not Specified", Isnull("Low", 0) as "Low", 
		Isnull("Medium", 0) as "Medium", Isnull("High", 0) as "High", Isnull("Critical", 0) as "Critical"
			From (Select province, order_priority, value From Orders) as Input
			Pivot (Sum(value) For order_priority In ("Not Specified", "Low", "Medium", "High", "Critical")) as Finish), 
	B as
	(Select 'Grand total' as province, Isnull("Not Specified", 0) as "Not Specified", Isnull("Low", 0) as "Low", 
		Isnull("Medium", 0) as "Medium", Isnull("High", 0) as "High", Isnull("Critical", 0) as "Critical" 
			From (Select order_priority, value From Orders) as Input
			Pivot (Sum(value) For order_priority In ("Not Specified", "Low", "Medium", "High", "Critical")) as Finish)
Select A.*, "Not Specified" + "Low" + "Medium" + "High" + "Critical" as "Grand total" 
	From A
Union all
Select B.*, "Not Specified" + "Low" + "Medium" + "High" + "Critical" as "Grand total" 
	From B

-- Q12. Top 3 products have highest profit of each product category
With A as
	(Select product_category, product_name, Sum(profit) as total_profit,
		Row_number() over (Partition by product_category Order by Sum(profit) desc) as rank
			From Orders
			Group by product_category, product_name)
Select * 
	From A Where rank < 4

-- Q13. Create table with columns: year, month, total_revenue, total_revenue_returned, acc_revenue, group_revenue
-- revenue = order_quantity*unit_price*(1-discount)
-- acc_revenue = total_revenue - total_revenue_returned
-- group_revenue (acc_revenue < 10000: thấp, < 20000: trung bình, > 20000: cao)

---CTE
With A as
	(Select year(order_date) as year, month(order_date) as month, 
		order_quantity*unit_price*(1-discount) as revenue
			From Orders),
	B as
	(Select year(R.returned_date) as year, month(R.returned_date) as month, 
		O.order_quantity*O.unit_price*(1-O.discount) as revenue_returned
			From Orders as O
			Left join Returns as R on R.order_id = O.order_id
			Where R.status is not null)
Select A.year, A.month, Sum(A.revenue), Sum(B.revenue_returned), Sum(A.revenue - B.revenue_returned) as acc_revenue,
	Case when Sum(A.revenue - B.revenue_returned) < 10000 then 'Thap' 
			when Sum(A.revenue - B.revenue_returned) < 20000 then 'Trung binh'
			else 'Cao' end as group_revenue
		From A
		Left join B on A.year = B.year and A.month = B.month
		Group by A.year, A.month
		Order by A.year, A.month 

---- Subquery
Select *, 
	Case when total_revenue_net < 10000 then 'Thap'
			when total_revenue_net < 20000 then 'Trung binh'
			else 'Cao' end as group_revenue
	From 
		(Select year, month, total_revenue, total_revenue_returned, total_revenue - total_revenue_returned as total_revenue_net
			From 
				((Select year(order_date) as year, month(order_date) as month, 
					Sum(order_quantity*unit_price*(1-discount)) as total_revenue
						From Orders 
						Group by year(order_date), month(order_date)) as A
					Left join
				(Select year(returned_date) as year_returned, month(returned_date) as month_returned, 
					Sum(O.order_quantity*O.unit_price*(1-O.discount)) as total_revenue_returned
						From Returns as R
						Left join Orders as O on R.order_id = O.order_id
						Group by year(returned_date), month(returned_date)) as B
					On A.year = B.year_returned and A.month = B.month_returned)) as C
	Order by month, year

---- Create a tempt table
With A as
	(Select year(order_date) as year_order, month(order_date) as month_order, 
		Sum(order_quantity*unit_price*(1-discount)) as total_revenue
			From Orders 
			Group by year(order_date), month(order_date)),
	B as
	(Select year(R.returned_date) as year_return, month(R.returned_date) as month_return,
		Sum(O.order_quantity*O.unit_price*(1-O.discount)) as total_revenue_returned
			From Returns as R
			Left join Orders as O on O.order_id = R.order_id
			Group by year(R.returned_date), month(R.returned_date))
Select A.year_order as year, A.month_order as month, A.total_revenue, B.total_revenue_returned, A.total_revenue - B.total_revenue_returned as total_revenue_net
	Into #temptable
		From A 
		Left join B on A.year_order = B.year_return and A.month_order = B.month_return

Select year, month, round(total_revenue, 2) as total_revenue, round(total_revenue_returned, 2) as total_revenue_returned, round(total_revenue_net, 2) as total_revenue_net,
	Case when total_revenue_net < 10000 then 'Thap'
		when total_revenue_net < 20000 then 'Trung binh'
		else 'Cao' end as group_revenue
		From #temptable
		Order by year, month