sqlplus system/password as sysdba '@\\vboxsvr\vagrant\src\main\resources\db\oracle\setup.sql'

sqlcmd -Q ':r \\vboxsvr\vagrant\src\main\resources\db\mssql\clearDBUsers.sql'