-- Create a database
CREATE DATABASE Berka_DWBI;
GO

USE Berka_Source;
GO

-- Check your Berka files
-- Record counts per source table
SELECT 'ACCOUNTS' AS TableName, COUNT(*) AS TotalRecords FROM ACCOUNTS   -- expect 4,500
UNION ALL SELECT 'CLIENTS',  COUNT(*) FROM CLIENTS                       -- expect 5,369
UNION ALL SELECT 'DISP',     COUNT(*) FROM DISP                          -- expect 5,369
UNION ALL SELECT 'DISTRICT', COUNT(*) FROM DISTRICT                      -- expect 77
UNION ALL SELECT 'CARDS',    COUNT(*) FROM CARDS                         -- expect 892
UNION ALL SELECT 'LOAN',     COUNT(*) FROM LOAN                          -- expect 682
UNION ALL SELECT 'ORDERS',   COUNT(*) FROM ORDERS                        -- expect 6,471
UNION ALL SELECT 'TRANS',    COUNT(*) FROM TRANS;                        -- expect 1,056,320

-- Loan status distribution
SELECT status, COUNT(*) AS LoanCount
FROM LOAN
GROUP BY status
ORDER BY status;


-- Check missing values
SELECT 
    COUNT(*) AS TotalRecords,
    COUNT(account_id) AS AccountID_NotNull,
    COUNT(*) - COUNT(account_id) AS AccountID_Null
FROM dbo.ACCOUNTS;


---
SELECT 
    'account' AS TableName,
    COUNT(*) AS TotalRecords,
    COUNT(account_id) AS Key_NotNull,
    COUNT(*) - COUNT(account_id) AS Key_Null
FROM dbo.ACCOUNTS

UNION ALL

SELECT 
    'client',
    COUNT(*),
    COUNT(client_id),
    COUNT(*) - COUNT(client_id)
FROM dbo.CLIENTS

UNION ALL

SELECT 
    'disp',
    COUNT(*),
    COUNT(disp_id),
    COUNT(*) - COUNT(disp_id)
FROM dbo.DISP

UNION ALL

SELECT 
    'district',
    COUNT(*),
    COUNT(A1),
    COUNT(*) - COUNT(A1)
FROM dbo.DISTRICT

UNION ALL

SELECT 
    'cards',
    COUNT(*),
    COUNT(card_id),
    COUNT(*) - COUNT(card_id)
FROM dbo.CARDS

UNION ALL

SELECT 
    'loan',
    COUNT(*),
    COUNT(loan_id),
    COUNT(*) - COUNT(loan_id)
FROM dbo.LOAN

UNION ALL

SELECT 
    'order',
    COUNT(*),
    COUNT(order_id),
    COUNT(*) - COUNT(order_id)
FROM dbo.order

UNION ALL

SELECT 
    'trans',
    COUNT(*),
    COUNT(trans_id),
    COUNT(*) - COUNT(trans_id)
FROM dbo.TRANS;


-- Check duplicate primary/key values in all source tables

