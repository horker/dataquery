# Horker DataQuery

Horker DataQuery is a database query utility based on ADO.NET.

The main features are:
- Written in C#, so that it works fast for large data
- Supports every database product that provides the ADO.NET driver, including SQL Server, Oracle, MySQL, PostgreSQL, SQLite, Access, OLEDB and ODBC.
- Returns query results as PowerShell objects, and exports PowerShell objects into database tables
- Enables to read `app.config` or `web.config` to set up database provider definitions and connection strings
- Enables to get information from the database schema
- Provides the built-in SQLite driver

## Installation

Horker DataQuery is available in [PowerShell Gallery](https://www.powershellgallery.com/packages/HorkerDataQuery)

```PowerShell
Install-Module HorkerDataQuery
```

## Quick Walkthrough

### Getting Started by Using SQLite

The module provides the built-in SQLite driver so that you can use SQLite databases out-of-the-box.

If you have no SQLite database files, create a new one:

```PowerShell
New-Item test.sqlite
```

Then you can access it by the `Invoke-DataQuery` cmdlet (or its alias `idq`).

```PowerShell
PS> idq test.sqlite "create table Test (a, b, c)"
PS> idq test.sqlite "insert into Test (a, b, c) values (10, 20, 30)"
PS> idq test.sqlite "select * from Test"

 a  b  c
 -  -  -
10 20 30

PS>
```

### Using Other Databases

To access differenct databases, you should define a connection string.

To do so, you can use the `Register-DataConnectionString` cmdlet. For example:

```PowerShell
Register-DataConnectionString `
  -Name localsql `
  -ProviderName System.Data.SqlClient `
  -ConnectionString "Data Source=localhost;Initial Catalog=AdventureWorks2014;Integrated Security=True"
```

The `Name` parameter is a name for this connection string. The `ProviderName` parameter specifies a database provider, such as `System.Data.SqlClient` for SQL Server, `System.Data.OracleClient` for Oracle, and `MySql.Data.MySqlClient` for MySQL. You can find a provider name by the `Get-DbProviderFactory` cmdlet;  The `InvariantName` property is what you want. The `ConnectionString` parameter is a connection string, which specification is different depending on database providers. See the documentation of your database.

After the above registration, you can give `localsql` to the first parameter of `Invoke-DataQuery`:

```PowerShell
idq localsql "select * from Production.Product"
```

You may like to add a definition to your `profile.ps1`:

```PowerShell
Import-Module HorkerDataQuery

Register-DataConnectionString `
  -Name localsql `
  -ProviderName System.Data.SqlClient `
  -ConnectionString "Data Source=localhost;Initial Catalog=AdventureWorks2014;Integrated Security=True"
```

Another way to define a connection string is loading `app.config` or `web.config`. If you are developing a database application, you have already had such a file.

To load a configuration file, use the `Register-DataConfiguration` cmdlet. This cmdlet will read the file, find the `<configuration><connectionStrings` and `<configuration><system.data><DbProviderFactories>` sections, and define connection strings (and database provider factories if exist) according to its contents. The cmdlet will safely ignore the other secions.

```PowerShell
Register-DataConfiguration <your_app_folder>/app.config
```

When you would like to make your own connection string, the `New-DataConnectionString` cmdlet will help.

### Exporting Objects to Database Tables

The `Export-DataTable` cmdlet inserts PowerShell objects into a database table. The properties of the objects are mapped to the database columns with the same names. If there are no corresponding columns in the table, such properties are ignored.

If the specified table does not exist, the cmdlet will create a new table based on the structure of the given object. See the following example:

```PowerShell
PS> dir -File C:\Windows | Export-DataTable test.sqlite WindowsDir
```

If the `test.sqlite` database does not contain the `WindowsDir` table, the above command will work as follows:

1. Create a table with the name `WindowsDir` that has the same columns as the properties of the System.IO.FileInfo object, including `Name`, `FullName`, `Length`, and `LastWriteTime`. In the current version, all columns are of the string type.

1. Insert data from the pipeline into the newly created table.

As a result, the `WindowsDir` table will be created, and it will contain the file information of the `C:\Windows` folder.

Now you can try various queries. For example, let's examine the number of files and the average file size for each file extension, as follows:

```PowerShell
PS> idq test.sqlite "select Extension, count(*), avg(Length) from WindowsDir group by Extension order by count(*) desc"

Extension count(*)      avg(Length)
--------- --------      -----------
.exe            13 419171.692307692
.log            13 193799.692307692
.ini             8          346.125
.xml             4            25531
.INI             3 935.333333333333
.LOG             3 379524.666666667
.bin             2          21565.5
.dll             2            72992
.prx             2           169972
.txt             2           234022
.DMP             1       1780035540
.SCR             1           301936
.dat             1            67584
.mif             1             1945
.scr             1           516096

PS>
```

(The resut depends on the environment.)

This cmdlet is useful for various kinds of data manipulation and analysis tasks.

### In-memory Database

The connection string `memory` is predefined to access a SQLite in-memory database.

To use a in-memory database, you need to open a connection by the `New-DataConnection` cmdlet:

```PowerShell
$c = New-DataConnection memory
```

After that, you can use this connection as ordinary database files or connection string names:

```PowerShell
PS> idq $c "create table Test (a, b, c)"
PS> idq $c "select * from sqlite_master" | ft

type  name tbl_name rootpage sql
----  ---- -------- -------- ---
table Test Test            2 CREATE TABLE Test (a, b, c)

PS>
```

Note that the contents of the in-memory database are lost when the current PowerShell session is terminated, or the connection is closed. You can explicitly close a connection by the `Close-DataConnection` cmdlet:

```PowerShell
Close-DataConnection $c
```

### File-based Databases

The module gives special treatment to SQLite and Microsoft Access as file-based databases. It means that you specify a file name directly as the first parameters of the several cmdlets, including `Invoke-DataQuery` or `New-DataConnection`, in addition to a connection string name.

Note that to use the Microsoft Access provider, Microsoft Access should have been installed in your machine. Furthermore, Microsoft provides the only 32-bit version of the Access provider. Thus you should activate the 32-bit version of PowerShell to make the Access provider effective. Select "Windows PowerShell (x86)" in the Start Menu.

## Cmdlets

The module provides the following cmdlets:

- Data query
    - `Invoke-DataQuery`: Executes a database query.
    - `Get-DataQueryResult`: Gets a result of the last query statement.

- Export
    - `Export-DataTable`: Inserts objects into a database table.

- Database connection
    - `New-DataConnection`: Opens a database connection.
    - `Close-DataConnection`: Closes a database connection.
    - `Get-DataConnectionHistory`: Gets open database connections in the current session.

- Connection string
    - `New-DataConnectionString`: Creates a connection string based on the given parameters.
    - `Get-DataConnectionString`: Gets connection strings defined in the ConfigurationManager.
    - `Register-DataConnectionString`: Registers a connection string to the ConfigurationManager.
    - `Unregister-DataConnectionString`: Removes a connection string definition from the ConfigurationManager.

- Database provider factory
    - `Get-DbProviderFactory`: Gets database provider factories defined in the ConfigurationManager.
    - `Register-DbProviderFactory`: Registers a database provider factory to the ConfigurationManager.
    - `Unregister-DbProviderFactory`: Removes a database provider factory from the ConfigurationManager.

- Configuration Manager
    - `Register-DataConfiguration`: Registers connection strings and database provider factories.

- Database Schema
    - `Get-DataSchema`: Gets database schema information.

Help topics are available for all cmdlets, so try `help` if you want to know about these cmdlets.

## License

Licensed under the MIT License.
