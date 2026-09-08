Describe 'Runtime compatibility' {
    BeforeEach {
        $modulePath = (Join-Path (Get-Module HorkerDataQuery).ModuleBase 'HorkerDataQuery.psd1')
        $sqliteType = (Get-DbProviderFactory System.Data.SQLite).GetType().AssemblyQualifiedName
    }

    AfterEach {
        Import-Module $modulePath -Force -Global -ErrorAction Stop
        if ((Get-DataConnectionString).GetEnumerator() | Where-Object Name -eq 'compat') { Unregister-DataConnectionString compat }
        Unregister-DbProviderFactory Horker.Compat
    }

    It 'replaces, lists and removes a provider without falling back to system registration' {
        Register-DbProviderFactory Test Horker.Compat Test $sqliteType
        Register-DbProviderFactory Replacement Horker.Compat Test $sqliteType
        @((Get-DbProviderFactory).Rows | Where-Object InvariantName -eq 'Horker.Compat').Count | Should -Be 1
        New-DataConnectionString Horker.Compat @{ 'Data Source' = ':memory:' } | Should -Match 'memory'
        Unregister-DbProviderFactory Horker.Compat
        { New-DataConnectionString Horker.Compat @{} -ErrorAction Stop } | Should -Throw
        Unregister-DbProviderFactory System.Data.Odbc
        { Get-DbProviderFactory System.Data.Odbc -ErrorAction Stop } | Should -Throw
    }

    It 'adds, reads and removes connection strings after an unsuccessful duplicate registration' {
        Register-DataConnectionString compat System.Data.SQLite 'Data Source=:memory:'
        { Register-DataConnectionString compat System.Data.SQLite 'Data Source=:memory:' -ErrorAction Stop } | Should -Throw
        ((Get-DataConnectionString).GetEnumerator() | Where-Object Name -eq 'compat').ProviderName | Should -Be 'System.Data.SQLite'
        $connection = New-DataConnection compat
        Close-DataConnection $connection
        Unregister-DataConnectionString compat
        @((Get-DataConnectionString).GetEnumerator() | Where-Object Name -eq 'compat').Count | Should -Be 0
        Register-DataConnectionString compat System.Data.SQLite 'Data Source=:memory:'
    }

    It 'applies configuration add, remove and clear operations in memory' {
        $path = Join-Path $TestDrive 'app.config'
        @"
<configuration>
  <system.data><DbProviderFactories><clear/>
    <add name="Temporary" invariant="Temporary" description="Test" type="$sqliteType"/>
    <remove invariant="Temporary"/>
    <add name="Test" invariant="Horker.Compat" description="Test" type="$sqliteType"/>
  </DbProviderFactories></system.data>
  <connectionStrings><clear/>
    <add name="Temporary" providerName="Horker.Compat" connectionString="Data Source=:memory:"/>
    <remove name="Temporary"/>
    <add name="compat" providerName="Horker.Compat" connectionString="Data Source=:memory:"/>
  </connectionStrings>
</configuration>
"@ | Set-Content $path
        Register-DataConfiguration $path -ErrorAction Stop
        (Get-DbProviderFactory).Rows.Count | Should -Be 1
        (Get-DataConnectionString).Count | Should -Be 1
        { Get-DbProviderFactory System.Data.Odbc -ErrorAction Stop } | Should -Throw
        $connection = New-DataConnection compat
        try { (Invoke-DataQuery $connection 'select 7 as Value').Value | Should -Be 7 }
        finally { Close-DataConnection $connection }
    }

    It 'exports objects, reads table schema and closes a SQLite connection' {
        $connection = New-DataConnection memory
        try {
            [pscustomobject]@{ Id = 3; Value = 'example' } | Export-DataTable $connection Items -ErrorAction Stop
            (Invoke-DataQuery $connection 'select * from Items').Value | Should -Be 'example'
            @(Get-DataSchema $connection Tables | Where-Object TABLE_NAME -eq 'Items').Count | Should -Be 1
        }
        finally { Close-DataConnection $connection }
        { $connection.Open() } | Should -Throw
        @(Get-DataConnectionHistory | Where-Object { [object]::ReferenceEquals($_, $connection) }).Count | Should -Be 0
    }
}
