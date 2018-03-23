# Horker DataQuery

Horker DataQuery is a database query utility based on ADO.NET.

The main features are:
- Written in C#, so that it works fast for large data
- Supports every database product that provides the ADO.NET driver, including SQL Server, Oracle, MySQL, PostgreSQL, SQLite, Access, OLEDB, and ODBC
- Returns query results as PowerShell objects, and exports PowerShell objects into database tables
- Reads `app.config` or `web.config` to define database providers and connection strings
- Gets information from the database schema
- Provides the built-in SQLite driver

## Installation

Horker DataQuery is available in [PowerShell Gallery](https://www.powershellgallery.com/packages/HorkerDataQuery)

```PowerShell
Install-Module HorkerDataQuery
```

## Quick Walkthrough

### Getting Started with SQLite

The module is shipped with the built-in SQLite provider so that you can use SQLite databases out of the box.

If you have no SQLite database files, create a new one:

```PowerShell
PS> New-Item test.db
```

Then you can access it by the `Invoke-DataQuery` cmdlet (or its alias `idq`).

```PowerShell
PS> idq test.db "create table Test (a, b, c)"
PS> idq test.db "insert into Test (a, b, c) values (10, 20, 30)"
PS> idq test.db "select * from Test"

 a  b  c
 -  -  -
10 20 30

PS>
```

### Using Other Databases

To access different databases, you should define a connection string.

To do so, you can use the `Register-DataConnectionString` cmdlet. For example:

```PowerShell
PS> Register-DataConnectionString `
  -Name localsql `
  -ProviderName System.Data.SqlClient `
  -ConnectionString "Data Source=localhost;Initial Catalog=AdventureWorks2014;Integrated Security=True"
```

The `Name` parameter is a name for this connection string. The `ProviderName` parameter specifies a database provider, such as `System.Data.SqlClient` for SQL Server, `System.Data.OracleClient` for Oracle, and `MySql.Data.MySqlClient` for MySQL. You can find a provider name by the `Get-DbProviderFactory` cmdlet;  The `InvariantName` property is what you want. The `ConnectionString` parameter is a connection string, which differs depending on database providers. See the documentation for your database.

After the registration, you can give a connection string name, such as `localsql` in the above example, to the first parameter of `Invoke-DataQuery`:

```PowerShell
PS> idq localsql "select * from Production.Product"
```

You may want to put the connection string definition of your database in your `profile.ps1`.

Another way to define a connection string is loading `app.config` or `web.config`. If you are developing a database application, you would have already had such a file.

To load a configuration file, use the `Register-DataConfiguration` cmdlet. This cmdlet will read the file, find the `<configuration><connectionStrings>` and `<configuration><system.data><DbProviderFactories>` sections, and define connection strings (and database provider factories if the latter section exists) according to its contents. The cmdlet will safely ignore the other sections in the file.

```PowerShell
PS> Register-DataConfiguration <your_app_folder>/app.config
```

### Exporting Objects to Database Tables

The `Export-DataTable` cmdlet inserts PowerShell objects into a database table. The properties of the objects are mapped to the database columns with the same names. If there are no corresponding columns in the table, such properties are ignored.

If the specified table does not exist, the cmdlet will create a new table based on the structure of the given object. See the following example:

```PowerShell
PS> dir -File C:\Windows | Export-DataTable test.db WindowsDir
```

If the `test.db` database does not contain the `WindowsDir` table, the above command will work as follows:

1. Creates a table with the name `WindowsDir` that has the same columns as the properties of the System.IO.FileInfo object, including `Name`, `FullName`, `Length`, and `LastWriteTime`.

1. Inserts data from the pipeline into the newly created table.

As a result, the `WindowsDir` table will be created and filled with the information of the files in the `C:\Windows` folder.

Now you can try various queries. For example, let's examine the number of files and the average file size for each file extension:

```PowerShell
PS> idq test.db "select Extension, count(*), avg(Length) from WindowsDir group by Extension order by count(*) desc"

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

(The result depends on the environment.)

In the current version, all columns defined by `Export-DataTable` are of the string type. If you want to specify columns and types, create your own table with the `CREATE TABLE` statement before export.

### In-memory Database

The connection string `memory` is predefined to access an SQLite in-memory database.

To use an in-memory database, you need to open a connection with the `New-DataConnection` cmdlet:

```PowerShell
PS> $mem = New-DataConnection memory
```

Then you can use this connection instead of database files or connection string names:

```PowerShell
PS> idq $mem "create table Test (a, b, c)"
PS> idq $mem "select * from sqlite_master" | ft

type  name tbl_name rootpage sql
----  ---- -------- -------- ---
table Test Test            2 CREATE TABLE Test (a, b, c)

PS>
```

Note that the contents of the in-memory database will be lost when the current PowerShell session is terminated, or the connection is closed.

You can explicitly close a connection with the `Close-DataConnection` cmdlet:

```PowerShell
PS> Close-DataConnection $mem
```

### File-based Databases

The module gives special treatment to SQLite and Microsoft Access as file-based databases. It means that you specify a file name directly as the first parameter of several cmdlets, including `Invoke-DataQuery` or `New-DataConnection`, instead of a connection string name.

Note that if you want to use the Microsoft Access provider, Microsoft Access should have been installed on your machine. Furthermore, Microsoft provides the only 32-bit version of the Access provider, so that you should activate the 32-bit version of PowerShell to make the provider effective. Select "Windows PowerShell (x86)" in the Start Menu.

### Database schemas

You can obtain database schema information by using the `Get-DataSchema` cmdlet. If you execute this cmdlet without the `CollectionName` parameter, it shows a list of available kinds of schema information:

```PowerShell
PS> Get-DataSchema test.db

CollectionName        NumberOfRestrictions NumberOfIdentifierParts
--------------        -------------------- -----------------------
MetaDataCollections                      0                       0
DataSourceInformation                    0                       0
DataTypes                                0                       0
ReservedWords                            0                       0
Catalogs                                 1                       1
Columns                                  4                       4
Indexes                                  4                       3
IndexColumns                             5                       4
Tables                                   4                       3
Views                                    3                       3
ViewColumns                              4                       4
ForeignKeys                              4                       3
Triggers                                 4

PS>
```

You can specify a kind of information that you want to know:

```PowerShell
PS> Get-DataSchema test.db columns

TABLE_CATALOG TABLE_SCHEMA          TABLE_NAME COLUMN_NAME COLUMN_GUID COLUMN_PROPID ORDINAL_POSITION COLUMN_HASDEFAULT
------------- ------------          ---------- ----------- ----------- ------------- ---------------- -----------------
main          sqlite_default_schema Test       a                                                    0             False
main          sqlite_default_schema Test       b                                                    1             False
main          sqlite_default_schema Test       c                                                    2             False
main          sqlite_default_schema WindowsDir Extension                                            0             False
main          sqlite_default_schema WindowsDir Name                                                 1             False
main          sqlite_default_schema WindowsDir Length                                               2             False

PS>
```

Information that the cmdlet will return varies depending on the database provider.

## Cmdlets

The module provides the following cmdlets. Help topics are available for all cmdlets; Try `help` for detailed information.

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

## License

Licensed under the MIT License.
