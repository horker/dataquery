---
external help file: Horker.Data.dll-Help.xml
Module Name: HorkerDataQuery
online version:
schema: 2.0.0
---

# Register-DataConfiguration

## SYNOPSIS

Registers connection strings and database provider factories.

## SYNTAX

```
Register-DataConfiguration [-ConfigurationFile] <String> [<CommonParameters>]
```

## DESCRIPTION

The Register-DataConfiguration cmdlet reads a configuration file (app.config or web.config in most cases), finds the /configuration/connectionStrings and /configuration/system.data/DbProviderFactories sections and, according to their contents, registers connection strings and database provider factories to the ConfigurationManager.

## EXAMPLES

## PARAMETERS

### -ConfigurationFile

A configuration file name.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Void

## NOTES

## RELATED LINKS
