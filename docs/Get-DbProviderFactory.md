---
external help file: Horker.Data.dll-Help.xml
Module Name: HorkerDataQuery
online version:
schema: 2.0.0
---

# Get-DbProviderFactory

## SYNOPSIS

Gets database provider factories defined in the ConfigurationManager.

## SYNTAX

```
Get-DbProviderFactory [[-ProviderName] <String>] [<CommonParameters>]
```

## DESCRIPTION

The Get-DbProviderFactory cmdlet gets database provider factories defined in the ConfigurationManager.

If the -ProviderName parameter is not specified, it returns all database provider factories.

## EXAMPLES

## PARAMETERS

### -ProviderName

A database provider name.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
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

### System.Data.DataTable

## NOTES

## RELATED LINKS
