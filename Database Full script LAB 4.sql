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

	if (@minutes = 0)
	BEGIN
		RETURN 0;
	END
	
	if (@minutes <= @prepayPeriod)
	BEGIN
		RETURN @prepayValue;
	END

	RETURN @postpayValue * (@minutes - @prepayPeriod) + @prepayValue;
END
GO

IF OBJECT_ID('GetEffective', 'FN') IS NOT NULL 
	DROP FUNCTION GetEffective;
GO 

CREATE FUNCTION Lab_4.GetEffective(@minutes int)
RETURNS int
AS BEGIN
	DECLARE @id int;
	SELECT @id=Id FROM Lab_4.Rate ORDER BY Lab_4.CalcTariff(Id, @minutes)
	RETURN @id;
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
	X int primary key,
)
GO

IF OBJECT_ID('KB301_Zhenikhov.Lab_4.Periods', 'U') IS NOT NULL
  DROP TABLE  KB301_Zhenikhov.Lab_4.Periods
GO

CREATE TABLE KB301_Zhenikhov.Lab_4.Periods
(
	Id int identity(1, 1) primary key,
	Point_1 int,
	Point_2 int,
	EfTariffId int
)
GO

DELETE FROM Lab_4.Points;
INSERT INTO Lab_4.Points (X) VALUES (0), (45000)

DECLARE @t1 int, @a1 int, @b1 int,
		@t2 int, @a2 int, @b2 int,
		@x0 int, @y0 int, @id int,
		@x1 int;
DECLARE @temp1 int, @temp2 int, @temp3 int, @swapped int;
SELECT @swapped = 0;

DECLARE cur1 CURSOR FOR
SELECT Id, PrepayPeriod, PostpayValue, PrepayValue FROM Lab_4.Rate

OPEN cur1

FETCH NEXT FROM cur1 
INTO @id, @t1, @a1, @b1
WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE cur2 CURSOR FOR
	SELECT PrepayPeriod, PostpayValue, PrepayValue FROM Lab_4.Rate
	WHERE PrepayPeriod != @t1 AND PostpayValue != @a1 OR PrepayValue != @b1

	OPEN cur2
	FETCH NEXT FROM cur2
	INTO @t2, @a2, @b2

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF (@a1 = 0)
		BEGIN
			SELECT @temp1 = @a1, @temp2=@t1, @temp3=@b1,
					@a1=@a2, @t1=@t2, @b1=@b2;

			SELECT @a2=@temp1, @t2=@temp2, @b2=@temp3, @swapped=1;
		END

		SELECT @x0 = (@t2 + @a1*@t1 + @b1) / @a1;
		IF (@x0 < @t1)
		BEGIN
			IF NOT EXISTS(SELECT * FROM Lab_4.Points WHERE X=@x0)
			BEGIN
				INSERT INTO Lab_4.Points (X) VALUES (@x0)
			END
		END

		SELECT @x0 = (@a1*@t1 - @a2*@t2 + @b2 - @b1) / (@a1 - @a2);
		SELECT @y0 = Lab_4.CalcTariff(@id, @x0);
		IF (@y0 >= @b2 AND @y0 >= @b1)
		BEGIN
			IF (@x0 > 45000)
			BEGIN
				SELECT @x0 = 45000;
			END

			IF NOT EXISTS(SELECT * FROM Lab_4.Points WHERE X=@x0)
			BEGIN
				INSERT INTO Lab_4.Points (X) VALUES (@x0)
			END
		END
		IF (@swapped = 1)
		BEGIN
			SELECT @temp1 = @a1, @temp2=@t1, @temp3=@b1,
					@a1=@a2, @t1=@t2, @b1=@b2;

			SELECT @a2=@temp1, @t2=@temp2, @b2=@temp3, @swapped=0;
		END
		FETCH NEXT FROM cur2
		INTO @t2, @a2, @b2;
	END
	CLOSE cur2;
	DEALLOCATE cur2;

	FETCH NEXT FROM cur1 
	INTO @id, @t1, @a1, @b1
END
CLOSE cur1;
DEALLOCATE cur1;
SELECT * FROM Lab_4.Points

--next step
DECLARE cur1 CURSOR FOR
SELECT * FROM Lab_4.Points ORDER BY X

OPEN cur1;

FETCH NEXT FROM cur1 
INTO @x0

IF @@FETCH_STATUS <> 0
BEGIN
	RETURN;
END

FETCH NEXT FROM cur1 
INTO @x1

DECLARE @tariffId int, @xAvg int,
		@lastInsTariff int, @lastId int;
SELECT @lastInsTariff = -1;

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @xAvg = (@x0 + @x1) / 2;
	SELECT @tariffId = Lab_4.GetEffective(@xAvg);

	IF (@tariffId = @lastInsTariff)
	BEGIN
		SELECT @lastId = SCOPE_IDENTITY();
		UPDATE Lab_4.Periods
		SET Point_2=@x1
		WHERE Id=@tariffId;
	END
	ELSE
	BEGIN
		INSERT INTO Lab_4.Periods (Point_1, Point_2, EfTariffId)
		VALUES (@x0, @x1, @tariffId)
	END
	
	SELECT @x0 = @x1;
	SELECT @lastInsTariff = @tariffId;
	FETCH NEXT FROM cur1 
	INTO @x1
END
CLOSE cur1;
DEALLOCATE cur1;

SELECT * FROM Lab_4.Periods