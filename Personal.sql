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

IF OBJECT_ID('KB301_Zhenikhov.Personal.AddSlots', 'TR') IS NOT NULL 
	DROP TRIGGER KB301_Zhenikhov.Personal.AddSlots;
GO

CREATE TRIGGER KB301_Zhenikhov.Personal.AddSlots ON Personal.Lots
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
	DEALLOCATE @products
END

DECLARE @date_1 datetime, @date_2 datetime, @place varchar(200);
-- SET @date_1 = ...
-- SET @date_2 = ...
-- SET @place = ...

-- 1 query
SELECT A.Id, SUM(S.FinalPrice) as Income FROM Personal.Auctions as A
INNER JOIN Personal.SoldLots as S ON A.Id = S.AuctionId
ORDER BY Income

-- 2 query 
DECLARE @result TABLE(ProductId int);

INSERT INTO @result
SELECT L.ProductId FROM Personal.SoldLots as S
INNER JOIN Personal.Lots as L ON S.AuctionId = L.AuctionId AND S.LotNumber = L.Number
INNER JOIN Personal.Auctions as A ON A.Id = S.AuctionId
WHERE A.AuctionDate >= @date_1 AND A.AuctionDate <= @date_2

SELECT P.FullName, L.AuctionId FROM @result as R
INNER JOIN Personal.Lots as L ON L.ProductId = R.ProductId
INNER JOIN Personal.Products as P ON P.Id = R.ProductId

-- 3 query
SELECT B.FullName, SUM(S.FinalPrice) as Income FROM Personal.SoldLots as S
INNER JOIN Personal.Lots as L ON S.AuctionId = L.AuctionId AND S.LotNumber = L.Number
INNER JOIN Personal.Products as P ON P.Id = L.ProductId
INNER JOIN Personal.Bidders as B ON B.Id = P.SellerId
GROUP BY P.SellerId
ORDER BY Income

-- 4 query
SELECT A.Id, COUNT(A.Id) as SoldCount FROM Personal.Auctions as A
INNER JOIN Personal.SoldLots as S ON S.AuctionId = A.Id
GROUP BY A.Id
ORDER BY SoldCount

-- 5 query 
SELECT B.FullName, P.FullName FROM Personal.Lots as L
INNER JOIN Personal.Auctions as A ON A.Id = L.AuctionId
INNER JOIN Personal.Products as P ON P.Id = L.ProductId
INNER JOIN Personal.Bidders as B ON B.Id = P.SellerId
WHERE A.AuctionDate >= @date_1 AND A.AuctionDate <= @date_2
ORDER BY B.Id

-- 6 query
SELECT B.FullName, COUNT(B.Id) as CustomersCount FROM Personal.SoldLots as S
INNER JOIN Personal.Auctions as A ON A.Id = S.AuctionId
INNER JOIN Personal.Bidders as B ON B.Id = S.CustomerId
WHERE A.AuctionDate >= @date_1 AND A.AuctionDate <= @date_2
GROUP BY B.Id