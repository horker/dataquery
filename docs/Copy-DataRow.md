---
external help file: Horker.Data.dll-Help.xml
Module Name: HorkerDataQuery
online version:
schema: 2.0.0
---

# Copy-DataRow

## SYNOPSIS

Copy data from one database to another.

## SYNTAX

```
Copy-DataRow [-SourceConnection] <ConnectionSpecifier> [-SourceSql] <String>
 [-TargetConnection] <ConnectionSpecifier> [[-TargetTable] <String>] [[-SourceParameters] <Object>]
 [[-TargetSql] <String>] [[-Timeout] <Int32>] [<CommonParameters>]
```

## DESCRIPTION

The Copy-DataRow cmdlet obtains a dataset from a database specified by the -SourceConnection parameter by executing the -SourceSql statement and inserts them to another database specified bu the -TargetConnection parameter.

When you specify a target table name by the -TargetTable parameter, the cmdlet assumes the table contains the same set of columns as the source dataset and inserts them into the corresponding columns.

When you specify a SQL statement by the -TargetSql parameter, the cmdlet executes it for each data row of the source dataset. The SQL statement should contain named parameters corresponding to the columns of the source dataset.

You can specify either one of the -TargetTable or -TargetSql parameters.

## EXAMPLES

## PARAMETERS

### -SourceConnection

A DbConnection object, a connection string name or a database file name (SQLite or Access) of the source database.

```yaml
Type: ConnectionSpecifier
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceParameters

Query parameters applied to the -SourceSql statement.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceSql

An SQL statement to obtain data from the source database.

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

### -TargetConnection

A DbConnection object, a connection string name or a database file name (SQLite or Access) of the target database.

```yaml
Type: ConnectionSpecifier
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetSql

An SQL statement to be used for copying the data. It is usually an INSERT or UPDATE statement with the corresponding named parameters to the columns of the source dataset.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TargetTable

A name of the table into which data will be inserted.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Timeout

A timeout in seconds.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
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
