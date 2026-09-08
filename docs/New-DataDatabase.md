---
external help file: Horker.Data.dll-Help.xml
Module Name: HorkerDataQuery
online version:
schema: 2.0.0
---

# New-DataDatabase

## SYNOPSIS
Creates an empty SQLite or DuckDB database file.

## SYNTAX

```powershell
New-DataDatabase [-Path] <String> [-DatabaseType <String>] [-Force] [-PassThru]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates and verifies an empty database, closes its connections, and moves it to
the requested path. No user tables are created. SQLite is supported on Windows
PowerShell 5.1 and PowerShell 7; DuckDB requires PowerShell 7.6.5 or later.

The extensions `.db`, `.sqlite` and `.sqlite3` select SQLite; `.duckdb` selects
DuckDB. Matching is case-insensitive. Other extensions, including no extension,
require DatabaseType. An explicit type must agree with a recognized extension.

Path is a literal filesystem path relative to the PowerShell current location;
wildcards are not expanded and registered connection names are not resolved.
The parent directory must already exist. Memory databases are not supported.

Existing files require Force. A verified temporary database on the same volume
replaces the original using File.Replace; the original is not deleted first.
Read-only files, reparse points, locked targets and targets with `-wal`, `-shm`,
`-journal` or `.wal` sidecars are rejected. Sidecars are never removed automatically.
Close all connections before replacement. Concurrent creation or use by another
process is unsupported. Filesystems without replacement support produce errors.
Force does not bypass confirmation, file locks or read-only attributes.

WhatIf and declined confirmation create no temporary files and return no output.
Provider registrations are respected, and connections are not added to history.

## EXAMPLES

### Example 1: Create a SQLite database
```powershell
New-DataDatabase ./sample.db
Invoke-DataQuery ./sample.db 'create table Items (Id integer)'
```

### Example 2: Create a DuckDB database with an arbitrary extension
```powershell
New-DataDatabase ./analytics.data -DatabaseType DuckDB
$c = New-DataConnection -ProviderName DuckDB.NET.Data -ConnectionString 'Data Source=analytics.data'
try { Invoke-DataQuery $c 'select 42 as Value' }
finally { Close-DataConnection $c }
```
Use an explicit provider when opening a DuckDB file without the `.duckdb` extension.

### Example 3: Replace a file and return its information
```powershell
$file = New-DataDatabase ./sample.db -Force -PassThru
```
Replacement discards the previous file contents, including any database tables.

## PARAMETERS

### -Path
Required single literal filesystem path. Position: 0.

### -DatabaseType
SQLite or DuckDB. Required for unrecognized or absent file extensions.

### -Force
Allows replacement of an existing regular file, including an empty or non-database file.

### -PassThru
Returns System.IO.FileInfo after successful placement and connection disposal.
Otherwise the cmdlet returns no output.

### -WhatIf
Shows the proposed operation without creating or replacing files.

### -Confirm
Requests confirmation before creating or replacing files.

### CommonParameters
This cmdlet supports the common parameters.

## INPUTS
None.

## OUTPUTS
System.IO.FileInfo when PassThru is specified; otherwise none.

## NOTES
The module version remains 3.0.0. No connection string is registered automatically.

## RELATED LINKS
[New-DataConnection](New-DataConnection.md)
[Invoke-DataQuery](Invoke-DataQuery.md)
[Export-DataTable](Export-DataTable.md)
