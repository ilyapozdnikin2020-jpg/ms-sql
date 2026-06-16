-- Переключение на пользователя-клиента
EXECUTE AS USER = 'ClientUser';
GO

-- 1.1. Разрешённое действие: просмотр своих заказов (client_id = 1)
EXEC usp_ClientViewOrders @client_id = 1;

-- 1.2. Попытка выполнить несанкционированное действие (например, создание заказа)
BEGIN TRY
    EXEC usp_CreateOrder @client_id = 1, @employee_id = 7, @department_id = 2, @stage_id = 1;
END TRY
BEGIN CATCH
    PRINT 'Ошибка: ' + ERROR_MESSAGE();
END CATCH
-- Ожидаемый результат: "The EXECUTE permission was denied on object 'usp_CreateOrder'"

BEGIN TRY
    SELECT * FROM Orders;
END TRY
BEGIN CATCH
    PRINT 'Ошибка: ' + ERROR_MESSAGE();
END CATCH

REVERT;
GO
