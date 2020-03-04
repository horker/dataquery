---
external help file: Horker.Data.dll-Help.xml
Module Name: HorkerDataQuery
online version:
schema: 2.0.0
---

# Invoke-DataQuery

## SYNOPSIS

Executes a database query.

## SYNTAX

### FileOrName
```
Invoke-DataQuery [-FileOrName] <String> [-Query] <String> [[-Parameters] <Object>] [[-Timeout] <Int32>]
 [-ShowRecordsAffected] [-PreserveDbNull] [-AsDataRow] [-AsDataTable] [<CommonParameters>]
```

### Connection
```
Invoke-DataQuery [-Connection] <DbConnection> [-Query] <String> [[-Parameters] <Object>] [[-Timeout] <Int32>]
 [-ShowRecordsAffected] [-PreserveDbNull] [-AsDataRow] [-AsDataTable] [<CommonParameters>]
```

## DESCRIPTION

The Invoke-DataQuery cmdlet executes an SQL statement to a database.

Despite its name, this cmdlet can execute any SQL statement, including INSERT, DELETE and CREATE. When such a statement is executed, no result will return. By specifying the -ShowRecordsAffected parameter, you can get the number of records affected by the statement. You can always obtain the same value by the Get-DataQueryResult cmdlet.

By default, the DBNull values in the result data set are replaced with normal null values, and the results are returned as a stream of PSObject values. You can change this behavior by the -PreserveDbNull, -AsDataRows and -AsDataTable switch parameters.

## EXAMPLES

## PARAMETERS

### -AsDataRow

Indicates to return the result dataset as an array of System.Data.DataRow instead of PSObject.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsDataTable

Indicates to return the result dataset as System.Data.DataTable instead of an array of PSObjects.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
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

### -Parameters

Query parameters.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreserveDbNull

Stops replacing the DBNull values in the results with normal null values.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Query

An SQL statement to be executed.

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

### -ShowRecordsAffected

Specifies whether the number of records affected by the SQL statement should be returned.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Timeout

A query timeout in seconds.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
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

### System.Management.Automation.PSObject

### System.Data.DataRow

### System.Data.DataTable

## NOTES

## RELATED LINKS
