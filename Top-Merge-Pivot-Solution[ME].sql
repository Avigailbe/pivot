--2.

use edate_new

select * into copy_HR_Emp
from [AdventureWorks2017].HumanResources.Employee

alter table copy_HR_Emp
add checkCol as checksum(loginid);
create index checkCol_index on copy_HR_Emp (checkCol);

select checkCol 
from copy_HR_Emp
where loginid = 'adventure-works\terri0'

--3. (also D in excersise book page 21)

select ntile(4) over(order by rowguid) as groupId, *
from copy_HR_Emp


--4 merge adventureworks with northwind
--a. first name last name, address and telephone
--b. same code, northwind firstname stays same and lastname gets updated by adventureworks
--   code in adventureworks but not in northwind, names updated from adventureworks
--   code in northwind not in adventureworks stay same

merge into northwind_new.dbo.employees as target 
	using adventureworks2017.person.person as source
	on (target.EmployeeID = source.BusinessEntityID)
	when matched then
		update set FirstName = target.FirstName, lastname = source.Lastname
	when not matched by target then
		insert (FirstName, lastname)
		values (source.firstname, source.Lastname)
	when not matched by source then
		update set FirstName = target.firstname, lastname = target.lastname
	OUTPUT $action, inserted.EmployeeID ,  deleted.EmployeeID, inserted.FirstName ,  deleted.FirstName, inserted.lastName ,  deleted.lastName;

--SET IDENTITY_INSERT northwind_new.dbo.new_employees off
--SET IDENTITY_INSERT northwind_new.dbo.employees off
Declare @address varchar (60) , @phoneNumber varchar (60), @Firstname varchar (60), @Lastname varchar (60)
Declare Addcursor cursor
for select distinct ad.addressLine1, ph.phonenumber		
				from adventureworks2017.person.address ad, adventureworks2017.person.businessEntityAddress bad, 
				adventureworks2017.person.person per, adventureworks2017.person.personphone ph, northwind_new.dbo.employees emp
				where ad.addressid = bad.addressid
				and bad.businessEntityId = per.businessEntityId
				and per.businessEntityId = ph.businessentityid
				and per.FirstName = emp.FirstName
				and per.LastName = emp.LastName
open Addcursor
Fetch next from Addcursor into @address, @phoneNumber
while @@FETCH_STATUS=0
begin 
	merge into northwind_new.dbo.employees as target 
	using adventureworks2017.person.person as source
	on (target.firstname = source.firstname and target.LastName = source.LastName)
	when matched then
		update set Address = @address, homephone = @phoneNumber
	OUTPUT $action, inserted.address,  deleted.address, inserted.homephone, deleted.homephone;
Fetch next from Addcursor into @address, @phoneNumber
end 
close Addcursor
Deallocate Addcursor


--5 (also A in excersise book page 20) show average standard cost - rows
--       DaysToManufacture - columns
use AdventureWorks2017
go

select 'AverageCost' AS Cost_By_Production_Days,   
					[0], [1], [2], [3], [4]  
FROM  (SELECT DaysToManufacture, StandardCost   
       FROM Production.Product) AS SourceTable  
PIVOT  
(  
		AVG(StandardCost)  
		FOR DaysToManufacture IN ([0], [1], [2], [3], [4])  
) AS PivotTable;  


--6. (also B in excersise book page 21) show	genders - rows
--			amount of employees born every year between 1980-1990 - columns

select Gender as Amount_of_Employees_by_Gender,
		[1980],[1981],[1982],[1983],[1984], [1985],[1986],[1987],[1988],
		[1989],[1990]
from (select businessentityid, gender, year(birthdate) as yearbirth
		from humanresources.Employee 
		where year(birthdate) between ('1980') and ('1990')) as SourceTable
pivot
(
		 count(businessentityid)
		 for yearbirth in ([1980],[1981],[1982],[1983],[1984],
								 [1985],[1986],[1987],[1988],[1989],[1990])
) as pvtable;


--7. (also C in excersise book page 21) amount of employees per dept - rows
--	 gender		- columns
--where still valid (EndDate is null)

select DepartmentID AS Employees_per_Dept,
		[M], [F]
