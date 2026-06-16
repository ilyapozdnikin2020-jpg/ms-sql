-- Переключение на пользователя-клиента
EXECUTE AS USER = 'ClientUser';
GO

-- Разрешённое действие: просмотр своих заказов (client_id = 1)
EXEC usp_ClientViewOrders @client_id = 1;

-- Попытка выполнить несанкционированное действие (например, создание заказа)
BEGIN TRY
    EXEC usp_CreateOrder @client_id = 1, @employee_id = 7, @department_id = 2, @stage_id = 1;
END TRY
BEGIN CATCH
    PRINT 'Ошибка: ' + ERROR_MESSAGE();
END CATCH

BEGIN TRY
    SELECT * FROM Orders;
END TRY
BEGIN CATCH
    PRINT 'Ошибка: ' + ERROR_MESSAGE();
END CATCH

REVERT;
GO

-- Переключение на пользователя-администратора
EXECUTE AS USER = 'AdminUser';
GO

-- Добавление нового сотрудника (account_id должен существовать в Accounts)
DECLARE @NewEmpID INT;
EXEC @NewEmpID = usp_AddEmployee @full_name = N'Сидоров Сидор Сидорович', @account_id = 5;
PRINT 'Добавлен сотрудник с ID = ' + CAST(@NewEmpID AS VARCHAR);

-- Удаление сотрудника, который НЕ является руководителем отдела
-- Например, предположим, что ID = @NewEmpID (только что созданный)
EXEC usp_DeleteEmployee @employee_id = @NewEmpID;
PRINT 'Сотрудник удалён успешно (не был руководителем)';

-- Попытка удалить сотрудника, который является руководителем отдела
-- Например, предположим, что сотрудник с ID = 7 является начальником отдела (есть запись в Departments)
BEGIN TRY
    EXEC usp_DeleteEmployee @employee_id = 7;
END TRY
BEGIN CATCH
    PRINT 'Ошибка: ' + ERROR_MESSAGE();
END CATCH


-- Администратор также может выполнять другие операции 
SELECT * FROM Employees;


REVERT;
GO
-- Под пользователем RepairUser
USE ffg
EXECUTE AS USER = 'RepairUser';

-- Создать клиента
EXEC usp_CreateClientRepairSpecialist @full_name = N'Иванов Иван Иванович', @email = 'ivangf@mail.ru', @password = 'pass123';

-- Посмотреть всех клиентов
EXEC usp_ViewClientsRepairSpecialist;

-- Посмотреть клиента по ID
EXEC usp_ViewClientsRepairSpecialist @client_id = 5;

-- Посмотреть клиентов по части имени
EXEC usp_ViewClientsRepairSpecialist @full_name = N'Иван';

-- Просмотр всех заказов через представление (разрешено)
SELECT * FROM vw_AllOrders;
-- Результат: все заказы с расшифровкой

-- Создание нового заказа 
DECLARE @NewOrderID INT;
EXEC @NewOrderID = usp_CreateOrder @client_id = 1, @employee_id = 2, @department_id = 2, @stage_id = 1;
PRINT 'Создан заказ с ID = ' + CAST(@NewOrderID AS VARCHAR);

-- Изменение статуса созданного заказа 
EXEC usp_UpdateOrderStage @order_id = @NewOrderID, @new_stage_id = 2;
PRINT 'Статус заказа обновлён';

-- Проверка, что статус изменился 
SELECT * FROM OrderStatusLog WHERE OrderID = @NewOrderID;


-- Попытка прямого INSERT в Orders 
BEGIN TRY
    INSERT INTO Orders (client_id, employee_id, department_id, stage_id)
    VALUES (2, 8, 3, 1);
END TRY
BEGIN CATCH
    PRINT 'Ошибка: ' + ERROR_MESSAGE();
END CATCH

-- Попытка удалить сотрудника
BEGIN TRY
    EXEC usp_DeleteEmployee @employee_id = 8;
END TRY
BEGIN CATCH
    PRINT 'Ошибка: ' + ERROR_MESSAGE();
END CATCH

REVERT;
