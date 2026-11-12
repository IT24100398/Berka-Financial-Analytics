--  USE DATABASE

USE Berka_DWBI;
GO


  -- CREATE Berka_DW SCHEMA

IF NOT EXISTS
(
    SELECT *
    FROM sys.schemas
    WHERE name = 'Berka_DW'
)
BEGIN
    EXEC('CREATE SCHEMA Berka_DW');
END;
GO


   -- DROP EXISTING TABLES
   --Drop Fact first because of Foreign Keys

IF OBJECT_ID('Berka_DW.FactTransaction', 'U') IS NOT NULL
    DROP TABLE Berka_DW.FactTransaction;
GO

IF OBJECT_ID('Berka_DW.DimOperation', 'U') IS NOT NULL
    DROP TABLE Berka_DW.DimOperation;
GO

IF OBJECT_ID('Berka_DW.DimTransactionType', 'U') IS NOT NULL
    DROP TABLE Berka_DW.DimTransactionType;
GO

IF OBJECT_ID('Berka_DW.DimDistrict', 'U') IS NOT NULL
    DROP TABLE Berka_DW.DimDistrict;
GO

IF OBJECT_ID('Berka_DW.DimCustomer', 'U') IS NOT NULL
    DROP TABLE Berka_DW.DimCustomer;
GO

IF OBJECT_ID('Berka_DW.DimAccount', 'U') IS NOT NULL
    DROP TABLE Berka_DW.DimAccount;
GO

IF OBJECT_ID('Berka_DW.DimDate', 'U') IS NOT NULL
    DROP TABLE Berka_DW.DimDate;
GO


-- CREATE DIMENSION TABLES


   -- 4.1 DimDate

CREATE TABLE Berka_DW.DimDate
(
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    DayNumber INT NOT NULL,
    MonthNumber INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    QuarterNumber INT NOT NULL,
    YearNumber INT NOT NULL
);
GO


--   4.2 DimAccount

CREATE TABLE Berka_DW.DimAccount
(
    AccountKey INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT NOT NULL,
    Frequency VARCHAR(50),
    OpenDate DATE,
    DistrictID INT
);
GO


--   4.3 DimCustomer

CREATE TABLE Berka_DW.DimCustomer
(
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    ClientID INT NOT NULL,
    BirthDate DATE,
    Gender VARCHAR(20),
    DistrictID INT
);
GO


--  4.4 DimDistrict
   
CREATE TABLE Berka_DW.DimDistrict
(
    DistrictKey INT IDENTITY(1,1) PRIMARY KEY,
    DistrictID INT NOT NULL,
    DistrictName VARCHAR(100),
    Region VARCHAR(100),
    Population INT,
    AverageSalary DECIMAL(10,2),
    UnemploymentRate DECIMAL(10,2)
);
GO


--   4.5 DimTransactionType

CREATE TABLE Berka_DW.DimTransactionType
(
    TransactionTypeKey INT IDENTITY(1,1) PRIMARY KEY,
    TransactionType VARCHAR(50) NOT NULL
);
GO


--    4.6 DimOperation

CREATE TABLE Berka_DW.DimOperation
(
    OperationKey INT IDENTITY(1,1) PRIMARY KEY,
    Operation VARCHAR(100) NOT NULL
);
GO


  -- 5. CREATE FACT TABLE

CREATE TABLE Berka_DW.FactTransaction
(
    TransactionKey INT IDENTITY(1,1) PRIMARY KEY,

    TransactionID INT NOT NULL,

    DateKey INT NOT NULL,
    AccountKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    DistrictKey INT NOT NULL,
    TransactionTypeKey INT NOT NULL,
    OperationKey INT NOT NULL,

    Amount DECIMAL(18,2),
    Balance DECIMAL(18,2),

    TransactionCount INT NOT NULL
);
GO


--   6. CREATE FOREIGN KEYS

ALTER TABLE Berka_DW.FactTransaction
ADD CONSTRAINT FK_FactTransaction_DimDate
FOREIGN KEY (DateKey)
REFERENCES Berka_DW.DimDate(DateKey);
GO


ALTER TABLE Berka_DW.FactTransaction
ADD CONSTRAINT FK_FactTransaction_DimAccount
FOREIGN KEY (AccountKey)
REFERENCES Berka_DW.DimAccount(AccountKey);
GO


ALTER TABLE Berka_DW.FactTransaction
ADD CONSTRAINT FK_FactTransaction_DimCustomer
FOREIGN KEY (CustomerKey)
REFERENCES Berka_DW.DimCustomer(CustomerKey);
GO


