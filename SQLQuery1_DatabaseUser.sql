USE ffg;  -- Замените на имя вашей базы данных
GO

-- Проверка и создание логинов (если не существуют)
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'ClientLogin')
BEGIN
    CREATE LOGIN ClientLogin WITH PASSWORD = 'ClientPass123!', CHECK_POLICY = OFF;
END

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'RepairLogin')
BEGIN
    CREATE LOGIN RepairLogin WITH PASSWORD = 'RepairPass123!', CHECK_POLICY = OFF;
END

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'AdminLogin')
BEGIN
    CREATE LOGIN AdminLogin WITH PASSWORD = 'AdminPass123!', CHECK_POLICY = OFF;
END

-- Создание пользователей в текущей БД (если не существуют)
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ClientUser')
BEGIN
    CREATE USER ClientUser FOR LOGIN ClientLogin;
END

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'RepairUser')
BEGIN
    CREATE USER RepairUser FOR LOGIN RepairLogin;
END

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'AdminUser')
BEGIN
    CREATE USER AdminUser FOR LOGIN AdminLogin;
END

-- Назначение ролей 
ALTER ROLE Client ADD MEMBER ClientUser;
ALTER ROLE RepairSpecialist ADD MEMBER RepairUser;
ALTER ROLE _Admin ADD MEMBER AdminUser;

-- Проверка
SELECT 
    dp.name AS DatabaseUser,
    dp.type_desc,
    r.name AS RoleName
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members rm ON dp.principal_id = rm.member_principal_id
LEFT JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
WHERE dp.name IN ('ClientUser', 'RepairUser', 'AdminUser')
ORDER BY dp.name;
