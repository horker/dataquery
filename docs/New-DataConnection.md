---
external help file: Horker.Data.dll-Help.xml
Module Name: HorkerDataQuery
online version:
schema: 2.0.0
---

# New-DataConnection

To create a new, closed SQLite or DuckDB file, use [New-DataDatabase](New-DataDatabase.md).
Unlike New-DataConnection, it rejects existing files unless Force is specified and
returns no open connection. Existing connection-string creation remains supported.

DuckDB is bundled on PowerShell 7.6.5+ / Windows x64 only. Use
`New-DataConnection duckdb-memory` for a private memory database, or
`New-DataConnection -ProviderName DuckDB.NET.Data -ConnectionString 'Data Source=analytics.duckdb'`
to create/open a file. Existing `.duckdb` paths may be specified directly (case-insensitive
suffix); missing paths require explicit creation. Registered names take precedence.
Explicit provider selection accepts arbitrary extensions. Add `access_mode=READ_ONLY`
to the connection string for read-only access. Retain the connection to share a
memory database between commands, then call `Close-DataConnection` in `finally`.
The existing `memory` connection remains SQLite. Windows PowerShell 5.1 reports
DuckDB as unsupported without loading its DLLs.

## SYNOPSIS

Opens a database connection.

## SYNTAX

### FileOrName (Default)
```
New-DataConnection [-FileOrName] <String> [<CommonParameters>]
```

### ConnectionString
```
New-DataConnection [-ProviderName] <String> [-ConnectionString] <String> [<CommonParameters>]
```

## DESCRIPTION

The New-DataConnection cmdlet opens a database connection.

## EXAMPLES

## PARAMETERS

### -ConnectionString

A database provider name.

```yaml
Type: String
Parameter Sets: ConnectionString
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileOrName

A database file name or a connection string name.

```yaml
Type: String
Parameter Sets: FileOrName
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProviderName

A database provider name.

```yaml
Type: String
Parameter Sets: ConnectionString
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Data.Common.DbConnection

## NOTES

## RELATED LINKS
