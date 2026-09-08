Describe 'Module dependency loading' {
    It 'loads each bundled provider from the module directory' -ForEach @(
        @{ Provider = 'System.Data.Odbc' }
        @{ Provider = 'System.Data.OleDb' }
        @{ Provider = 'System.Data.SqlClient' }
        @{ Provider = 'System.Data.SQLite' }
        @{ Provider = 'Npgsql' }
    ) {
        $factory = Get-DbProviderFactory $Provider
        $module = Get-Module HorkerDataQuery
        (Split-Path $factory.GetType().Assembly.Location) | Should -Be $module.ModuleBase
        $connection = $factory.CreateConnection()
        try {
            $connection | Should -BeOfType ([System.Data.Common.DbConnection])
        }
        finally {
            $connection.Dispose()
        }
    }

    It 'can register a bundled provider by its assembly-qualified type name' {
        $factory = Get-DbProviderFactory System.Data.Odbc
        try {
            Register-DbProviderFactory 'Test provider' 'Horker.Test' 'Test provider' $factory.GetType().AssemblyQualifiedName
            [object]::ReferenceEquals((Get-DbProviderFactory Horker.Test), $factory) | Should -BeTrue
        }
        finally {
            Unregister-DbProviderFactory Horker.Test
        }
    }

    It 'exports the query alias' {
        (Get-Alias idq).ResolvedCommand.Name | Should -Be 'Invoke-DataQuery'
    }
}