ALTER TABLE Berka_DW.FactTransaction
ADD CONSTRAINT FK_FactTransaction_DimDistrict
FOREIGN KEY (DistrictKey)
REFERENCES Berka_DW.DimDistrict(DistrictKey);
GO


ALTER TABLE Berka_DW.FactTransaction
ADD CONSTRAINT FK_FactTransaction_DimTransactionType
FOREIGN KEY (TransactionTypeKey)
REFERENCES Berka_DW.DimTransactionType(TransactionTypeKey);
GO


ALTER TABLE Berka_DW.FactTransaction
ADD CONSTRAINT FK_FactTransaction_DimOperation
FOREIGN KEY (OperationKey)
REFERENCES Berka_DW.DimOperation(OperationKey);
GO


--   7. LOAD DimDate
  -- Source transaction dates are YYMMDD.
   -- Berka dates are from the 1990s.

;WITH DateList AS
(
    SELECT CAST('1993-01-01' AS DATE) AS FullDate

    UNION ALL

    SELECT DATEADD(DAY, 1, FullDate)
    FROM DateList
    WHERE FullDate < '1998-12-31'
)
INSERT INTO Berka_DW.DimDate
(
    DateKey,
    FullDate,
    DayNumber,
    MonthNumber,
    MonthName,
    QuarterNumber,
    YearNumber
)
SELECT
    YEAR(FullDate) * 10000
        + MONTH(FullDate) * 100
        + DAY(FullDate),

    FullDate,

    DAY(FullDate),

    MONTH(FullDate),

    DATENAME(MONTH, FullDate),

    DATEPART(QUARTER, FullDate),

    YEAR(FullDate)
FROM DateList
OPTION (MAXRECURSION 0);
GO


--   8. VALIDATE DimDate

SELECT
    COUNT(*) AS DateRows,
    MIN(FullDate) AS MinimumDate,
    MAX(FullDate) AS MaximumDate
FROM Berka_DW.DimDate;
GO


--   9. LOAD DimAccount

INSERT INTO Berka_DW.DimAccount
(
    AccountID,
    Frequency,
    OpenDate,
    DistrictID
)
SELECT
    account_id,
    frequency,

    DATEFROMPARTS
    (
        1900 + CAST([date] AS INT) / 10000,
        (CAST([date] AS INT) / 100) % 100,
        CAST([date] AS INT) % 100
    ) AS OpenDate,

    district_id

FROM dbo.ACCOUNTS;
GO


--   10. VALIDATE DimAccount

SELECT
    COUNT(*) AS AccountRows
FROM Berka_DW.DimAccount;
GO


SELECT TOP 20
    AccountKey,
    AccountID,
    Frequency,
    OpenDate,
    DistrictID
FROM Berka_DW.DimAccount
ORDER BY AccountID;
GO


--   11. LOAD DimCustomer
  -- birth_number format = YYMMDD

   --Example:
   --450204 = 1945-02-04

  -- Female month:
   --50 is added to the month.

   -- Example:
     -- 505204 = 1950-02-04

INSERT INTO Berka_DW.DimCustomer
(
    ClientID,
    BirthDate,
    Gender,
    DistrictID
)
SELECT
    client_id,

    DATEFROMPARTS
    (
        1900 + CAST(birth_number AS INT) / 10000,

        CASE
            WHEN
                ((CAST(birth_number AS INT) / 100) % 100) > 50
            THEN
                ((CAST(birth_number AS INT) / 100) % 100) - 50
            ELSE
                ((CAST(birth_number AS INT) / 100) % 100)
        END,

        CAST(birth_number AS INT) % 100
    ) AS BirthDate,

    CASE
        WHEN
            ((CAST(birth_number AS INT) / 100) % 100) > 50
        THEN 'Female'
        ELSE 'Male'
    END AS Gender,

    district_id

FROM dbo.CLIENTS;
GO


--   12. VALIDATE DimCustomer

SELECT
    COUNT(*) AS CustomerRows
FROM Berka_DW.DimCustomer;
GO


SELECT TOP 20
    ClientID,
    BirthDate,
    Gender,
    DistrictID
FROM Berka_DW.DimCustomer
ORDER BY ClientID;
GO


/* Check for incorrect future birth dates */

SELECT
    COUNT(*) AS FutureBirthDates
FROM Berka_DW.DimCustomer
WHERE BirthDate > GETDATE();
GO


