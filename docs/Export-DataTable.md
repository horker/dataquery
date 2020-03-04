---
external help file: Horker.Data.dll-Help.xml
Module Name: HorkerDataQuery
online version:
schema: 2.0.0
---

# Export-DataTable

## SYNOPSIS

Inserts objects as data rows into a database table.

## SYNTAX

### FileOrName
```
Export-DataTable [-InputObject <Object>] [-FileOrName] <String> [-TableName] <String>
 [[-AdditionalColumns] <String[]>] [[-TypeName] <String>] [<CommonParameters>]
```

### Connection
```
Export-DataTable [-InputObject <Object>] [-Connection] <DbConnection> [-TableName] <String>
 [[-AdditionalColumns] <String[]>] [[-TypeName] <String>] [<CommonParameters>]
```

## DESCRIPTION

The Export-DataTable cmdlet inserts pipeline objects into a database table specified by the -TableName parameter.

The properties of the objects are mapped to the database columns with the same names. If there are no corresponding columns in the table, such properties are ignored.

If the specified table does not exist, the cmdlet will create a new table based on the structure of the given object. In the current version, all columns are defined as a string type. (This does not matter for SQLite because it allows to apply arithmetic operations to string columns.) If you need a table with exact types, create a table manually by the Invoke-DataQuery cmdlet beforehand.

## EXAMPLES

## PARAMETERS

### -AdditionalColumns

Additional column names.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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

### -InputObject

Objects to be inserted into a database table.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -TableName

A table name into which objects will be inserted.

The value is used without being quoted when the cmdlet generates internal SQL statements. Thus, you should specify this parameter with explicit quotes if necessary.

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

### -TypeName

A type of columns of a newly created table. By default, it is one of 'varchar' (general databases), 'nvarchar' (SQL Server), 'varchar2' (Oracle), or an empty string (SQLite).

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Object

## OUTPUTS

### System.Void

## NOTES

## RELATED LINKS
