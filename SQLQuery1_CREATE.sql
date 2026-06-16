-- Таблица Аккаунтов (учётные записи)
CREATE TABLE Accounts (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,      -- Логин пользователя
    password VARCHAR(255) NOT NULL
);
INSERT INTO Accounts
(email,password)
VALUES
('EWRTRYIU@MAIL','124HIU'),
('EWRTRYSDFDSAFIU@MAIL.RU','124HIU'),
('EWRTFSDEARYIU@MAIL.RU','124HIU'),
('EWRTRDSAFSDFYIU@MAIL.RU','124HIU'),
('EWRTRYIGJHU@MAIL.RU','124HIU'),
('EWRTRYGH7IU@MAIL.RU','124HIU')
SELECT *
FROM Accounts
-- Сотрудники
CREATE TABLE Employees (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    full_name NVARCHAR(255) NOT NULL,
    account_id INT UNIQUE,
    FOREIGN KEY (account_id) REFERENCES Accounts(ID)
);
INSERT INTO Employees
(full_name,account_id)
VALUES
(N'БОРИС',2);
SELECT *
FROM Employees
-- Клиенты
CREATE TABLE Clients (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    full_name NVARCHAR(255) NOT NULL,
    account_id INT UNIQUE,
    FOREIGN KEY (account_id) REFERENCES Accounts(ID)
);
INSERT INTO Clients
(full_name,account_id)
VALUES
(N'БОРИС ава',3);
SELECT *
FROM Clients
-- Должности
CREATE TABLE Positions (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(255) NOT NULL,
    Monthly_salary DECIMAL(10, 2) DEFAULT 80678 -- Оклад по умолчанию
);
INSERT INTO Positions 
(title)
VALUES
(N'Спец по ремонту')
SELECT *
FROM Positions
-- Отделы
CREATE TABLE Departments (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    department_name NVARCHAR(255) NOT NULL,
    employee_id INT,
    position_id INT,
    FOREIGN KEY (employee_id) REFERENCES Employees(ID),
    FOREIGN KEY (position_id) REFERENCES Positions(ID)
);

INSERT INTO Departments
(department_name,employee_id,position_id)
VALUES
(N'Русский ремонт',1,1)
SELECT *
FROM Departments

-- Этапы заказов
CREATE TABLE Stages (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    description TEXT NOT NULL
);
INSERT INTO Stages
(description)
VALUES
(N'принет'),
(N'идет'),
(N'сделан')
SELECT *
FROM Stages
-- Заказы
CREATE TABLE Orders (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    client_id INT NOT NULL,
    employee_id INT NOT NULL,
    department_id INT NOT NULL,
    stage_id INT NOT NULL,
    FOREIGN KEY (client_id) REFERENCES Clients(ID),
    FOREIGN KEY (employee_id) REFERENCES Employees(ID),
    FOREIGN KEY (department_id) REFERENCES Departments(ID),
    FOREIGN KEY (stage_id) REFERENCES Stages(ID)
);

INSERT INTO Orders
(client_id,employee_id,department_id,stage_id)
VALUES 
(1,1,2,1)
SELECT *
FROM Orders


CREATE PROCEDURE CheckOrderExists
    @order_id INT -- Идентификатор сотрудника для проверки
AS
BEGIN
SELECT
*
FROM Orders
JOIN Employees ON Employees.ID=Orders.employee_id
    WHERE
        Employees.ID = @order_id;
END;
EXEC CheckOrderExists @order_id = 123;


CREATE PROCEDURE AddingEmployeesExists
@full_name NVARCHAR(255),
@account_id INT
AS
BEGIN 
INSERT INTO Employees
(full_name,account_id)
VALUES
(@full_name,@account_id)
END;
EXEC AddingEmployeesExists @full_name='Борисович Иван Иванович', @account_id=1;
SELECT *
FROM Employees




CREATE PROCEDURE PreventDeleteEmployeeWithPositionEXEC
@account_id INT
AS
BEGIN
DELETE Employees
WHERE account_id=@account_id
END;
EXEC PreventDeleteEmployeeWithPositionEXEC @account_id=1

