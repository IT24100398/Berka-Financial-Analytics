/* =========================================================
   1. CREATE DATA MART SCHEMA
   ========================================================= */

IF NOT EXISTS
(
    SELECT *
    FROM sys.schemas
    WHERE name = 'Berka_DM'
)
BEGIN
    EXEC('CREATE SCHEMA Berka_DM');
END;
GO


/* =========================================================
   2. REMOVE EXISTING DATA MART TABLE
   ========================================================= */

IF OBJECT_ID('Berka_DM.BankingTransactionMart', 'U') IS NOT NULL
    DROP TABLE Berka_DM.BankingTransactionMart;
GO


/* =========================================================
   3. CREATE BANKING TRANSACTION DATA MART
   ========================================================= */

SELECT
    f.TransactionKey,
    f.TransactionID,

    d.FullDate,
    d.DayNumber,
    d.MonthNumber,
    d.MonthName,
    d.QuarterNumber,
    d.YearNumber,

    a.AccountID,
    a.Frequency,
    a.OpenDate,

    c.ClientID,
    c.Gender,
    c.BirthDate,

    dist.DistrictID,
    dist.DistrictName,
    dist.Region,
    dist.Population,
    dist.AverageSalary,
    dist.UnemploymentRate,

    tt.TransactionType,
    o.Operation,

    f.Amount,
    f.Balance,
    f.TransactionCount

INTO Berka_DM.BankingTransactionMart

FROM Berka_DW.FactTransaction f

INNER JOIN Berka_DW.DimDate d
    ON f.DateKey = d.DateKey

INNER JOIN Berka_DW.DimAccount a
    ON f.AccountKey = a.AccountKey

INNER JOIN Berka_DW.DimCustomer c
    ON f.CustomerKey = c.CustomerKey

INNER JOIN Berka_DW.DimDistrict dist
    ON f.DistrictKey = dist.DistrictKey

INNER JOIN Berka_DW.DimTransactionType tt
    ON f.TransactionTypeKey = tt.TransactionTypeKey

INNER JOIN Berka_DW.DimOperation o
    ON f.OperationKey = o.OperationKey;
GO

SELECT COUNT(*) AS DataMartRows
FROM Berka_DM.BankingTransactionMart;

SELECT TOP 20 *
FROM Berka_DM.BankingTransactionMart;

--
SELECT
    (SELECT COUNT(*)
     FROM Berka_DW.FactTransaction) AS DWRows,

    (SELECT COUNT(*)
     FROM Berka_DM.BankingTransactionMart) AS DataMartRows;