/* =========================================================
   13. LOAD DimDistrict
   A12 contains '?' for some records.
   TRY_CONVERT changes '?' to NULL.
   ========================================================= */

INSERT INTO Berka_DW.DimDistrict
(
    DistrictID,
    DistrictName,
    Region,
    Population,
    AverageSalary,
    UnemploymentRate
)
SELECT
    A1,
    A2,
    A3,
    A4,
    A11,

    TRY_CONVERT
    (
        DECIMAL(10,2),
        A12
    )

FROM dbo.DISTRICT;
GO


/* =========================================================
   14. VALIDATE DimDistrict
   ========================================================= */

SELECT
    COUNT(*) AS DistrictRows
FROM Berka_DW.DimDistrict;
GO


SELECT TOP 20
    DistrictKey,
    DistrictID,
    DistrictName,
    Region,
    Population,
    AverageSalary,
    UnemploymentRate
FROM Berka_DW.DimDistrict
ORDER BY DistrictID;
GO


/* Check NULL unemployment values */

SELECT
    COUNT(*) AS NullUnemploymentRate
FROM Berka_DW.DimDistrict
WHERE UnemploymentRate IS NULL;
GO


/* =========================================================
   15. LOAD DimTransactionType
   ========================================================= */

INSERT INTO Berka_DW.DimTransactionType
(
    TransactionType
)
SELECT DISTINCT
    type
FROM dbo.TRANS
WHERE type IS NOT NULL;
GO


/* =========================================================
   16. VALIDATE DimTransactionType
   ========================================================= */

SELECT *
FROM Berka_DW.DimTransactionType
ORDER BY TransactionTypeKey;
GO


/* =========================================================
   17. LOAD DimOperation
   ========================================================= */

INSERT INTO Berka_DW.DimOperation
(
    Operation
)
SELECT DISTINCT
    operation
FROM dbo.TRANS
WHERE operation IS NOT NULL;
GO


/* Add Unknown member.
   Required because some transactions
   have NULL operation values.
   */

INSERT INTO Berka_DW.DimOperation
(
    Operation
)
VALUES
(
    'Unknown'
);
GO


/* =========================================================
   18. VALIDATE DimOperation
   ========================================================= */

SELECT *
FROM Berka_DW.DimOperation
ORDER BY OperationKey;
GO


/* =========================================================
   19. CHECK TRANSACTIONS WITHOUT ACCOUNT OWNER

   CustomerKey is obtained through:

   TRANS
      -> ACCOUNT
      -> DISP
      -> CLIENT

   DISP.type = 'OWNER'
   ========================================================= */

SELECT
    COUNT(*) AS TransactionsWithoutOwner
FROM dbo.TRANS t
LEFT JOIN dbo.DISP d
    ON t.account_id = d.account_id
   AND d.type = 'OWNER'
WHERE d.account_id IS NULL;
GO


/* =========================================================
   20. CHECK ACCOUNTS WITHOUT OWNER
   ========================================================= */

SELECT
    COUNT(*) AS AccountsWithoutOwner
FROM dbo.ACCOUNTS a
LEFT JOIN dbo.DISP d
    ON a.account_id = d.account_id
   AND d.type = 'OWNER'
WHERE d.account_id IS NULL;
GO


/* =========================================================
   21. CHECK FOR MULTIPLE OWNERS PER ACCOUNT

   Important because multiple OWNER rows
   could duplicate fact records.
   ========================================================= */

SELECT
    account_id,
    COUNT(*) AS OwnerCount
FROM dbo.DISP
WHERE type = 'OWNER'
GROUP BY account_id
HAVING COUNT(*) > 1;
GO


/* =========================================================
   22. PRE-LOAD TRANSACTION COMPLETENESS CHECK
   ========================================================= */

SELECT

    (
        SELECT COUNT(*)
        FROM dbo.TRANS
    ) AS SourceCount,

    (
        SELECT COUNT(*)
        FROM dbo.TRANS t
        INNER JOIN dbo.DISP d
            ON t.account_id = d.account_id
           AND d.type = 'OWNER'
    ) AS TransactionsWithOwner,

    (
        SELECT COUNT(*)
        FROM dbo.TRANS
        WHERE operation IS NULL
    ) AS NullOperationCount;
GO


/* =========================================================
   23. LOAD FactTransaction

   IMPORTANT:
   - All transactions are retained.
   - NULL operation -> Unknown.
   - Customer is linked through account OWNER.
   - No WHERE operation IS NOT NULL condition.
   ========================================================= */
