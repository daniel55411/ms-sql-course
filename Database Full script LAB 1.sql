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
   WHERE name = N'Lab_1'
) 
 DROP SCHEMA Lab_1
GO

CREATE SCHEMA Lab_1 
GO

/*region Station*/
IF OBJECT_ID('[KB301_Zhenikhov].Lab_1.Station', 'U') IS NOT NULL
  DROP TABLE  [KB301_Zhenikhov].Lab_1.Station
GO

CREATE TABLE [KB301_Zhenikhov].Lab_1.Station
(
	Id tinyint, 
	Name nvarchar(40) NOT NULL, 
	Location nvarchar(40) NOT NULL, 
    CONSTRAINT PK_Station_Id PRIMARY KEY (Id) 
)
GO
/*endregion*/

/*region Measurement*/
IF OBJECT_ID('[KB301_Zhenikhov].Lab_1.Measurement', 'U') IS NOT NULL
  DROP TABLE  [KB301_Zhenikhov].Lab_1.Measurement
GO

CREATE TABLE [KB301_Zhenikhov].Lab_1.Measurement
(
	Id tinyint, 
	Name nvarchar(40) NOT NULL, 
	Unit nvarchar(40) NOT NULL, 
    CONSTRAINT PK_Measurement_Id PRIMARY KEY (Id) 
)
GO
/*endregion*/

/*region Info*/
IF OBJECT_ID('[KB301_Zhenikhov].Lab_1.Info', 'U') IS NOT NULL
  DROP TABLE  [KB301_Zhenikhov].Lab_1.Info
GO

CREATE TABLE [KB301_Zhenikhov].Lab_1.Info
(
	Measurement_time datetime,
	Station_id tinyint, 
	Measurement_id tinyint, 
	Value decimal(4, 1),
)
GO

ALTER TABLE [KB301_Zhenikhov].Lab_1.Info ADD 
	CONSTRAINT FK_Station_id FOREIGN KEY (Station_id) 
	REFERENCES [KB301_Zhenikhov].Lab_1.Station(id)
	ON UPDATE CASCADE
GO

ALTER TABLE [KB301_Zhenikhov].Lab_1.Info ADD 
	CONSTRAINT FK_Measurement_id FOREIGN KEY (Measurement_id) 
	REFERENCES [KB301_Zhenikhov].Lab_1.Measurement(id)
	ON UPDATE CASCADE
GO
/*endregion*/
GO
DELETE FROM Lab_1.Measurement
GO

GO
INSERT INTO Lab_1.Measurement
           (Id
           ,Name
           ,Unit)
     VALUES
           (1, 'Measurement_1', 'temperature'),
		   (2, 'Measurement_2', 'pressure'),
		   (3, 'Measurement_3', 'humidity')
GO

GO
DELETE FROM Lab_1.Station
GO

GO
INSERT INTO Lab_1.Station
           (Id
           ,Name
           ,Location)
     VALUES
           (1, 'Station_1', 'NY'),
		   (2, 'Station_2', 'California'),
		   (3, 'Station_3', 'Ekaterinburg')
GO

GO
DELETE FROM Lab_1.Info
GO

GO
INSERT INTO Lab_1.Info
           (Measurement_id,
		   Station_id,
		   Measurement_time,
		   Value)
     VALUES
           (1, 1, '05/02/17 11:12:13', 1.12),
		   (1, 1, '05/02/17 11:12:13', 2.13),
		   (1, 1, '05/02/17 11:12:13', 3.11),
		   (2, 2, '05/02/17 11:12:13', 1.12),
		   (2, 2, '05/02/17 11:12:13', 2.13),
		   (2, 2, '05/02/17 11:12:13', 3.11),
		   (3, 3, '04/07/17 11:12:13', 1.12),
		   (3, 3, '04/07/17 11:12:13', 2.13),
		   (3, 3, '04/07/17 11:12:13', 3.11),
		   (1, 1, '04/07/17 11:12:13', 0.1),
		   (1, 1, '04/07/17 11:12:13', 0.12),
		   (1, 3, '04/07/17 11:12:13', 0.19),
		   (2, 3, '04/07/17 11:12:13', 5.1),
		   (2, 2, '04/07/17 11:12:13', 111.12),
		   (2, 3, '09/05/18 11:12:13', 2.35),
		   (3, 1, '02/06/18 11:12:13', 1.12),
		   (3, 2, '03/07/18 11:12:13', 2.13),
		   (3, 3, '01/01/18 11:12:13', 3.11)
GO

SELECT FORMAT(CONVERT(date, I.Measurement_time), 'dd MMMM yy') as 'Date', M.Name as 'Type', S.Name as 'Station', CAST(AVG(I.Value) AS decimal(10, 1)) as 'Avg Value'
  FROM KB301_Zhenikhov.Lab_1.Info as I
  INNER JOIN KB301_Zhenikhov.Lab_1.Measurement as M ON M.Id = I.Measurement_id
  INNER JOIN KB301_Zhenikhov.Lab_1.Station as S ON S.Id = I.Station_id
  WHERE CONVERT(date, I.Measurement_time) = '04-07-2017'
  GROUP BY I.Measurement_id, FORMAT(CONVERT(date, I.Measurement_time), 'dd MMMM yy'), I.Station_id, M.Name, S.Name;