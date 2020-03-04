---
external help file: Horker.Data.dll-Help.xml
Module Name: HorkerDataQuery
online version:
schema: 2.0.0
---

# Register-DataConnectionString

## SYNOPSIS

Registers a connection string to the ConfigurationManager.

## SYNTAX

```
Register-DataConnectionString [-Name] <String> [-ProviderName] <String> [-ConnectionString] <String>
 [<CommonParameters>]
```

## DESCRIPTION

The Register-DataConnectionString cmdlet registers a connection string to the ConfigurationManager.

## EXAMPLES

## PARAMETERS

### -ConnectionString

A connection string.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name

A connection string name.

```yaml
Type: String
Parameter Sets: (All)
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
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Void

## NOTES

## RELATED LINKS
