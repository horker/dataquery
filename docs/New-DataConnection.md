---
external help file: Horker.Data.dll-Help.xml
Module Name: HorkerDataQuery
online version:
schema: 2.0.0
---

# New-DataConnection

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
