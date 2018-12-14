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
COLLATE SQL_Latin1_General_CP1251_CI_AS;
GO

USE KB301_Zhenikhov
GO

IF EXISTS(
  SELECT *
    FROM sys.schemas
   WHERE name = N'Lab_2'
) 
 DROP SCHEMA Lab_2
GO

CREATE SCHEMA Lab_2 
GO

IF OBJECT_ID('[KB301_Zhenikhov].Lab_2.Car', 'U') IS NOT NULL
  DROP TABLE  [KB301_Zhenikhov].Lab_2.Car
GO

CREATE TABLE [KB301_Zhenikhov].Lab_2.Car
(
	FullNumber varchar(9) CHECK (FullNumber LIKE '[А-Я][0-9][0-9][0-9][А-Я][А-Я][0-9][0-9]' 
								OR FullNumber LIKE '[А-Я][0-9][0-9][0-9][А-Я][А-Я][127][0-9][0-9]') PRIMARY KEY,
	Number AS SUBSTRING(FullNumber, 0,	6),
	Region AS SUBSTRING(FullNumber, 6, LEN(FullNumber) - 6),
)
GO

--IF OBJECT_ID('RegisterCar', 'TR') IS NOT NULL 
--	DROP TRIGGER EntryCar;
--GO

--CREATE TRIGGER RegisterCar ON [KB301_Zhenikhov].Lab_2.Car
--INSTEAD OF INSERT AS 
--BEGIN
--	RAISERROR('Private access to table', 16, 10)
--END

/*region KPP*/
IF OBJECT_ID('[KB301_Zhenikhov].Lab_2.KPP', 'U') IS NOT NULL
  DROP TABLE  [KB301_Zhenikhov].Lab_2.KPP
GO

CREATE TABLE [KB301_Zhenikhov].Lab_2.KPP
(
	TransitTime datetime,
	Number varchar(9) NOT NULL,
	Direction bit NOT NULL 
)
GO
/*endregion*/

IF OBJECT_ID('EntryCar', 'TR') IS NOT NULL 
	DROP TRIGGER EntryCar;
GO

CREATE TRIGGER EntryCar ON [KB301_Zhenikhov].Lab_2.KPP
INSTEAD OF INSERT AS 
BEGIN
	INSERT INTO [KB301_Zhenikhov].Lab_2.Car (FullNumber)
	SELECT Number FROM inserted
	EXCEPT 
	SELECT FullNumber FROM Lab_2.Car

	IF EXISTS(
	SELECT TOP 1 * FROM inserted 
	INNER JOIN Lab_2.KPP ON inserted.Number = Lab_2.KPP.Number
	ORDER BY inserted.TransitTime) 
	BEGIN
		RAISERROR('Car can not move in one direction twice', 16, 10)
	END

	INSERT INTO Lab_2.KPP
	SELECT * FROM inserted
END

/*region RegionSynonyms*/
IF OBJECT_ID('[KB301_Zhenikhov].Lab_2.RegionSynonym', 'U') IS NOT NULL
  DROP TABLE  [KB301_Zhenikhov].Lab_2.RegionSynonym
GO

CREATE TABLE [KB301_Zhenikhov].Lab_2.RegionSynonym
(
	Region smallint NOT NULL,
	Synonym smallint NOT NULL
)
GO
/*endregion*/

/*region Regions*/
IF OBJECT_ID('[KB301_Zhenikhov].Lab_2.Region', 'U') IS NOT NULL
  DROP TABLE  [KB301_Zhenikhov].Lab_2.Region
GO

CREATE TABLE [KB301_Zhenikhov].Lab_2.Region
(
	RegionName varchar(40) NOT NULL,
	RegionCode smallint NOT NULL
)
GO

/*endregion*/
GO
DELETE FROM Lab_2.Region
GO

GO
INSERT INTO Lab_2.Region
           (RegionCode , RegionName)
     VALUES
           (66, 'Свердловская область'),
		   (59, 'Пермский край'),
		   (23, 'Краснодарский край'),
		   (78, 'Санкт-петербург')
GO

GO
DELETE FROM Lab_2.RegionSynonym
GO

GO
INSERT INTO Lab_2.RegionSynonym
           (Region, Synonym)
     VALUES
           (66, 66),
		   (66, 96),
		   (66, 196),
		   (66, 196),
		   (78, 78),
		   (78, 98),
		   (78, 178),
		   (78, 198),
		   (78, 78),
		   (59, 59),
		   (59, 81),
		   (59, 159),
		   (23, 23),
		   (23, 123),
		   (23, 193)
GO

GO
DELETE FROM Lab_2.KPP
GO

GO
INSERT INTO Lab_2.KPP
           (TransitTime, Direction, Number)
     VALUES
           ('05/02/17 11:12:13', 0, 'И777ИИ77'),
		   ('05/02/17 11:12:13', 1, 'И777ИИ177'),
		   ('05/02/17 11:12:13', 0, 'И177ИИ277'),
		   ('05/02/17 12:12:13', 0, 'И277ИИ777'),
		   ('05/02/17 13:12:13', 0, 'И377ИИ77'),
		   ('05/02/17 14:12:13', 0, 'И477ИИ77')
GO

SELECT * FROM [KB301_Zhenikhov].Lab_2.KPP;
SELECT * FROM [KB301_Zhenikhov].Lab_2.Car;

BEGIN TRY
	INSERT INTO Lab_2.KPP
			   (TransitTime, Direction, Number)
		 VALUES
			   ('05/02/17 11:12:13', 0, 'И777ИИ77')
END TRY
BEGIN CATCH
	PRINT(ERROR_MESSAGE())
END CATCH

INSERT INTO Lab_2.KPP
	   (TransitTime, Direction, Number)
	VALUES
	   ('05/02/17 14:12:13', 1, 'И777ИИ77')

SELECT * FROM Lab_2.KPP WHERE Number='И777ИИ77';

INSERT INTO Lab_2.KPP
	   (TransitTime, Direction, Number)
	VALUES
	   ('06/02/17 14:12:13', 1, 'И277ИИ777'),
	   ('07/02/17 14:12:13', 0, 'И277ИИ777')

SELECT * FROM Lab_2.KPP;