CREATE TRIGGER PreventDeleteEmployeeWithPosition
ON Employees
INSTEAD OF DELETE
AS
BEGIN
    DECLARE @employee_id INT;
    SELECT @employee_id = ID FROM deleted;

    -- Проверяем, есть ли отделы, привязанные к этому сотруднику
    IF EXISTS (
        SELECT 1 
        FROM Departments d
        WHERE d.employee_id = @employee_id
    )
    BEGIN
        RAISERROR('Невозможно удалить сотрудника, так как он назначен руководителем одного или нескольких отделов.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    DELETE e
    FROM Employees e
    INNER JOIN deleted del ON e.ID = del.ID;
END;
DELETE Employees

-- 1. Роли
CREATE ROLE Client;
CREATE ROLE RepairSpecialist;
CREATE ROLE _Admin;
GO

-- 2. Представления
-- 2.1. Для специалиста по ремонту – все заказы с деталями
CREATE VIEW vw_AllOrders AS
SELECT 
    o.ID AS OrderID,
    o.client_id,
    c.full_name AS ClientName,
    o.employee_id,
    e.full_name AS EmployeeName,
    o.department_id,
    d.department_name AS DepartmentName,
    o.stage_id,
    s.description AS StageDescription
FROM Orders o
INNER JOIN Clients c ON o.client_id = c.ID
INNER JOIN Employees e ON o.employee_id = e.ID
INNER JOIN Departments d ON o.department_id = d.ID
INNER JOIN Stages s ON o.stage_id = s.ID;
GO

-- 3. Хранимые процедуры

-- 3.1. Клиент – просмотр заказов (по client_id)
CREATE PROCEDURE usp_ClientViewOrders
    @client_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        o.ID AS OrderID,
        o.stage_id,
        s.description AS StageDescription,
        o.employee_id,
        e.full_name AS EmployeeName,
        o.department_id,
        d.department_name AS DepartmentName
    FROM Orders o
    INNER JOIN Stages s ON o.stage_id = s.ID
    INNER JOIN Employees e ON o.employee_id = e.ID
    INNER JOIN Departments d ON o.department_id = d.ID
    WHERE o.client_id = @client_id;
END;
GO

-- 3.2. Специалист по ремонту – создание заказа
CREATE PROCEDURE usp_CreateOrder
    @client_id INT,
    @employee_id INT,
    @department_id INT,
    @stage_id INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Orders (client_id, employee_id, department_id, stage_id)
    VALUES (@client_id, @employee_id, @department_id, @stage_id);
    SELECT SCOPE_IDENTITY() AS NewOrderID;
END;
GO

-- 3.3. Специалист по ремонту – изменение статуса заказа
CREATE PROCEDURE usp_UpdateOrderStage
    @order_id INT,
    @new_stage_id INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Orders
    SET stage_id = @new_stage_id
    WHERE ID = @order_id;
END;
GO

-- 3.4. Администратор – добавление сотрудника
CREATE PROCEDURE usp_AddEmployee
    @full_name NVARCHAR(255),
    @account_id INT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Employees (full_name, account_id)
    VALUES (@full_name, @account_id);
    SELECT SCOPE_IDENTITY() AS NewEmployeeID;
END;
GO

-- 3.5. Администратор – удаление сотрудника учитывает существующий триггер
CREATE PROCEDURE usp_DeleteEmployee
    @employee_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Employees WHERE ID = @employee_id;
END;
GO

-- 4. Назначение разрешений (GRANT / DENY)

-- 4.1. Роль "Клиент"

GRANT EXECUTE ON usp_ClientViewOrders TO Client;

DENY SELECT, INSERT, UPDATE, DELETE ON Orders TO Client;
DENY SELECT ON Clients TO Client;
DENY SELECT ON Employees TO Client;
DENY SELECT ON Departments TO Client;
DENY SELECT ON Stages TO Client;

-- 4.2. Роль "Специалист по ремонту"

GRANT EXECUTE ON usp_CreateOrder TO RepairSpecialist;
GRANT EXECUTE ON usp_UpdateOrderStage TO RepairSpecialist;
GRANT SELECT ON vw_AllOrders TO RepairSpecialist;

DENY INSERT, UPDATE ON Orders TO RepairSpecialist;


-- 4.3. Роль "Администратор"

GRANT EXECUTE ON usp_AddEmployee TO _Admin;
GRANT EXECUTE ON usp_DeleteEmployee TO _Admin;

GRANT SELECT, INSERT, UPDATE, DELETE ON Employees TO _Admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON Accounts TO _Admin;


-- 5. Дополнительный триггер для логирования изменений статуса заказа
-- Создаём таблицу для логов (если её ещё нет)
IF OBJECT_ID('OrderStatusLog', 'U') IS NULL
BEGIN
    CREATE TABLE OrderStatusLog (
        LogID INT IDENTITY(1,1) PRIMARY KEY,
        OrderID INT NOT NULL,
        OldStageID INT NULL,
        NewStageID INT NOT NULL,
        ChangeDate DATETIME DEFAULT GETDATE(),
        ChangedBy NVARCHAR(128) DEFAULT SUSER_SNAME()
    );
END;
GO

-- Триггер, срабатывающий после обновления stage_id
CREATE TRIGGER trg_OrderStatusChange
ON Orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(stage_id)
    BEGIN
        INSERT INTO OrderStatusLog (OrderID, OldStageID, NewStageID, ChangedBy)
        SELECT 
            i.ID,
            d.stage_id,
            i.stage_id,
            SUSER_SNAME()
        FROM inserted i
        INNER JOIN deleted d ON i.ID = d.ID
        WHERE i.stage_id <> d.stage_id;
    END
END;
GO

-- Представление для просмотра клиентов (всех или по фильтру)
CREATE VIEW vw_Clients AS
SELECT 
    c.ID AS ClientID,
    c.full_name,
    a.email,
    a.ID AS AccountID
FROM Clients c
INNER JOIN Accounts a ON c.account_id = a.ID;
GO

-- Процедура для создания клиента (создает аккаунт + клиента)
CREATE PROCEDURE usp_CreateClientRepairSpecialist
    @full_name NVARCHAR(255),
    @email VARCHAR(255),
    @password VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @account_id INT;
    DECLARE @err_msg NVARCHAR(4000);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Проверка существования email
        IF EXISTS (SELECT 1 FROM Accounts WHERE email = @email)
        BEGIN
            RAISERROR('Email уже существует', 16, 1);
            ROLLBACK;
            RETURN;
        END

        -- Вставка аккаунта
        INSERT INTO Accounts (email, password)
        VALUES (@email, @password);
        SET @account_id = SCOPE_IDENTITY();

        -- Вставка клиента
        INSERT INTO Clients (full_name, account_id)
        VALUES (@full_name, @account_id);

        COMMIT TRANSACTION;
        SELECT SCOPE_IDENTITY() AS NewClientID; -- возвращаем ID нового клиента
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        SET @err_msg = ERROR_MESSAGE();
        RAISERROR(@err_msg, 16, 1);
    END CATCH
END
GO

-- Процедура для просмотра клиентов 
CREATE PROCEDURE usp_ViewClientsRepairSpecialist
    @client_id INT = NULL,
    @full_name NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        ClientID,
        full_name,
        email
    FROM vw_Clients
    WHERE (@client_id IS NULL OR ClientID = @client_id)
      AND (@full_name IS NULL OR full_name LIKE '%' + @full_name + '%')
    ORDER BY full_name;
END
GO


GRANT SELECT ON vw_Clients TO RepairSpecialist;
GRANT EXECUTE ON usp_CreateClientRepairSpecialist TO RepairSpecialist;
GRANT EXECUTE ON usp_ViewClientsRepairSpecialist TO RepairSpecialist;
