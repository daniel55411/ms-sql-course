USE master

GO

IF  EXISTS (
	SELECT name 
		FROM sys.databases 
		WHERE name = N'KB301_Zhenikhov'
)
ALTER DATABASE KB301_Zhenikhov set single_user with rollback immediate
GO

IF  EXISTS (
	SELECT name 
		FROM sys.databases 
		WHERE name = N'KB301_Zhenikhov'
)
DROP DATABASE KB301_Zhenikhov
GO

CREATE DATABASE KB301_Zhenikhov
GO

USE KB301_Zhenikhov
GO

IF EXISTS(
  SELECT *
    FROM sys.schemas
   WHERE name = N'Lab_4'
) 
 DROP SCHEMA Lab_4
GO

CREATE SCHEMA Lab_4 
GO

IF OBJECT_ID('KB301_Zhenikhov.Lab_4.Rate', 'U') IS NOT NULL
  DROP TABLE  KB301_Zhenikhov.Lab_4.Rate
GO

CREATE TABLE KB301_Zhenikhov.Lab_4.Rate
(
	Id int identity(1, 1) primary key,
	Name varchar(20),
	PrepayPeriod int,
	PrepayValue int,
	PostpayValue int
)
GO

IF OBJECT_ID('CalcTariff', 'FN') IS NOT NULL 
	DROP FUNCTION CalcTariff;
GO 

CREATE FUNCTION Lab_4.CalcTariff(@id int, @minutes int)
RETURNS int
AS BEGIN
	DECLARE @prepayPeriod int, @prepayValue int, @postpayValue int;
	SELECT @prepayPeriod = PrepayPeriod, @prepayValue = PrepayValue, @postpayValue = PostpayValue 
	FROM Lab_4.Rate WHERE Id = @id;

	if (@minutes <= @prepayPeriod)
	BEGIN
		RETURN @prepayValue;
	END

	RETURN @postpayValue * (@minutes - @prepayPeriod) + @prepayValue;
END
GO

IF OBJECT_ID('GetEffective', 'P') IS NOT NULL 
	DROP PROCEDURE GetEffective;
GO 

CREATE PROCEDURE Lab_4.GetEffective(@minutes int)
AS BEGIN
	SELECT TOP(1) Id, Name, Lab_4.CalcTariff(Id, @minutes) as value FROM Lab_4.Rate r ORDER BY value;
END
GO

INSERT INTO Lab_4.Rate
	(Name, PostpayValue, PrepayPeriod, PrepayValue)
	VALUES 
	('month', 0, 45000, 300),
	('halfmonth', 10, 300, 200),
	('free', 8, 0, 0)

EXEC Lab_4.GetEffective 5

IF OBJECT_ID('KB301_Zhenikhov.Lab_4.Points', 'U') IS NOT NULL
  DROP TABLE  KB301_Zhenikhov.Lab_4.Points
GO

CREATE TABLE KB301_Zhenikhov.Lab_4.Points
(
	Id int identity(1, 1) primary key,
	FirstTariffId int,
	SecondTariffId int,
	PointX int
)
GO

IF OBJECT_ID('KB301_Zhenikhov.Lab_4.Periods', 'U') IS NOT NULL
  DROP TABLE  KB301_Zhenikhov.Lab_4.Periods
GO

CREATE TABLE KB301_Zhenikhov.Lab_4.Periods
(
	Id int identity(1, 1) primary key,
	Point_1 int,
	Point_2 int
)
GO

IF OBJECT_ID('Intersection', 'FN') IS NOT NULL 
	DROP FUNCTION Intersection;
GO 

CREATE FUNCTION Lab_4.Intersection(@firstTariffId int, @secondTariffId int)
RETURNS int
AS BEGIN
	DECLARE @prepayPeriod_1 int, @prepayValue_1 int, @postpayValue_1 int;
	SELECT @prepayPeriod_1 = PrepayPeriod, @prepayValue_1 = PrepayValue, @postpayValue_1 = PostpayValue 
	FROM Lab_4.Rate WHERE Id = @firstTariffId;

	DECLARE @prepayPeriod_2 int, @prepayValue_2 int, @postpayValue_2 int;
	SELECT @prepayPeriod_2 = PrepayPeriod, @prepayValue_2 = PrepayValue, @postpayValue_2 = PostpayValue 
	FROM Lab_4.Rate WHERE Id = @secondTariffId;

	if (@minutes <= @prepayPeriod)
	BEGIN
		RETURN @prepayValue;
	END

	RETURN @postpayValue * (@minutes - @prepayPeriod) + @prepayValue;
END
GO

IF OBJECT_ID('GetPoints', 'P') IS NOT NULL 
	DROP PROCEDURE GetPoints;
GO 

CREATE PROCEDURE Lab_4.GetPoints
AS BEGIN
	DELETE FROM Lab_4.Points;
	
	SELECT * FROM Lab_4.Rate as [1]
	CROSS JOIN Lab_4.Rate as [2]
END
GO