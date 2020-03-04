---
external help file: Horker.Data.dll-Help.xml
Module Name: HorkerDataQuery
online version:
schema: 2.0.0
---

# Register-DbProviderFactory

## SYNOPSIS

Registers a database provider factory to the ConfigurationManager.

## SYNTAX

```
Register-DbProviderFactory [-Name] <String> [-Invariant] <String> [-Description] <String> [-Type] <String>
 [<CommonParameters>]
```

## DESCRIPTION

The Register-DbProviderFactory cmdlet registers a database provider factory to the ConfigurationManager.

## EXAMPLES

## PARAMETERS

### -Description

A human readable description.

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

### -Invariant

An invariant name.

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

### -Name

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

### -Type

An assembly qualified name of the provider's factory class.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
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
