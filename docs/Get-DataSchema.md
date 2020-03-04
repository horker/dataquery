---
external help file: Horker.Data.dll-Help.xml
Module Name: HorkerDataQuery
online version:
schema: 2.0.0
---

# Get-DataSchema

## SYNOPSIS

Gets database schema information.

## SYNTAX

### FileOrName
```
Get-DataSchema [-FileOrName] <String> [[-CollectionName] <String>] [<CommonParameters>]
```

### Connection
```
Get-DataSchema [-Connection] <DbConnection> [[-CollectionName] <String>] [<CommonParameters>]
```

## DESCRIPTION

The Get-DataSchema cmdlet gets database schema information that the database engine provides. If a schema collection name (-CollectionName) is not specified, it returns the information of all available schemas. The provided information varies among database products.

## EXAMPLES

## PARAMETERS

### -CollectionName

A schama collection name.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Connection

A database connection.

```yaml
Type: DbConnection
Parameter Sets: Connection
Aliases:

Required: True
Position: 0
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Data.DataRow

## NOTES

## RELATED LINKS
