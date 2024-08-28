-- Easy level Q1 to Q5
-- Q1. Show the first name and the email address of customer with CompanyName 'Bike World'

select 
firstname,
emailaddress
from Customer
where companyname = 'Bike World'
;

-- Q2. Show the CompanyName for all customers with an address in City 'Dallas'.

select
distinct c.companyname
from Customer as c
join CustomerAddress as ca
on c.customerid = ca.customerid
where ca.addressid in (
select addressid
from Address
where city = 'Dallas')
;

-- Q3. How many items with ListPrice more than $1000 have been sold?

select
count(sod.productid) as number_of_item
from SalesOrderDetail as sod
join Product as p
on sod.productid = p.productid
where p.listprice > 1000
;

-- Q4. Give the CompanyName of those customers with orders over $100000. Include the subtotal plus tax plus freight.

select
companyname
from Customer
where customerid in (select
customerid
from SalesOrderHeader
group by customerid
having sum(subtotal+taxamt+freight) > 100000)
;

-- Q5. Find the number of left racing socks ('Racing Socks, L') ordered by CompanyName 'Riding Cycles'

select
sum(sod.orderqty) as number_of_orders
from Customer as c
join SalesOrderHeader as soh
on c.customerid = soh.customerid
join SalesOrderDetail as sod
on soh.salesorderid = sod.salesorderid
join Product as p
on sod.productid = p.productid
where p.name = 'Racing Socks, L'
and c.companyname = 'Riding Cycles'
;

-- Medium level Q6 to Q10
-- Q6. A "Single Item Order" is a customer order where only one item is ordered. Show the SalesOrderID and the UnitPrice for every Single Item Order.

with filterorder as (select
salesorderid, sum(orderqty)
from SalesOrderDetail
group by salesorderid
having sum(orderqty) = 1)

select
salesorderid,
unitprice
from SalesOrderDetail
where salesorderid in (select salesorderid 
from filterorder)
;

-- Q7. Where did the racing socks go? List the product name and the CompanyName for all Customers who ordered ProductModel 'Racing Socks'.

select
p.name,
c.companyname
from Customer as c
join SalesOrderHeader as soh
on c.customerid = soh.customerid
join SalesOrderDetail as sod
on soh.salesorderid = sod.salesorderid
join Product as p
on sod.productid = p.productid
join ProductModel as pm
on p.productmodelid = pm.productmodelid
where pm.name = 'Racing Socks'
;

-- Q8. Show the product description for culture 'fr' for product with ProductID 736. (my attempt using nested query for practicing but join is also possible)

select
description
from ProductDescription
where productdescriptionid in (
    select productdescriptionid
    from ProductModelProductDescription
    where culture = 'fr'
    and Productmodelid in (
        select productmodelid
        from ProductModel
        where productmodelid in (
            select
            productmodelid
            from Product
            where productid = 736)))
;

-- Q9. Use the SubTotal value in SaleOrderHeader to list orders from the largest to the smallest. For each order show the CompanyName and the SubTotal and the total weight of the order.

select
c.companyname,
soh.subtotal,
sum(sod.orderqty * p.weight) as total_weight
from SalesOrderHeader as soh
join Customer as c
on soh.customerid = c.customerid
join SalesOrderDetail as sod
on soh.salesorderid = sod.salesorderid
join Product as p
on sod.productid = p.productid
group by soh.salesorderid, c.companyname, soh.subtotal
order by soh.subtotal desc
;

--Q10. How many products in ProductCategory 'Cranksets' have been sold to an address in 'London'? (my attempt using cte instead of simple join for practicing)

--finding product id in category name 
with filterproduct as (
select productid
from Product as p
join ProductCategory as pc
on p.productcategoryid = pc.productcategoryid
where pc.name = 'Cranksets'),

-- finding addressid in city name
filteraddress as (
select
addressid
from Address
where city = 'London')

--joing two cte together and find total orderqty
select
sum(sod.orderqty) as total
from SalesOrderDetail as sod
join filterproduct 
on sod.productid = filterproduct.productid
join SalesOrderHeader as soh
on sod.salesorderid = soh.salesorderid
join filteraddress
on soh.billtoaddressid = filteraddress.addressid
;

-- Hard level Q11 to Q15
--Q11. For every customer with a 'Main Office' in Dallas show AddressLine1 of the 'Main Office' and AddressLine1 of the 'Shipping' address - if there is no shipping address leave it blank. Use one row per customer.

