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
   WHERE name = N'Personal'
) 
 DROP SCHEMA Personal
GO

CREATE SCHEMA Personal 
GO

IF OBJECT_ID('KB301_Zhenikhov.Personal.Bidders', 'U') IS NOT NULL
  DROP TABLE  KB301_Zhenikhov.Personal.Bidders
GO

CREATE TABLE KB301_Zhenikhov.Personal.Bidders
(
	Id int identity(1, 1) primary key,
	FullName varchar(20),
	IsCompany bit
)
GO

IF OBJECT_ID('KB301_Zhenikhov.Personal.Auctions', 'U') IS NOT NULL
  DROP TABLE  KB301_Zhenikhov.Personal.Auctions
GO

CREATE TABLE KB301_Zhenikhov.Personal.Auctions
(
	Id int identity(1, 1) primary key,
	AuctionDate datetime,
	Place varchar(200),
	Descriptions varchar(200)
)
GO

IF OBJECT_ID('KB301_Zhenikhov.Personal.Products', 'U') IS NOT NULL
  DROP TABLE  KB301_Zhenikhov.Personal.Products
GO

CREATE TABLE KB301_Zhenikhov.Personal.Products
(
	Id int identity(1, 1) primary key,
	FullName varchar(20),
	SellerId int references Personal.Bidders (Id),
	Descriptions varchar(200)
)
GO

IF OBJECT_ID('KB301_Zhenikhov.Personal.Lots', 'U') IS NOT NULL
  DROP TABLE  KB301_Zhenikhov.Personal.Lots
GO

CREATE TABLE KB301_Zhenikhov.Personal.Lots
(
	AuctionId int references Personal.Auctions (Id),
	ProductId int references Personal.Products (Id),
	Number int,
	StartingPrice money
)
GO

IF OBJECT_ID('KB301_Zhenikhov.Personal.SoldLots', 'U') IS NOT NULL
  DROP TABLE  KB301_Zhenikhov.Personal.SoldLots
GO

CREATE TABLE KB301_Zhenikhov.Personal.SoldLots
(
	AuctionId int references Personal.Auctions (Id),
	LotNumber int references Personal.Products (Id),
	CustomerId int references Personal.Bidders( Id),
	FinalPrice money
)
GO

IF OBJECT_ID('AddSlots', 'TR') IS NOT NULL 
	DROP TRIGGER AddSlots;
GO

CREATE TRIGGER AddSlots ON Personal.Lots
INSTEAD OF INSERT AS 
BEGIN
	DECLARE @products TABLE(ProductId int, AuctionDate datetime)
	INSERT INTO @products
	SELECT I.ProductId, A.AuctionDate FROM inserted as I
	INNER JOIN Personal.Auctions as A ON A.Id = I.AuctionId

	IF EXISTS(SELECT * FROM @products as P 
	INNER JOIN Personal.Lots as L ON L.ProductId = P.ProductId
	INNER JOIN Personal.Auctions as A ON A.Id = L.AuctionId AND P.AuctionDate = A.AuctionDate)
	BEGIN
		RAISERROR('Products has already exposed on that time', 16, 10)
	END

	INSERT INTO Personal.Lots
	SELECT * FROM inserted
END
GO

INSERT INTO Personal.Bidders (FullName, IsCompany)
VALUES 
	('Daniil', 0),
	('OOO Au', 1),
	('Pirat', 0),
	('Vlad', 0),
	('OAO SkyForce', 1)
GO

INSERT INTO Personal.Auctions (AuctionDate, Place, Descriptions)
VALUES 
	('01/01/98 14:59:00', 'Sierra', 'Description 1'),	-- 1
	('01/01/98 14:59:00', 'Ekat', 'Description 2'),		-- 2
	('01/01/98 16:59:00', 'Sierra', 'Description 3'),	-- 3
	('01/01/98 16:59:00', 'Ekat', 'Description 4'),		-- 4
	('01/02/98 16:59:00', 'Sierra', 'Description 5'),	-- 5
	('01/02/98 16:59:00', 'Ekat', 'Description 6'),		-- 6
	('02/01/98 16:40:00', 'Sierra', 'Description 7'),	-- 7
	('02/01/98 16:59:00', 'Ekat', 'Description 8')		-- 8
GO

INSERT INTO Personal.Products (FullName, SellerId, Descriptions)
VALUES
	('Product 1 1', 1, 'Description 1 1'), -- 1
	('Product 1 2', 1, 'Description 1 2'), -- 2
	('Product 1 3', 1, 'Description 1 3'), -- 3
	('Product 2 1', 2, 'Description 2 1'), -- 4
	('Product 2 2', 2, 'Description 2 2'), -- 5
	('Product 2 3', 2, 'Description 2 3'), -- 6
	('Product 2 4', 2, 'Description 2 4'), -- 7
	('Product 2 5', 2, 'Description 2 5'), -- 8
	('Product 3 1', 3, 'Description 3 1'), -- 9
	('Product 3 2', 3, 'Description 3 2'), -- 10
	('Product 3 3', 3, 'Description 3 3'), -- 11
	('Product 3 4', 3, 'Description 3 4'), -- 12
	('Product 4 1', 4, 'Description 4 1'), -- 13
	('Product 4 2', 4, 'Description 4 2'), -- 14
	('Product 4 3', 4, 'Description 4 3'), -- 15
	('Product 4 4', 4, 'Description 4 4'), -- 16
	('Product 5 1', 5, 'Description 5 1'), -- 17
	('Product 5 2', 5, 'Description 5 2')  -- 18
GO