SELECT 'account' AS TableName, COUNT(*) AS DuplicateGroups
FROM (
    SELECT account_id
    FROM dbo.account
    GROUP BY account_id
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT 'client', COUNT(*)
FROM (
    SELECT client_id
    FROM dbo.client
    GROUP BY client_id
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT 'disp', COUNT(*)
FROM (
    SELECT disp_id
    FROM dbo.disp
    GROUP BY disp_id
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT 'district', COUNT(*)
FROM (
    SELECT A1
    FROM dbo.district
    GROUP BY A1
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT 'cards', COUNT(*)
FROM (
    SELECT card_id
    FROM dbo.cards
    GROUP BY card_id
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT 'loan', COUNT(*)
FROM (
    SELECT loan_id
    FROM dbo.loan
    GROUP BY loan_id
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT 'order', COUNT(*)
FROM (
    SELECT order_id
    FROM dbo.[order]
    GROUP BY order_id
    HAVING COUNT(*) > 1
) x

UNION ALL

SELECT 'trans', COUNT(*)
FROM (
    SELECT trans_id
    FROM dbo.trans
    GROUP BY trans_id
    HAVING COUNT(*) > 1
) x;



-- Relationship / Orphan Record Validation

SELECT 'DISP → CLIENTS' AS Relationship, COUNT(*) AS OrphanRecords
FROM dbo.DISP d
LEFT JOIN dbo.CLIENTS c
    ON d.client_id = c.client_id
WHERE c.client_id IS NULL

UNION ALL

SELECT 'DISP → ACCOUNTS', COUNT(*)
FROM dbo.DISP d
LEFT JOIN dbo.ACCOUNTS a
    ON d.account_id = a.account_id
WHERE a.account_id IS NULL

UNION ALL

SELECT 'TRANS → ACCOUNTS', COUNT(*)
FROM dbo.TRANS t
LEFT JOIN dbo.ACCOUNTS a
    ON t.account_id = a.account_id
WHERE a.account_id IS NULL

UNION ALL

SELECT 'ORDERS → ACCOUNTS', COUNT(*)
FROM dbo.ORDERS o
LEFT JOIN dbo.ACCOUNTS a
    ON o.account_id = a.account_id
WHERE a.account_id IS NULL

UNION ALL

SELECT 'LOAN → ACCOUNTS', COUNT(*)
FROM dbo.LOAN l
LEFT JOIN dbo.ACCOUNTS a
    ON l.account_id = a.account_id
WHERE a.account_id IS NULL

UNION ALL

SELECT 'CARDS → DISP', COUNT(*)
FROM dbo.CARDS c
LEFT JOIN dbo.DISP d
    ON c.disp_id = d.disp_id
WHERE d.disp_id IS NULL;

-- Invalid / Inconsistent Value Validation

SELECT 'ACCOUNTS - frequency' AS CheckField, COUNT(*) AS InvalidRecords
FROM dbo.ACCOUNTS
WHERE LTRIM(RTRIM(frequency)) NOT IN
(
    'POPLATEK MESICNE',
    'POPLATEK TYDNE',
    'POPLATEK PO OBRATU'
)

UNION ALL

SELECT 'DISP - type', COUNT(*)
FROM dbo.DISP
WHERE LTRIM(RTRIM(type)) NOT IN
(
    'OWNER',
    'USER'
)

UNION ALL

SELECT 'LOAN - status', COUNT(*)
FROM dbo.LOAN
WHERE LTRIM(RTRIM(status)) NOT IN
(
    'A',
    'B',
    'C',
    'D'
)

UNION ALL

SELECT 'CARDS - type', COUNT(*)
FROM dbo.CARDS
WHERE LTRIM(RTRIM(type)) NOT IN
(
    'junior',
    'classic',
    'gold'
)

UNION ALL

SELECT 'TRANS - type', COUNT(*)
FROM dbo.TRANS
WHERE LTRIM(RTRIM(type)) NOT IN
(
    'PRIJEM',
    'VYDAJ'
)

UNION ALL

SELECT 'TRANS - operation', COUNT(*)
FROM dbo.TRANS
WHERE LTRIM(RTRIM(operation)) NOT IN
(
    'VYBER KARTOU',
    'VKLAD',
    'PREVOD Z UCTU',
    'VYBER',
    'PREVOD NA UCET'
)

UNION ALL

SELECT 'ORDERS - k_symbol', COUNT(*)
FROM dbo.ORDERS
WHERE LTRIM(RTRIM(k_symbol)) NOT IN
(
    'POJISTNE',
    'SIPO',
    'LEASING',
    'UVER'
);

----
SELECT
    TABLE_NAME,
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN
(
    'ACCOUNTS',
    'CLIENTS',
    'DISP',
    'DISTRICT',
    'CARDS',
    'LOAN',
    'ORDERS',
    'TRANS'
)
ORDER BY TABLE_NAME, ORDINAL_POSITION;


-- Check actual categorical values

SELECT 'DISP.type' AS Field, type AS Value, COUNT(*) AS Records
FROM dbo.DISP
GROUP BY type

UNION ALL

SELECT 'TRANS.type', type, COUNT(*)
FROM dbo.TRANS
GROUP BY type

UNION ALL

SELECT 'TRANS.operation', operation, COUNT(*)
FROM dbo.TRANS
GROUP BY operation

UNION ALL

SELECT 'ORDERS.k_symbol', k_symbol, COUNT(*)
FROM dbo.ORDERS
GROUP BY k_symbol

ORDER BY Field, Records DESC;


-----
SELECT 'ACCOUNTS.frequency' AS Field, COUNT(*) AS ValuesWithSpaces
FROM dbo.ACCOUNTS
WHERE frequency <> LTRIM(RTRIM(frequency))

UNION ALL

SELECT 'DISP.type', COUNT(*)
FROM dbo.DISP
WHERE type <> LTRIM(RTRIM(type))

UNION ALL

SELECT 'LOAN.status', COUNT(*)
FROM dbo.LOAN
WHERE status <> LTRIM(RTRIM(status))

UNION ALL

SELECT 'CARDS.type', COUNT(*)
FROM dbo.CARDS
WHERE type <> LTRIM(RTRIM(type))

UNION ALL

SELECT 'TRANS.type', COUNT(*)
FROM dbo.TRANS
WHERE type <> LTRIM(RTRIM(type))

UNION ALL

SELECT 'TRANS.operation', COUNT(*)
FROM dbo.TRANS
WHERE operation IS NOT NULL
  AND operation <> LTRIM(RTRIM(operation))

UNION ALL

SELECT 'ORDERS.k_symbol', COUNT(*)
FROM dbo.ORDERS
WHERE k_symbol IS NOT NULL
  AND k_symbol <> LTRIM(RTRIM(k_symbol));



  

/* =========================================================
   30. CREATE INDEXES FOR ANALYTICAL QUERIES
   ========================================================= */

CREATE INDEX IX_FactTransaction_DateKey
ON Berka_DW.FactTransaction(DateKey);
GO


CREATE INDEX IX_FactTransaction_AccountKey
ON Berka_DW.FactTransaction(AccountKey);
GO


CREATE INDEX IX_FactTransaction_CustomerKey
ON Berka_DW.FactTransaction(CustomerKey);
GO


CREATE INDEX IX_FactTransaction_DistrictKey
ON Berka_DW.FactTransaction(DistrictKey);
GO


CREATE INDEX IX_FactTransaction_TransactionTypeKey
ON Berka_DW.FactTransaction(TransactionTypeKey);
GO


CREATE INDEX IX_FactTransaction_OperationKey
ON Berka_DW.FactTransaction(OperationKey);
GO