--using max case when to ensure customerid appear in the same row if there are duplicated
select
ca.customerid,
max(case when ca.addresstype = 'Main Office' then a.addressline1 else ' ' end) as main_office,
max(case when ca.addresstype = 'Shipping' then a.addressline1 else ' ' end) as shipping_office
from CustomerAddress as ca
join Address as a
on ca.addressid = a.addressid
where a.city = 'Dallas'
group by ca.customerid

--Q12. For each order show the SalesOrderID and SubTotal calculated three ways:
--A) From the SalesOrderHeader
--B) Sum of OrderQty*UnitPrice
--C) Sum of OrderQty*ListPrice

--finding sum of B)
with cteb as (
select
salesorderid,
sum(orderqty * unitprice) as total
from SalesOrderDetail
group by salesorderid),
--find sum of C)
ctec as (
select
sod.salesorderid,
sum(sod.orderqty * p.listprice) as total
from SalesOrderDetail as sod
join Product as p
on sod.productid = p.productid
group by sod.salesorderid)
--A) already provided joining finding sum of B) and C) together
select
sod.salesorderid,
soh.subtotal,
cteb.total,
ctec.total
from SalesOrderDetail as sod
join SalesOrderHeader as soh
on sod.salesorderid = soh.salesorderid
join cteb
on sod.salesorderid = cteb.salesorderid
join ctec
on sod.salesorderid = ctec.salesorderid
group by sod.salesorderid
;

--Q13. Show the best selling item by value.

--identifying best selling item using dense_rank()
with bestsell as (
select
productid,
sum(orderqty * unitprice) as total,
dense_rank() over(
order by sum(orderqty * unitprice) desc) as ranking
from SalesOrderDetail
group by productid
order by ranking)

select
name,
bs.total
from Product as p
join bestsell as bs
on p.productid = bs.productid
where ranking = 1
;

--Q14. Show how many orders are in the following ranges (in $):
--RANGE      Num Orders      Total Value
--0-  99
--100- 999
--1000-9999
--10000-

--finding total amount for each sale order id
with grouping as(
select
salesorderid,
sum(orderqty * unitprice) as total
from SalesOrderDetail
group by salesorderid
),
--classify each total amount using case when into each category 
grouping2 as (
select case
when total between 0 and 99 then '0-99'
when total between 100 and 999 then '100-999'
when total between 1000 and 9999 then '1000-9999'
else '10000-'
end as range_value,
salesorderid,
total
from grouping
)
--count sale order id in each category and total in each category
select
range_value,
count(salesorderid) as num_orders,
sum(total) as total
from grouping2
group by range_value
;

-- Alternative, shorter way removing second cte (grouping2)
with grouping as(
select
salesorderid,
sum(orderqty * unitprice) as total
from SalesOrderDetail
group by salesorderid
)

select case
when total between 0 and 99 then '0-99'
when total between 100 and 999 then '100-999'
when total between 1000 and 9999 then '1000-9999'
else '10000-'
end as range_value,
count(salesorderid) as num_orders,
sum(total) as total
from grouping
group by range_value
;

--Q15. Identify the three most important cities. Show the break down of top level product category against city.
--finding top city using rank() where top cities are the most items being sold to
with top_city as (
select
a.city,
sum(sod.orderqty * sod.unitprice) as total,
rank() over (
order by sum(sod.orderqty * sod.unitprice) desc) as ranks
from SalesOrderDetail as sod
join SalesOrderHeader as soh 
on sod.salesorderid = soh.salesorderid
join Address as a 
on soh.billtoaddressid = a.addressid
and soh.shiptoaddressid = a.addressid
group by a.city
order by ranks)

--select category name with city filtering only top 3 and total amount for each product category
select
a.city,
pc.name,
sum(sod.orderqty * sod.unitprice) as total
from SalesOrderDetail as sod
join Product as p
on sod.productid = p.productid
join SalesOrderHeader as soh
on sod.salesorderid = soh.salesorderid
join Address as a
on soh.billtoaddressid = a.addressid
and soh.shiptoaddressid = a.addressid
join ProductCategory as pc
on p.productcategoryid = pc.productcategoryid
where a.city in (
    select
    city
    from top_city
    where ranks < 3)
group by a.city, pc.name
order by a.city, total desc
;