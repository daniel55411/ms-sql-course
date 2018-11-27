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
   WHERE name = N'Lab_3'
) 
 DROP SCHEMA Lab_3
GO

CREATE SCHEMA Lab_3 
GO

IF OBJECT_ID('KB301_Zhenikhov.Lab_3.ExchangeRates', 'U') IS NOT NULL
  DROP TABLE  KB301_Zhenikhov.Lab_3.ExchangeRates
GO

CREATE TABLE KB301_Zhenikhov.Lab_3.ExchangeRates
(
	SoldCurrencyId smallint,
	PurchasedCurrencyId smallint,
	Rate decimal(4, 2)
)
GO

IF OBJECT_ID('AddRate', 'TR') IS NOT NULL 
	DROP TRIGGER AddRate;
GO 

CREATE TRIGGER AddRate ON Lab_3.ExchangeRates
AFTER INSERT 
AS
	INSERT INTO Lab_3.ExchangeRates
	SELECT PurchasedCurrencyId, SoldCurrencyId, ROUND(1 / Rate, 2) FROM inserted
	WHERE PurchasedCurrencyId != SoldCurrencyId
GO

IF OBJECT_ID('CheckRate', 'TR') IS NOT NULL
	DROP TRIGGER CheckRate
GO

CREATE TRIGGER CheckRate ON Lab_3.ExchangeRates
INSTEAD OF INSERT
AS
	IF EXISTS(SELECT * FROM inserted 
	INNER JOIN Lab_3.ExchangeRates 
	ON inserted.PurchasedCurrencyId = Lab_3.ExchangeRates.PurchasedCurrencyId
	AND inserted.SoldCurrencyId = Lab_3.ExchangeRates.SoldCurrencyId)
	BEGIN
		RAISERROR ('Ñurrency pair exists', 16, 10);
	END

	INSERT INTO ExchangeRates
	SELECT * FROM inserted;
GO

IF OBJECT_ID('KB301_Zhenikhov.Lab_3.Currency', 'U') IS NOT NULL
  DROP TABLE  KB301_Zhenikhov.Lab_3.Currency
GO

CREATE TABLE KB301_Zhenikhov.Lab_3.Currency
(
	Id smallint identity(1, 1) primary key,
	Name varchar(3)
)
GO

IF OBJECT_ID('KB301_Zhenikhov.Lab_3.Purse', 'U') IS NOT NULL
	DROP TABLE KB301_Zhenikhov.Lab_3.Purse
GO

CREATE TABLE KB301_Zhenikhov.Lab_3.Purse
(
	CurrencyId smallint,
	Value smallmoney
)
GO

IF OBJECT_ID('CheckPurse', 'TR') IS NOT NULL
	DROP TRIGGER CheckPurse
GO

CREATE TRIGGER CheckPurse ON Lab_3.Purse
INSTEAD OF INSERT
AS
	IF EXISTS(SELECT * FROM inserted 
	INNER JOIN Lab_3.Purse 
	ON inserted.CurrencyId = Lab_3.Purse.CurrencyId)
	BEGIN
		RAISERROR ('Ñurrency in purse added', 16, 10);
	END

	INSERT INTO Purse
	SELECT * FROM inserted;
GO

IF OBJECT_ID('KB301_Zhenikhov.Lab_3.PutMoney', 'P') IS NOT NULL
  DROP TABLE  KB301_Zhenikhov.Lab_3.PutMoney
GO

CREATE PROC Lab_3.PutMoney 
	@CurrencyId smallint,
	@Value smallmoney
AS BEGIN
	UPDATE KB301_Zhenikhov.Lab_3.Purse
	SET Value = Value + @Value
	WHERE CurrencyId = @CurrencyId
END
GO

IF OBJECT_ID('KB301_Zhenikhov.Lab_3.GetMoney', 'P') IS NOT NULL
  DROP TABLE  KB301_Zhenikhov.Lab_3.GetMoney
GO

CREATE PROC Lab_3.GetMoney
	@CurrencyId smallint,
	@Value smallmoney
AS BEGIN
	IF EXISTS(SELECT * FROM KB301_Zhenikhov.Lab_3.Purse 
				WHERE CurrencyId = @CurrencyId AND Value >= @Value)
	BEGIN
		SET @Value = -@Value;
		EXEC KB301_Zhenikhov.Lab_3.PutMoney @CurrencyId, @Value;
	END
	ELSE 
	BEGIN
		RAISERROR('Not enough money in purse by that currency', 16, 10)
	END
END
GO

IF OBJECT_ID('KB301_Zhenikhov.Lab_3.EstimateCost', 'P') IS NOT NULL
  DROP TABLE  KB301_Zhenikhov.Lab_3.EstimateCost
GO

CREATE PROC Lab_3.EstimateCost
	@CurrencyId smallint
AS BEGIN
	SELECT ROUND(SUM(Value * er.Rate), 2) FROM KB301_Zhenikhov.Lab_3.Purse
	INNER JOIN KB301_Zhenikhov.Lab_3.ExchangeRates as er 
	ON Purse.CurrencyId = er.PurchasedCurrencyId AND er.SoldCurrencyId = @CurrencyId
END
GO

GO
DELETE FROM Lab_3.Currency
GO

GO
INSERT INTO Lab_3.Currency
           (Name)
     VALUES
           ('RUB'),
		   ('CNY'),
		   ('EUR')
GO

GO
DELETE FROM Lab_3.ExchangeRates
GO

GO
INSERT INTO Lab_3.ExchangeRates
           (SoldCurrencyId, PurchasedCurrencyId, Rate)
     VALUES
           (1, 1, 1.0),
		   (1, 2, 9.8),
		   (1, 3, 50.0),
		   (2, 2, 1.0),
		   (2, 3, 10.0),
		   (3, 3, 1.0)
GO

SELECT * FROM Lab_3.ExchangeRates;

BEGIN TRY  
     INSERT INTO Lab_3.ExchangeRates
           (SoldCurrencyId, PurchasedCurrencyId, Rate)
     VALUES
           (1, 2, 3.0)
END TRY  
BEGIN CATCH  
     PRINT('There was an error while adding an existing pair.')
END CATCH  

INSERT INTO Lab_3.Purse
			(CurrencyId, Value)
		VALUES
			(1, 0),
			(2, 0),
			(3, 0)
GO

SELECT * FROM Lab_3.Purse;

BEGIN TRY  
     INSERT INTO Lab_3.Purse
           (CurrencyId, Value)
     VALUES
           (1, 3.0)
END TRY  
BEGIN CATCH  
     PRINT(ERROR_MESSAGE())
END CATCH  

EXEC Lab_3.PutMoney 1, 100.4;
EXEC Lab_3.PutMoney 2, 31.2;
SELECT * FROM Lab_3.Purse;

EXEC Lab_3.GetMoney 1, 59.4;
EXEC Lab_3.GetMoney 2, 31.2;
SELECT * FROM Lab_3.Purse

BEGIN TRY  
     EXEC Lab_3.GetMoney 2, 31.2;
END TRY  
BEGIN CATCH  
     PRINT(ERROR_MESSAGE())
END CATCH  

BEGIN TRY  
     EXEC Lab_3.GetMoney 1, 50.0;
END TRY  
BEGIN CATCH  
     PRINT(ERROR_MESSAGE())
END CATCH  

EXEC Lab_3.PutMoney 2, 10.0;
EXEC Lab_3.PutMoney 3, 40.0;
EXEC Lab_3.EstimateCost 1;