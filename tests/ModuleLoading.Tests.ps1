Describe 'Module dependency loading' {
    It 'loads each provider from the correct runtime directory' -ForEach @(
        @{ Provider = 'System.Data.Odbc' }
        @{ Provider = 'System.Data.OleDb' }
        @{ Provider = 'System.Data.SqlClient' }
        @{ Provider = 'System.Data.SQLite' }
    ) {
        $factory = Get-DbProviderFactory $Provider
        $module = Get-Module HorkerDataQuery
        if ($PSVersionTable.PSEdition -eq 'Desktop' -and $Provider -ne 'System.Data.SQLite') {
            $factory.GetType().Assembly.Location | Should -Be ([System.Data.Common.DbConnection].Assembly.Location)
        }
        else {
            $target = if ($PSVersionTable.PSEdition -eq 'Desktop') { 'net48' } else { 'net10.0' }
            (Split-Path $factory.GetType().Assembly.Location) | Should -Be (Join-Path $module.ModuleBase "lib\$target")
        }
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

    It 'only bundles PostgreSQL in the Core target' {
        $module = Get-Module HorkerDataQuery
        Test-Path (Join-Path $module.ModuleBase 'lib\net48\Npgsql.dll') | Should -BeFalse
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            { Get-DbProviderFactory Npgsql -ErrorAction Stop } | Should -Throw
        }
        else {
            (Get-DbProviderFactory Npgsql).GetType().Assembly.Location | Should -Be (Join-Path $module.ModuleBase 'lib\net10.0\Npgsql.dll')
        }
    }

    It 'can be reimported without replacing live connection types or duplicating memory' {
        $connection = New-DataConnection memory
        try {
            Import-Module (Join-Path (Get-Module HorkerDataQuery).ModuleBase 'HorkerDataQuery.psd1') -Force -Global -ErrorAction Stop
            if ($PSVersionTable.PSEdition -eq 'Core') {
                [System.Runtime.Loader.AssemblyLoadContext]::GetLoadContext((Get-Command Invoke-DataQuery).ImplementingType.Assembly).Name | Should -Be 'HorkerDataQuery'
            }
            (Invoke-DataQuery $connection 'select 42 as Value').Value | Should -Be 42
            @((Get-DataConnectionString).GetEnumerator() | Where-Object Name -eq 'memory').Count | Should -Be 1
        }
        finally { Close-DataConnection $connection }
    }
}