INSERT INTO Personal.Lots (AuctionId, ProductId, Number, StartingPrice)
VALUES
	(1, 1, 1, 220.0),
	(1, 4, 2, 1000.0),
	(1, 9, 3, 500.0),
	(1, 18, 4, 2222.0),
	(1, 17, 5, 2301.2),
	(2, 2, 1, 10.0),
	(2, 3, 2, 35.9),
	(2, 14, 3, 800.0),
	(3, 5, 1, 1220.0),
	(3, 1, 2, 12320.0),
	(3, 15, 3, 600.0),
	(3, 16, 4, 771.0),
	(4, 15, 1, 700.0),
	(4, 16, 2, 980.0),
	(5, 10, 1, 220.0),
	(6, 1, 1, 10.0),
	(6, 6, 2, 20.0),
	(6, 7, 3, 30.0),
	(6, 13, 4, 40.0),
	(6, 11, 5, 50.0),
	(7, 8, 1, 130.0),
	(7, 12, 2, 410.0),
	(7, 13, 3, 20.0),
	(8, 1, 1, 220.0),
	(8, 5, 2, 220.0),
	(8, 9, 3, 220.0),
	(8, 15, 4, 220.0)
GO

INSERT INTO Personal.SoldLots (AuctionId, CustomerId, LotNumber, FinalPrice)
VALUES
	(1, 2, 1, 230.0),	-- 1
	(1, 3, 3, 560.0),	-- 9
	(1, 4, 5, 3301.2),	-- 17
	(2, 5, 1, 11.0),	-- 2
	(2, 1, 2, 36.9),	-- 3
	(2, 2, 3, 900.0),	-- 14
	(3, 4, 3, 640.0),	-- 15
	(3, 5, 4, 779.0),	-- 16
	(5, 1, 1, 250.0),	-- 10
	(6, 3, 2, 200.0),	-- 6
	(7, 5, 1, 170.0),	-- 8
	(7, 1, 2, 510.0),	-- 12
	(7, 2, 3, 200.0),	-- 13
	(8, 2, 2, 223.0)	-- 5
GO

BEGIN TRY
	INSERT INTO Personal.Lots (AuctionId, ProductId, Number, StartingPrice)
	VALUES (2, 1, 10, 220.0)
END TRY
BEGIN CATCH
	PRINT(ERROR_MESSAGE())
END CATCH
GO

BEGIN TRY
	INSERT INTO Personal.Lots (AuctionId, ProductId, Number, StartingPrice)
	VALUES (7, 1, 10, 220.0)
	DELETE FROM Personal.Lots WHERE AuctionId = 7 AND Number = 10;
END TRY
BEGIN CATCH
	PRINT(ERROR_MESSAGE())
END CATCH
GO

DECLARE @date_1 datetime, @date_2 datetime, @place varchar(200);
SET @date_1 = '01/01/98 11:59:00'
SET @date_2 = '01/02/98 11:59:00'
SET @place = 'Sierra'

-- 1 query
SELECT A.Id, SUM(S.FinalPrice) as Income FROM Personal.Auctions as A
INNER JOIN Personal.SoldLots as S ON A.Id = S.AuctionId
GROUP BY A.Id
ORDER BY Income

---- 2 query 
DECLARE @result TABLE(ProductId int);

INSERT INTO @result
SELECT L.ProductId FROM Personal.SoldLots as S
INNER JOIN Personal.Lots as L ON S.AuctionId = L.AuctionId AND S.LotNumber = L.Number
INNER JOIN Personal.Auctions as A ON A.Id = S.AuctionId
WHERE A.AuctionDate >= @date_1 AND A.AuctionDate <= @date_2

SELECT P.FullName, L.AuctionId FROM @result as R
INNER JOIN Personal.Lots as L ON L.ProductId = R.ProductId
INNER JOIN Personal.Products as P ON P.Id = R.ProductId
ORDER BY P.FullName

---- 3 query
SELECT B.FullName, SUM(S.FinalPrice) as Income FROM Personal.SoldLots as S
INNER JOIN Personal.Lots as L ON S.AuctionId = L.AuctionId AND S.LotNumber = L.Number
INNER JOIN Personal.Products as P ON P.Id = L.ProductId
INNER JOIN Personal.Bidders as B ON B.Id = P.SellerId
INNER JOIN Personal.Auctions as A ON A.Id = L.AuctionId
WHERE A.AuctionDate >= @date_1 AND A.AuctionDate <= @date_2
GROUP BY P.SellerId, B.FullName
ORDER BY Income DESC

---- 4 query
SELECT A.Id, COUNT(A.Id) as SoldCount FROM Personal.Auctions as A
INNER JOIN Personal.SoldLots as S ON S.AuctionId = A.Id
WHERE A.Place = @place
GROUP BY A.Id
ORDER BY SoldCount

---- 5 query 
SELECT B.FullName, P.FullName FROM Personal.Lots as L
INNER JOIN Personal.Auctions as A ON A.Id = L.AuctionId
INNER JOIN Personal.Products as P ON P.Id = L.ProductId
INNER JOIN Personal.Bidders as B ON B.Id = P.SellerId
WHERE A.AuctionDate >= @date_1 AND A.AuctionDate <= @date_2
ORDER BY B.Id

---- 6 query
SELECT B.FullName, COUNT(B.Id) as CustomersCount FROM Personal.SoldLots as S
INNER JOIN Personal.Auctions as A ON A.Id = S.AuctionId
INNER JOIN Personal.Bidders as B ON B.Id = S.CustomerId
WHERE A.AuctionDate >= @date_1 AND A.AuctionDate <= @date_2
GROUP BY B.Id, B.FullName