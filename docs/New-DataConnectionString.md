---
external help file: Horker.Data.dll-Help.xml
Module Name: HorkerDataQuery
online version:
schema: 2.0.0
---

# New-DataConnectionString

## SYNOPSIS

Creates a connection string based on the given parameters.

## SYNTAX

```
New-DataConnectionString [-ProviderName] <String> [-Parameters] <Hashtable> [-TestConnection]
 [<CommonParameters>]
```

## DESCRIPTION

The New-DataConnectionString cmdlet creates a connection string based on parameters for a specific database provider.

When the -TestConnection parameter is specified, the cmdlet tries to connect to a database with a newly created connection string.

## EXAMPLES

## PARAMETERS

### -Parameters

A set of parameters that should be included in a connection string.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
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
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TestConnection

Makes the cmdlet to test connectivity of a generated connection string.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.String

## NOTES

## RELATED LINKS
