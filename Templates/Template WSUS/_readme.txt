Template WSUS Server
--------------------

Requirements
- WSUS database on SQL server (not Windows Internal Database - cannot remote connect)
- Microsoft ODBC Driver - https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15
- Configure ODBC connection to WSUS database
	- /etc/odbc.ini
		[WSUSDB]
		Description = WSUS Database
		Driver = ODBC Driver 17 for SQL Server
		Server = x.x.x.x,1433
	- test connection 
		isql -v WSUSDB username password

