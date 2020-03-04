---
external help file: Horker.Data.dll-Help.xml
Module Name: HorkerDataQuery
online version:
schema: 2.0.0
---

# Get-DataConnectionHistory

## SYNOPSIS

Gets open database connections in the current session.

## SYNTAX

```
Get-DataConnectionHistory [<CommonParameters>]
```

## DESCRIPTION

The Get-DataConnectionHistory cmdlet gets open database connections in the current session that you have opened explicitly by the New-DataConnection cmdlet,  or implicitly by the other cmdlets you invoked.

This cmdlet is useful when you need to investigate untracked open connections causing a trouble (acquiring a file lock, for example).

## EXAMPLES

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Data.Common.DbConnection

## NOTES

## RELATED LINKS