INSERT INTO Berka_DW.FactTransaction
(
    TransactionID,
    DateKey,
    AccountKey,
    CustomerKey,
    DistrictKey,
    TransactionTypeKey,
    OperationKey,
    Amount,
    Balance,
    TransactionCount
)
SELECT
    t.trans_id,

    dd.DateKey,

    da.AccountKey,

    dc.CustomerKey,

    ddist.DistrictKey,

    dtt.TransactionTypeKey,

    ISNULL(
        dop.OperationKey,
        unk.OperationKey
    ) AS OperationKey,

    CAST(t.amount AS DECIMAL(18,2)) AS Amount,

    CAST(t.balance AS DECIMAL(18,2)) AS Balance,

    1 AS TransactionCount

FROM dbo.TRANS AS t

INNER JOIN Berka_DW.DimDate AS dd
    ON dd.FullDate =
        DATEFROMPARTS
        (
            1900 + CAST(t.[date] AS INT) / 10000,
            (CAST(t.[date] AS INT) / 100) % 100,
            CAST(t.[date] AS INT) % 100
        )

INNER JOIN Berka_DW.DimAccount AS da
    ON da.AccountID = t.account_id

INNER JOIN dbo.ACCOUNTS AS a
    ON a.account_id = t.account_id

INNER JOIN dbo.DISP AS disp
    ON disp.account_id = t.account_id
   AND disp.type = 'OWNER'

INNER JOIN Berka_DW.DimCustomer AS dc
    ON dc.ClientID = disp.client_id

INNER JOIN Berka_DW.DimDistrict AS ddist
    ON ddist.DistrictID = a.district_id

INNER JOIN Berka_DW.DimTransactionType AS dtt
    ON dtt.TransactionType = t.type

LEFT JOIN Berka_DW.DimOperation AS dop
    ON dop.Operation = t.operation

CROSS JOIN
(
    SELECT OperationKey
    FROM Berka_DW.DimOperation
    WHERE Operation = 'Unknown'
) AS unk;

GO


/* ---------------------------------------------------------
   Match transaction date
   --------------------------------------------------------- */

INNER JOIN Berka_DW.DimDate dd
    ON dd.FullDate =
        DATEFROMPARTS
        (
            1900 + CAST(t.[date] AS INT) / 10000,

            (CAST(t.[date] AS INT) / 100) % 100,

            CAST(t.[date] AS INT) % 100
        )


/* ---------------------------------------------------------
   Match account
   --------------------------------------------------------- */

INNER JOIN Berka_DW.DimAccount da
    ON da.AccountID = t.account_id


/* ---------------------------------------------------------
   Get account district
   --------------------------------------------------------- */

INNER JOIN dbo.ACCOUNTS a
    ON a.account_id = t.account_id


/* ---------------------------------------------------------
   Get account owner
   --------------------------------------------------------- */

INNER JOIN dbo.DISP disp
    ON disp.account_id = t.account_id
   AND disp.type = 'OWNER'


/* ---------------------------------------------------------
   Match customer
   --------------------------------------------------------- */

INNER JOIN Berka_DW.DimCustomer dc
    ON dc.ClientID = disp.client_id


/* ---------------------------------------------------------
   Match district
   --------------------------------------------------------- */

INNER JOIN Berka_DW.DimDistrict ddist
    ON ddist.DistrictID = a.district_id


/* ---------------------------------------------------------
   Match transaction type
   --------------------------------------------------------- */

INNER JOIN Berka_DW.DimTransactionType dtt
    ON dtt.TransactionType = t.type


/* ---------------------------------------------------------
   Operation is LEFT JOIN because operation can be NULL
   --------------------------------------------------------- */

LEFT JOIN Berka_DW.DimOperation dop
    ON dop.Operation = t.operation;
GO


/* =========================================================
   24. CHECK SOURCE VS FACT COUNT
   ========================================================= */

SELECT

    (
        SELECT COUNT(*)
        FROM dbo.TRANS
    ) AS SourceCount,

    (
        SELECT COUNT(*)
        FROM Berka_DW.FactTransaction
    ) AS LoadedCount,

    (
        SELECT COUNT(*)
        FROM dbo.TRANS
    )
    -
    (
        SELECT COUNT(*)
        FROM Berka_DW.FactTransaction
    ) AS Dropped;
GO


/* =========================================================
   25. CHECK TRANSACTION ID DUPLICATES IN FACT
   ========================================================= */

SELECT
    TransactionID,
    COUNT(*) AS DuplicateCount
