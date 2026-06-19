SELECT 
    name AS LogicalName,
    physical_name AS PhysicalPath,
    type_desc AS FileType 
FROM sys.master_files
WHERE database_id = DB_ID('Repair');

--проверка всех таблиц
SELECT 
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS TableName,
    create_date,
    modify_date
FROM sys.tables
ORDER BY SchemaName, TableName;

--проверка всех процедур
SELECT 
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS ProcedureName,
    create_date,
    modify_date
FROM sys.procedures
WHERE type_desc = 'SQL_STORED_PROCEDURE'  -- только пользовательские (не системные)
ORDER BY SchemaName, ProcedureName;

--проверка всех триггеров
-- Триггеры на таблицах (DML-триггеры)
SELECT 
    SCHEMA_NAME(t.schema_id) AS TableSchema,
    OBJECT_NAME(t.parent_object_id) AS TableName,
    tr.name AS TriggerName,
    tr.create_date,
    tr.modify_date,
    CASE tr.is_instead_of_trigger WHEN 1 THEN 'INSTEAD OF' ELSE 'AFTER' END AS TriggerType
FROM sys.triggers tr
JOIN sys.tables t ON tr.parent_id = t.object_id
ORDER BY TableSchema, TableName, TriggerName;

-- Триггеры на базе данных (DDL-триггеры)
SELECT 
    name AS TriggerName,
    create_date,
    modify_date,
    is_disabled
FROM sys.triggers
WHERE parent_class = 0;  -- 0 = база данных

--провеке всех ролей и их владельцы 
SELECT 
    r.name AS RoleName,
    r.principal_id AS RolePrincipalID,
    COALESCE(OWNER.name, 'dbo') AS OwnerName
FROM sys.database_principals r
LEFT JOIN sys.database_principals OWNER 
    ON r.owning_principal_id = OWNER.principal_id
WHERE r.type = 'R'                     -- только роли
  AND r.is_fixed_role = 0              -- исключаем фиксированные роли (SQL Server 2012+)
  AND r.name NOT LIKE '##%'            -- исключаем служебные
ORDER BY r.name;

--проверка представлений
SELECT 
    SCHEMA_NAME(v.schema_id) AS SchemaName,
    v.name AS ViewName,
    v.create_date,
    v.modify_date,
    OBJECT_DEFINITION(v.object_id) AS ViewDefinition   -- текст создания (опционально)
FROM sys.views v
ORDER BY SchemaName, ViewName;

SELECT *
FROM Accounts
SELECT *
FROM Clients
SELECT *
FROM Departments
SELECT *
FROM Employees
SELECT *
FROM Orders
SELECT *
FROM OrderStatusLog
SELECT *
FROM Positions
SELECT *
FROM Stages