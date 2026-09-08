# Horker DataQuery

Horker DataQuery is a database query utility based on ADO.NET.

The main features are:
- Written in C#, so that it works fast for large data
- Supports database products with an ADO.NET driver, including SQL Server, Oracle, MySQL, PostgreSQL, SQLite, DuckDB, Access, OLEDB, and ODBC
- Returns query results as PowerShell objects, and exports PowerShell objects into database tables
- Reads `app.config` or `web.config` to define database providers and connection strings
- Gets information from the database schema
- Bundles SQLite on both supported hosts, plus Npgsql and DuckDB on PowerShell 7

## Installation

Version 3.0.0 supports the following Windows x64 environments:

| Host | Runtime | Bundled database providers |
| --- | --- | --- |
| Windows PowerShell 5.1 (Desktop) | .NET Framework 4.8 or later | Framework ODBC, OLE DB and SqlClient; SQLite 1.0.119 |
| PowerShell 7.6.5 or later (Core) | .NET 10 | ODBC, OLE DB, SqlClient, SQLite 1.0.119, Npgsql 10.0.3 and DuckDB.NET.Data.Full 1.5.5 |

One module package contains both `lib/net48` and `lib/net10.0`; the loader selects
the matching target. Running the Desktop version does not require .NET 10.
32-bit PowerShell and Core versions earlier than 7.6.5 are not supported.
Database drivers such as the Access driver must also be 64-bit.

