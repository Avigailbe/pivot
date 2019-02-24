USE [Northwind_new]
GO

CREATE TABLE [dbo].[Quiz](
	[INumber] [int] NULL,
	[Subject] [nvarchar](50) NULL,
	[Grade] [int] NULL
) ON [PRIMARY]
GO

select INumber, [Hebrew], [Dutch], [English], [MaxGrade_Subject]
FROM  (select q.INumber, grade, Subject, s.MaxGrade_Subject
	   from quiz q, (select INumber, (cast((max(Grade) over (partition by INumber))as varchar)+'-'+ Subject) as MaxGrade_Subject 
                   from quiz) as s
       where q.INumber=s.INumber)source

PIVOT  
(  
		Max(Grade)  
		FOR Subject IN ([Hebrew], [Dutch], [English])
) AS PivotTable;  