FROM Berka_DW.FactTransaction
GROUP BY TransactionID
HAVING COUNT(*) > 1;
GO


/* =========================================================
   26. CHECK NULL FOREIGN KEYS
   ========================================================= */

SELECT
    COUNT(*) AS NullDateKey
FROM Berka_DW.FactTransaction
WHERE DateKey IS NULL;
GO


SELECT
    COUNT(*) AS NullAccountKey
FROM Berka_DW.FactTransaction
WHERE AccountKey IS NULL;
GO


SELECT
    COUNT(*) AS NullCustomerKey
FROM Berka_DW.FactTransaction
WHERE CustomerKey IS NULL;
GO


SELECT
    COUNT(*) AS NullDistrictKey
FROM Berka_DW.FactTransaction
WHERE DistrictKey IS NULL;
GO


SELECT
    COUNT(*) AS NullTransactionTypeKey
FROM Berka_DW.FactTransaction
WHERE TransactionTypeKey IS NULL;
GO


SELECT
    COUNT(*) AS NullOperationKey
FROM Berka_DW.FactTransaction
WHERE OperationKey IS NULL;
GO


/* =========================================================
   27. CHECK UNKNOWN OPERATION USAGE
   ========================================================= */

SELECT
    COUNT(*) AS UnknownOperationTransactions
FROM Berka_DW.FactTransaction f
INNER JOIN Berka_DW.DimOperation o
    ON f.OperationKey = o.OperationKey
WHERE o.Operation = 'Unknown';
GO


/* =========================================================
   28. FACT TABLE SUMMARY
   ========================================================= */

SELECT
    COUNT(*) AS TotalTransactions,
    SUM(Amount) AS TotalTransactionAmount,
    SUM(TransactionCount) AS TransactionCount
FROM Berka_DW.FactTransaction;
GO


/* =========================================================
   29. CHECK FACT TABLE SAMPLE
   ========================================================= */

SELECT TOP 20
    f.TransactionKey,
    f.TransactionID,

    d.FullDate,

    a.AccountID,

    c.ClientID,
    c.Gender,
    c.BirthDate,

    dist.DistrictName,
    dist.Region,

    tt.TransactionType,

    o.Operation,

    f.Amount,
    f.Balance,
    f.TransactionCount

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
    ON f.OperationKey = o.OperationKey

ORDER BY f.TransactionKey;
GO

/* =========================================================
   31. FINAL ROW COUNT SUMMARY
   ========================================================= */

SELECT
    'DimDate' AS TableName,
    COUNT(*) AS RowCount
FROM Berka_DW.DimDate

UNION ALL

SELECT
    'DimAccount',
    COUNT(*)
FROM Berka_DW.DimAccount

UNION ALL

SELECT
    'DimCustomer',
    COUNT(*)
FROM Berka_DW.DimCustomer

UNION ALL

SELECT
    'DimDistrict',
    COUNT(*)
FROM Berka_DW.DimDistrict

UNION ALL

SELECT
    'DimTransactionType',
    COUNT(*)
FROM Berka_DW.DimTransactionType

UNION ALL

SELECT
    'DimOperation',
    COUNT(*)
FROM Berka_DW.DimOperation

UNION ALL

SELECT
    'FactTransaction',
    COUNT(*)
FROM Berka_DW.FactTransaction;
GO


/* =========================================================
   32. FINAL SOURCE-TO-WAREHOUSE VALIDATION
   ========================================================= */

SELECT

    (SELECT COUNT(*)
     FROM dbo.ACCOUNTS)
        AS Source_Accounts,

    (SELECT COUNT(*)
     FROM Berka_DW.DimAccount)
        AS DW_Accounts,

    (SELECT COUNT(*)
     FROM dbo.CLIENTS)
        AS Source_Clients,

    (SELECT COUNT(*)
     FROM Berka_DW.DimCustomer)
        AS DW_Customers,

    (SELECT COUNT(*)
     FROM dbo.DISTRICT)
        AS Source_Districts,

    (SELECT COUNT(*)
     FROM Berka_DW.DimDistrict)
        AS DW_Districts,

    (SELECT COUNT(*)
     FROM dbo.TRANS)
        AS Source_Transactions,

    (SELECT COUNT(*)
     FROM Berka_DW.FactTransaction)
        AS DW_Transactions;
GO


--

SELECT
    TransactionID,
    COUNT(*) AS DuplicateCount
FROM Berka_DW.FactTransaction
GROUP BY TransactionID
HAVING COUNT(*) > 1;

USE Berka_DWBI;
GO