Horker DataQuery is available in [PowerShell Gallery](https://www.powershellgallery.com/packages/HorkerDataQuery)

```PowerShell
Install-Module HorkerDataQuery
```

To build from source on Windows x64, install the .NET 10 SDK, InvokeBuild,
and Pester 5, then run `Invoke-Build` from PowerShell 7.6.5 or later.
The build publishes the current managed and native NuGet dependencies into
`module/Debug/HorkerDataQuery` and `module/Release/HorkerDataQuery`, and runs
the .NET tests for both targets and Pester tests in separate `powershell.exe
-NoProfile` and `pwsh -NoProfile` processes. The Framework reference assemblies
are restored through NuGet. Build tools must be available to the build process,
and the Windows PowerShell execution policy must allow local test scripts.

Import a local build using `Import-Module ./module/Release/HorkerDataQuery`.
Database file arguments are resolved literally relative to the current PowerShell
location for creation, connections, queries, copies, exports and schema requests.
Registered connection names take precedence over file paths when opening databases.
Connection strings supplied explicitly or through configuration retain provider-defined
semantics; relative paths embedded inside those strings are not rewritten.
Provider registration and configuration imports only change process memory;
they do not modify `machine.config` or the PowerShell host configuration.
If Desktop already loaded a conflicting SQLite or Horker.Data assembly, start
a new `powershell.exe -NoProfile` process and import this module first.

### PostgreSQL on Windows PowerShell 5.1

The Desktop target does not bundle or automatically register Npgsql. Install
the 64-bit PostgreSQL ODBC driver separately and use an ODBC DSN, for example:

```PowerShell
Register-DataConnectionString pg System.Data.Odbc 'DSN=PostgreSQL64'
$connection = New-DataConnection pg
try { Invoke-DataQuery $connection 'select 1 as value' }
finally { Close-DataConnection $connection }
```

Configure the DSN with the server and authentication settings required by your
environment. PostgreSQL, SQL Server, Access and other external database
connections require separate integration testing; the automated suite uses local SQLite and DuckDB databases.

### DuckDB on PowerShell 7

DuckDB.NET.Data.Full 1.5.5 and its Windows x64 native library are bundled under
`lib/net10.0`. No separate DuckDB installation is required. Windows PowerShell
5.1 does not bundle or register DuckDB and reports that PowerShell 7 is required.

```powershell
$c = New-DataConnection duckdb-memory
try {
    Invoke-DataQuery $c 'select $value as Value' @{ value = 42 }
} finally { Close-DataConnection $c }

# Explicit creation also accepts files with arbitrary extensions.
$c = New-DataConnection -ProviderName DuckDB.NET.Data `
    -ConnectionString 'Data Source=analytics.duckdb'
Close-DataConnection $c

# Shorthand only opens an existing file; suffix matching is case-insensitive.
$c = New-DataConnection ./analytics.duckdb
Close-DataConnection $c

$c = New-DataConnection -ProviderName DuckDB.NET.Data `
    -ConnectionString 'Data Source=analytics.duckdb;access_mode=READ_ONLY'
Close-DataConnection $c
```

Registered connection names take precedence over file extensions. A missing
`.duckdb` file is not created by shorthand. `memory` remains SQLite; retain an
explicitly opened `duckdb-memory` connection to use the same in-memory database
across commands. Connections supplied by the caller remain open after queries,
copies and exports, including failures; implicitly opened connections are disposed.

Use `?` or `$1`, `$2`, ... for positional parameters (arrays or scalar values),
and `$name` for dictionary parameters. Dictionary keys accept `name` or `$name`.
SQL text containing `@name` is not rewritten. For `Copy-DataRow -TargetSql`, use
`$ColumnName` matching the source columns. Generated DuckDB INSERT statements
use positional parameters and double-quoted, escaped column names.

`Invoke-DataQuery` supports normal objects, `-AsDataRow` and `-AsDataTable`,
including empty tables with column metadata. Standard numbers, strings, booleans
and timestamps retain CLR types. BLOB values are copied to `byte[]` before the
native reader is disposed. Other provider values, including compound types, are
returned without custom JSON or string conversion. SQL NULL becomes `$null` in
normal output, or `DBNull` with `-PreserveDbNull` and in DataRow/DataTable output.

`Export-DataTable` creates missing tables using `VARCHAR` unless `-TypeName` is
specified; it does not infer types. Existing tables retain their types. Schema-qualified
table expressions such as `analytics.items` are accepted; quote table identifiers
yourself when necessary. Failed row inserts roll back the batch. `Get-DataSchema`
delegates to DuckDB.NET, including the collection list, `Tables` and `Columns`;
unsupported collections produce errors.

DuckDB query affected-row counts (`Get-DataQueryResult` and
`-ShowRecordsAffected`) are always `-1`. A positive `-Timeout` is rejected before
SQL execution, including copies with DuckDB on either side. Omit the timeout or
use `0` for no limit; negative values are invalid. Dedicated CSV/Parquet helpers,
Appender, automatic extension installation and changes to multiple-result output
are outside this integration.

Provider references: [installation](https://duckdb.net/docs/getting-started.html),
[parameters](https://duckdb.net/docs/basic-usage.html),
[CLR types](https://duckdb.net/docs/type-mapping.html).

## Quick Walkthrough

### Creating a Database File

```powershell
New-DataDatabase ./sample.db                   # SQLite
New-DataDatabase ./analytics.duckdb            # DuckDB (PowerShell 7 only)
New-DataDatabase ./database -DatabaseType SQLite
$file = New-DataDatabase ./sample.db -Force -PassThru
```

The cmdlet creates an empty database and closes its connections. It normally returns
no output; `-PassThru` returns `FileInfo`. Extensions `.db`, `.sqlite`, `.sqlite3`
select SQLite and `.duckdb` selects DuckDB, case-insensitively. Other extensions
require `-DatabaseType`. Conflicting types and recognized extensions are rejected.
Paths are literal and relative to the PowerShell current location. The parent directory
must exist; connection names and memory database specifications are not accepted.

`-Force` replaces an existing file only after creating and verifying a temporary
database. Close all connections first. Read-only files, reparse points, locked files,
and targets with database sidecars are rejected. Concurrent database use is unsupported.
`-WhatIf` and `-Confirm` are supported; `-Force` does not bypass confirmation.
See [New-DataDatabase](docs/New-DataDatabase.md) for details.

### Getting Started with SQLite

The module is shipped with the built-in SQLite provider so that you can use SQLite databases out of the box.

If you have no SQLite database files, create a new one:

```PowerShell
PS> New-DataDatabase test.db
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

In the current version, all columns defined by `Export-DataTable` are of the string type. If you want to specify columns and types, create a table with the `CREATE TABLE` statement before export:

```PowerShell
PS> idq test.db "drop table WindowsDir"
PS> idq test.db "create table WindowsDir (Name text, Length int)"
PS> dir C:\Windows -File | Export-DataTable test.db WindowsDir
PS> idq test.db "select * from WindowsDir limit 3" | ft

Name              Length
----              ------
ativpsrm.bin           0
bfsvc.exe          71168
BlendSettings.ini     23

PS>
```

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
