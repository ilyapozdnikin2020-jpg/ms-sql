USE ffg
--Создаём папку для хранения резервных копий
EXEC xp_create_subdir N'C:\Backup\Repair';   

--Полное резервное копирование базы данных=
BACKUP DATABASE ffg
TO DISK = 'C:\Backup\Repair\Repair_full.bak'
WITH 
    INIT,
    NAME = 'Repair-FullBackup';

--Дифференциальное резервное копирование
BACKUP DATABASE ffg
TO DISK = 'C:\Backup\Repair\Repair_diff.bak'
WITH 
    DIFFERENTIAL,
    INIT,
    NAME = 'Repair-DiffBackup';

--Резервное копирование журнала транзакций
BACKUP LOG ffg
TO DISK = 'C:\Backup\Repair\Repair_log.trn'
WITH 
    INIT,
    NAME = 'Repair-LogBackup';


--Проверка успешности создания файлов
PRINT 'Резервные копии созданы в папке C:\Backup\Repair\';

RESTORE FILELISTONLY FROM DISK = 'C:\Backup\Repair\Repair_full.bak';

RESTORE DATABASE Repair
FROM DISK = 'C:\Backup\Repair\Repair_full.bak'
WITH 
    MOVE 'ffg' TO 'C:\Backup\Repair\Repair.mdf',
    MOVE 'ffg_log'  TO 'C:\Backup\Repair\Repair.ldf',
    NORECOVERY,
    REPLACE;
	
RESTORE LOG [Repair]
FROM DISK = 'C:\Backup\Repair\Repair_log.trn'
WITH RECOVERY;