from (select emp.BusinessEntityID, emph.DepartmentID, emp.Gender 
	    from humanresources.Employee emp 
		inner join humanresources.EmployeeDepartmentHistory emph
		on emp.BusinessEntityID = emph.BusinessEntityID
		where emph.EndDate is null) as SourceTable 
pivot
(
	count(BusinessEntityID) for Gender in ([M], [F])
)as pvtable;


--8. show amount of employees divided by city for addressid=5
-- amount employees - column
-- city - rows

select city AS Employees_per_City, [5] as 'Amount_of_Emps_Per_City'
from (select paddt.AddressTypeID, pbea.BusinessEntityID, padd.City 
		from person.BusinessEntityAddress pbea 
		inner join person.Address padd 
		on padd.AddressID = pbea.AddressID 
		inner join person.AddressType paddt
		on pbea.AddressTypeID = paddt.AddressTypeID
		where paddt.AddressTypeID=5) as SourceTable 
pivot
(
	count(BusinessEntityID) for AddressTypeID in ([5])
)as pvtable;


--9. number of employees - column
--   provences - rows

select StateProvinceCode AS Province, [5] as 'Emps_Per_Province'
from (select pstp.StateProvinceCode, pbea.BusinessEntityID, pbea.AddressTypeID
		from person.Address padd 
		inner join person.StateProvince pstp
		on padd.StateProvinceID = pstp.StateProvinceID
		inner join person.BusinessEntityAddress pbea
		on pbea.AddressID = padd.AddressID
		where pbea.AddressTypeID=5) as SourceTable 
pivot
(
	count(BusinessEntityID) for AddressTypeID in ([5])
)as pvtable;

--?????????SOLUTION THAT DOESN'T WORK BECAUSE TYPE  <> 5
select Province, [5] as 'Emps_Per_Province'
from (select e.BusinessEntityID as number,sp.Name Province , a.StateProvinceID, BEA.AddressTypeID
		from HumanResources.Employee e inner join 
			person.businessentityaddress bea
		on e.BusinessEntityID=bea.BusinessEntityID inner join 
			person.address a 
		on bea.AddressID=a.AddressID INNER join
		Person.StateProvince sp 
		on a.StateProvinceID=sp.StateProvinceID) as SourceTable 
pivot
(
	count(number) for AddressTypeID in ([5])
)as pvtable;

--10.	with northwind.employees and edate.operation.members
--		empid, firstName, LastName

with both as (
		select emp.EmployeeID as 'Emps_Both',emp.FirstName as 'FN_Both', emp.LastName as 'LN_Both'
		from Northwind.dbo.employees emp
		union
		select mem.Id, mem.FirstName, mem.LastName
		from edate.Operation.Members mem
),
InCommon as (
		select emp.EmployeeID as 'Emps_InCommon',emp.FirstName as 'FN_InCom', emp.LastName as 'LN_InCom'
		from Northwind.dbo.employees emp 
		inner join edate.Operation.Members mem
		on emp.EmployeeID = mem.Id
),
eDateNotNorth as (
		select mem.Id as 'Emps_eDateNotNorthwind', mem.FirstName as 'FN_eDateNotNorthwind', mem.LastName as 'LN_eDateNotNorthwind'
		from edate.Operation.Members mem 
		except
		select emp.EmployeeID,emp.FirstName, emp.LastName
		from Northwind.dbo.employees emp
)
select Emps_InCommon AS empId,[FN_Both], [LN_Both], [FN_InCom], [LN_InCom], [FN_eDateNotNorthwind], [LN_eDateNotNorthwind]
from (select both.Emps_Both, both.FN_Both, both.LN_Both, 
			 Emps_InCommon, InCommon.FN_InCom, InCommon.LN_InCom, 
			 eDateNotNorth.FN_eDateNotNorthwind, 
			 eDateNotNorth.LN_eDateNotNorthwind
	  from  both, InCommon, eDateNotNorth 
	  where both.Emps_Both = InCommon.Emps_InCommon
	  and both.Emps_Both = eDateNotNorth.Emps_eDateNotNorthwind) as SourceTable
pivot
(
	count(Emps_Both) for Emps_Both in ([1], [2], [3], [4], [5], [6], [7], [8], [9])--, LN_Both, Emps_InCommon, FN_InCom, LN_InCom, Emps_eDateNotNorthwind, FN_eDateNotNorthwind, LN_eDateNotNorthwind)
)as pvtable;

