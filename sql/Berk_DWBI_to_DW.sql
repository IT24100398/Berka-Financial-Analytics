/* =========================================================
   EXPORT: Berka_DWBI  →  Berka_DW
   Only: Dimension tables + Fact + Data Mart
   ========================================================= */

USE master;
GO

-- 1. Create target database (drop if you want a clean rebuild)
IF DB_ID('Berka_DW') IS NOT NULL
BEGIN
    ALTER DATABASE Berka_DW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Berka_DW;
END
GO

CREATE DATABASE Berka_DW;
GO

USE Berka_DW;
GO

-- 2. Create schemas
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Berka_DW')
    EXEC('CREATE SCHEMA Berka_DW');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Berka_DM')
    EXEC('CREATE SCHEMA Berka_DM');
GO

/* ---------------------------------------------------------
   3. Copy Dimension tables (structure + data)
   --------------------------------------------------------- */

-- DimDate
SELECT * INTO Berka_DW.DimDate
FROM Berka_DWBI.Berka_DW.DimDate;
GO

-- DimAccount
SELECT * INTO Berka_DW.DimAccount
FROM Berka_DWBI.Berka_DW.DimAccount;
GO

-- DimCustomer
SELECT * INTO Berka_DW.DimCustomer
FROM Berka_DWBI.Berka_DW.DimCustomer;
GO

-- DimDistrict
SELECT * INTO Berka_DW.DimDistrict
FROM Berka_DWBI.Berka_DW.DimDistrict;
GO

-- DimTransactionType
SELECT * INTO Berka_DW.DimTransactionType
FROM Berka_DWBI.Berka_DW.DimTransactionType;
GO

-- DimOperation
SELECT * INTO Berka_DW.DimOperation
FROM Berka_DWBI.Berka_DW.DimOperation;
GO

/* ---------------------------------------------------------
   4. Copy Fact table
   --------------------------------------------------------- */
SELECT * INTO Berka_DW.FactTransaction
FROM Berka_DWBI.Berka_DW.FactTransaction;
GO

/* ---------------------------------------------------------
   5. Copy Data Mart
   --------------------------------------------------------- */
SELECT * INTO Berka_DM.BankingTransactionMart
FROM Berka_DWBI.Berka_DM.BankingTransactionMart;
GO

/* ---------------------------------------------------------
   6. Recreate Primary Keys (SELECT INTO does not copy PKs)
   --------------------------------------------------------- */
ALTER TABLE Berka_DW.DimDate
    ADD CONSTRAINT PK_DimDate PRIMARY KEY (DateKey);
GO

ALTER TABLE Berka_DW.DimAccount
    ADD CONSTRAINT PK_DimAccount PRIMARY KEY (AccountKey);
GO

ALTER TABLE Berka_DW.DimCustomer
    ADD CONSTRAINT PK_DimCustomer PRIMARY KEY (CustomerKey);
GO

ALTER TABLE Berka_DW.DimDistrict
    ADD CONSTRAINT PK_DimDistrict PRIMARY KEY (DistrictKey);
GO

ALTER TABLE Berka_DW.DimTransactionType
    ADD CONSTRAINT PK_DimTransactionType PRIMARY KEY (TransactionTypeKey);
GO

ALTER TABLE Berka_DW.DimOperation
    ADD CONSTRAINT PK_DimOperation PRIMARY KEY (OperationKey);
GO

ALTER TABLE Berka_DW.FactTransaction
    ADD CONSTRAINT PK_FactTransaction PRIMARY KEY (TransactionKey);
GO

/* ---------------------------------------------------------
   7. Recreate Foreign Keys
   --------------------------------------------------------- */
ALTER TABLE Berka_DW.FactTransaction
ADD CONSTRAINT FK_Fact_DimDate
FOREIGN KEY (DateKey) REFERENCES Berka_DW.DimDate(DateKey);
GO

ALTER TABLE Berka_DW.FactTransaction
ADD CONSTRAINT FK_Fact_DimAccount
FOREIGN KEY (AccountKey) REFERENCES Berka_DW.DimAccount(AccountKey);
GO

ALTER TABLE Berka_DW.FactTransaction
ADD CONSTRAINT FK_Fact_DimCustomer
FOREIGN KEY (CustomerKey) REFERENCES Berka_DW.DimCustomer(CustomerKey);
GO

ALTER TABLE Berka_DW.FactTransaction
ADD CONSTRAINT FK_Fact_DimDistrict
FOREIGN KEY (DistrictKey) REFERENCES Berka_DW.DimDistrict(DistrictKey);
GO

ALTER TABLE Berka_DW.FactTransaction
ADD CONSTRAINT FK_Fact_DimTransactionType
FOREIGN KEY (TransactionTypeKey) REFERENCES Berka_DW.DimTransactionType(TransactionTypeKey);
GO

ALTER TABLE Berka_DW.FactTransaction
ADD CONSTRAINT FK_Fact_DimOperation
FOREIGN KEY (OperationKey) REFERENCES Berka_DW.DimOperation(OperationKey);
GO

/* ---------------------------------------------------------
   8. Useful indexes for analytics
   --------------------------------------------------------- */
CREATE INDEX IX_Fact_DateKey            ON Berka_DW.FactTransaction(DateKey);
CREATE INDEX IX_Fact_AccountKey         ON Berka_DW.FactTransaction(AccountKey);
CREATE INDEX IX_Fact_CustomerKey        ON Berka_DW.FactTransaction(CustomerKey);
CREATE INDEX IX_Fact_DistrictKey        ON Berka_DW.FactTransaction(DistrictKey);
CREATE INDEX IX_Fact_TransactionTypeKey ON Berka_DW.FactTransaction(TransactionTypeKey);
CREATE INDEX IX_Fact_OperationKey       ON Berka_DW.FactTransaction(OperationKey);
GO

/* ---------------------------------------------------------
   9. Validation
   --------------------------------------------------------- */
SELECT 'DimDate'            AS TableName, COUNT(*) AS Rows FROM Berka_DW.DimDate
UNION ALL SELECT 'DimAccount',            COUNT(*) FROM Berka_DW.DimAccount
UNION ALL SELECT 'DimCustomer',           COUNT(*) FROM Berka_DW.DimCustomer
UNION ALL SELECT 'DimDistrict',           COUNT(*) FROM Berka_DW.DimDistrict
UNION ALL SELECT 'DimTransactionType',    COUNT(*) FROM Berka_DW.DimTransactionType
UNION ALL SELECT 'DimOperation',          COUNT(*) FROM Berka_DW.DimOperation
UNION ALL SELECT 'FactTransaction',       COUNT(*) FROM Berka_DW.FactTransaction
UNION ALL SELECT 'BankingTransactionMart',COUNT(*) FROM Berka_DM.BankingTransactionMart;
GO