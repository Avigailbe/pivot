--A
--Show customer names that made orders in 2015 divided by month
--how many orders per month
--where more than 2 orders per order id

use AdventureWorks2017
go


select FirstName+' '+LastName, [1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12]
from
(
	SELECT pp.FirstName, pp.LastName, month(orderdate) orderMonth,  so.numberOfOrders
	FROM (select orderdate, SalesOrderID, CustomerID, count(SalesOrderID) over (partition by customerid) as numberOfOrders
		  from AdventureWorks2017.Sales.SalesOrderHeader)so
	inner join AdventureWorks2017.Sales.Customer sc
	on so.CustomerID = sc.CustomerID
	inner join Person.Person pp
	on sc.PersonID = pp.BusinessEntityID
	where year(so.orderdate) = '2011'
	and pp.PersonType='IN'
	and so.numberOfOrders >2
) as sourcetable
PIVOT 
(sum(numberOfOrders) for ordermonth in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])) as pivottable


--B. show suppliler names as of 1/1/2013
--columns country, region

use Northwind
go

declare @command varchar(8000)
declare @str varchar(1000) = ''
select @str = @str + '[' + cast(City as varchar) + '],'
		 from Suppliers order by City
set @str = substring(@str , 1 , len(@str) -1 ) 
--do pivot on sting
print @str
set @command = 
'select Country, ' + @str +' from
(
  SELECT CompanyName, City, Country
  FROM dbo.Suppliers
)as sourcetable
PIVOT 
 (count(CompanyName) for city in (' + @str +') ) tablePivot'
  exec (@command)

