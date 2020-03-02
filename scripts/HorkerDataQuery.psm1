$script:DefaultDbProviderFactories = @(
    @{
        Name = "Odbc Data Provider"
        InvariantName = "System.Data.Odbc"
        Description = ".Net Framework Data Provider for Odbc"
        Type = [System.Data.Odbc.OdbcFactory].AssemblyQualifiedName
    }
    @{
        Name = "OleDb Data Provider"
        InvariantName = "System.Data.OleDb"
        Description = ".Net Framework Data Provider for OleDb"
        Type = [System.Data.OleDb.OleDbFactory].AssemblyQualifiedName
    }
    @{
        Name = "SqlClient Data Provider"
        InvariantName = "System.Data.SqlClient"
        Description = ".Net Framework Data Provider for SqlServer"
        Type = [System.Data.SqlClient.SqlClientFactory].AssemblyQualifiedName
    }
    @{
        Name = "SQLite Data Provider"
        InvariantName = "System.Data.SQLite"
        Description = ".NET Framework Data Provider for SQLite"
        Type = [System.Data.SQLite.SQLiteFactory].AssemblyQualifiedName
    }
    @{
        Name = "Npgsql Data Provider"
        InvariantName = "Npgsql"
        Description = ".Net Data Provider for PostgreSQL"
        Type = [Npgsql.NpgsqlFactory].AssemblyQualifiedName
    }
)

foreach ($f in $DefaultDbProviderFactories) {
    Register-DbProviderFactory $f["Name"] $f["InvariantName"] $f["Description"] $f["Type"]
}

Register-DataConnectionString "memory" "System.Data.SQLite" "Data Source=':memory:'"
