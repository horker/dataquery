Describe 'DuckDB on Core' -Skip:($PSVersionTable.PSEdition -ne 'Core') {
    BeforeEach { $c = New-DataConnection duckdb-memory -ErrorAction Stop }
    AfterEach { if ($c) { Close-DataConnection $c } }

    It 'loads the bundled factory and preserves a live connection across reimport' {
        $module = Get-Module HorkerDataQuery
        (Get-DbProviderFactory DuckDB.NET.Data).GetType().Assembly.Location | Should -Be (Join-Path $module.ModuleBase 'lib/net10.0/DuckDB.NET.Data.dll')
        @((Get-Process -Id $PID).Modules | Where-Object ModuleName -eq 'duckdb.dll')[0].FileName | Should -Be (Join-Path $module.ModuleBase 'lib/net10.0/duckdb.dll')
        Invoke-DataQuery $c 'create table saved (i integer)'
        Import-Module (Join-Path $module.ModuleBase 'HorkerDataQuery.psd1') -Force -Global
        (Invoke-DataQuery $c 'select count(*) as n from saved').n | Should -Be 0
        @((Get-DataConnectionString).GetEnumerator() | Where-Object Name -eq duckdb-memory).Count | Should -Be 1
    }

    It 'returns <Count> rows in <Mode> mode with NULL and schema' -ForEach @(
        @{ Count=0; Mode='Object' }; @{ Count=1; Mode='Object' }; @{ Count=3; Mode='Object' }
        @{ Count=0; Mode='Row' }; @{ Count=1; Mode='Row' }; @{ Count=3; Mode='Row' }
        @{ Count=0; Mode='Table' }; @{ Count=1; Mode='Table' }; @{ Count=3; Mode='Table' }
    ) {
        $options = @{}
        if ($Mode -eq 'Row') { $options.AsDataRow = $true }
        if ($Mode -eq 'Table') { $options.AsDataTable = $true }
        $result = @(Invoke-DataQuery $c "select range as Id, cast(null as varchar) as Value from range($Count)" @options -ErrorAction Stop)
        if ($Mode -eq 'Table') {
            $result.Count | Should -Be 1
            $result[0].Columns.Count | Should -Be 2
            $result[0].Columns[0].DataType | Should -Be ([long])
            $rows = @($result[0].Rows)
        } else { $rows = $result }
        $rows.Count | Should -Be $Count
        foreach ($row in $rows) {
            if ($Mode -eq 'Object') { ($null -eq $row.Value) | Should -BeTrue }
            else { [object]::ReferenceEquals($row.Value, [DBNull]::Value) | Should -BeTrue }
        }
    }

    It 'binds positional and named parameters without rewriting SQL' {
        (Invoke-DataQuery $c 'select ? + ? as v' @(20,22) -ErrorAction Stop).v | Should -Be 42
        (Invoke-DataQuery $c 'select $1 as v' 42 -ErrorAction Stop).v | Should -Be 42
        (Invoke-DataQuery $c 'select $value as v' @{ value=42 } -ErrorAction Stop).v | Should -Be 42
        (Invoke-DataQuery $c 'select $value as v' @{ '$value'=42 } -ErrorAction Stop).v | Should -Be 42
        { Invoke-DataQuery $c 'select @value as v' @{ value=42 } -ErrorAction Stop } | Should -Throw
        { Invoke-DataQuery $c 'select $value' @{ value=1; '$value'=2 } -ErrorAction Stop } | Should -Throw '*unique*'
        $row = Invoke-DataQuery $c 'select $a as a, $b as b' @{ a=$null; b=[DBNull]::Value } -PreserveDbNull -ErrorAction Stop
        [object]::ReferenceEquals($row.a, [DBNull]::Value) | Should -BeTrue
        [object]::ReferenceEquals($row.b, [DBNull]::Value) | Should -BeTrue
    }

    It 'preserves standard CLR values in <Mode> output' -ForEach @(@{Mode='Object'}, @{Mode='Table'}) {
        $options = @{}
        if ($Mode -eq 'Table') { $options.AsDataTable=$true }
        $result = Invoke-DataQuery $c "select 42::INTEGER as i, 123456789012::BIGINT as l, 12.34::DECIMAL(8,2) as d, 1.5::DOUBLE as f, true as b, '日本語' as s, TIMESTAMP '2026-01-02 03:04:05' as t, from_hex('00FF') as bytes" @options -ErrorAction Stop
        $row = if ($Mode -eq 'Table') { $result.Rows[0] } else { $result }
        $row.i | Should -BeOfType ([int]); $row.l | Should -BeOfType ([long])
        $row.d | Should -Be ([decimal]12.34); $row.f | Should -Be 1.5
        $row.b | Should -BeTrue; $row.s | Should -Be '日本語'
        $row.t | Should -Be ([datetime]'2026-01-02T03:04:05')
        [Convert]::ToBase64String($row.bytes) | Should -Be 'AP8='
    }

    It 'retains colliding column names in <Mode> output' -ForEach @(@{Mode='Object'}, @{Mode='Row'}, @{Mode='Table'}) {
        $options=@{}
        if ($Mode -eq 'Row') { $options.AsDataRow=$true }
        if ($Mode -eq 'Table') { $options.AsDataTable=$true }
        $result=Invoke-DataQuery $c 'select 10 as Name, 20 as Name1, 30 as name' @options -ErrorAction Stop
        $row=if ($Mode -eq 'Table') { $result.Rows[0] } else { $result }
        $row.Name | Should -Be 10; $row.Name1 | Should -Be 20; $row.name2 | Should -Be 30
    }

    It 'creates files explicitly, recognizes existing mixed-case suffixes and supports read-only access' {
        $path=Join-Path $TestDrive 'file.DuCkDb'
        { New-DataConnection $path -ErrorAction Stop } | Should -Throw '*ConnectionString*'
        Test-Path $path | Should -BeFalse
        $file=New-DataConnection -ProviderName DuckDB.NET.Data -ConnectionString "Data Source=$path" -ErrorAction Stop
        try { Invoke-DataQuery $file 'create table items (i integer)' -ErrorAction Stop } finally { Close-DataConnection $file }
        (Invoke-DataQuery $path 'select count(*) as n from items' -ErrorAction Stop).n | Should -Be 0
        $file=New-DataConnection -ProviderName DuckDB.NET.Data -ConnectionString "Data Source=$path;access_mode=READ_ONLY" -ErrorAction Stop
        try { { Invoke-DataQuery $file 'insert into items values (1)' -ErrorAction Stop } | Should -Throw }
        finally { Close-DataConnection $file }
        $stream=[IO.File]::Open($path, 'Open', 'ReadWrite', 'None'); $stream.Dispose()
        Remove-Item $path -ErrorAction Stop
    }

    It 'exports new and existing schema-qualified tables with quoted columns and explicit types' {
        Invoke-DataQuery $c 'create schema analytics'
        [pscustomobject]@{ 'a"b'='first'; Value=$null } | Export-DataTable $c analytics.items -ErrorAction Stop
        [pscustomobject]@{ 'a"b'='second'; Value='value' } | Export-DataTable $c analytics.items -ErrorAction Stop
        $rows=@(Invoke-DataQuery $c 'select * from analytics.items order by "a""b"' -ErrorAction Stop)
        $rows.Count | Should -Be 2; $rows[0].'a"b' | Should -Be first
        ($null -eq $rows[0].Value) | Should -BeTrue
        (Invoke-DataQuery $c "select data_type as t from information_schema.columns where table_name='items' limit 1").t | Should -Be VARCHAR
        [pscustomobject]@{ i=42 } | Export-DataTable $c typed -TypeName INTEGER -ErrorAction Stop
        (Invoke-DataQuery $c 'select i from typed').i | Should -BeOfType ([int])
        { [pscustomobject]@{ i=1 } | Export-DataTable $c 'items where invalid syntax' -ErrorAction Stop } | Should -Throw '*Parser*'
    }

    It 'copies <Source> to <Target> using <Mode> SQL' -ForEach @(
        @{Source='duckdb-memory';Target='duckdb-memory';Mode='Generated'}
        @{Source='memory';Target='duckdb-memory';Mode='Generated'}
        @{Source='duckdb-memory';Target='memory';Mode='Generated'}
        @{Source='duckdb-memory';Target='duckdb-memory';Mode='Explicit'}
        @{Source='memory';Target='duckdb-memory';Mode='Explicit'}
        @{Source='duckdb-memory';Target='memory';Mode='Explicit'}
    ) {
        $src=New-DataConnection $Source; $dst=New-DataConnection $Target
        try {
            Invoke-DataQuery $src 'create table items (Id integer, Value varchar)'
            Invoke-DataQuery $src "insert into items values (1, 'first'), (2, null)"
            Invoke-DataQuery $dst 'create table items (Id integer, Value varchar)'
            if ($Mode -eq 'Generated') { Copy-DataRow $src 'select * from items' $dst items -ErrorAction Stop }
            else {
                $sql=if ($Target -eq 'memory') { 'insert into items values (@Id,@Value)' } else { 'insert into items values ($Id,$Value)' }
                Copy-DataRow $src 'select * from items' $dst -TargetSql $sql -ErrorAction Stop
            }
            $rows=@(Invoke-DataQuery $dst 'select * from items order by Id')
            $rows.Count | Should -Be 2; $rows[0].Value | Should -Be first
            ($null -eq $rows[1].Value) | Should -BeTrue
        } finally { Close-DataConnection $src; Close-DataConnection $dst }
    }

    It 'rolls back partial <Operation> writes and preserves the original error and external connection' -ForEach @(@{Operation='Copy'}, @{Operation='Export'}) {
        Invoke-DataQuery $c 'create table items (Id integer primary key)'
        Invoke-DataQuery $c 'insert into items values (1)'
        if ($Operation -eq 'Export') {
            { @([pscustomobject]@{Id=2}, [pscustomobject]@{Id=1}) | Export-DataTable $c items -ErrorAction Stop } | Should -Throw '*Duplicate key*'
        } else {
            { Copy-DataRow $c 'select 2 as Id union all select 1 as Id' $c items -ErrorAction Stop } | Should -Throw '*Duplicate key*'
        }
        (Invoke-DataQuery $c 'select count(*) as n from items' -ErrorAction Stop).n | Should -Be 1
        $tx=$c.BeginTransaction(); try { $tx.Rollback() } finally { $tx.Dispose() }
    }

    It 'rejects timeouts before writes and reports unknown affected rows' {
        Invoke-DataQuery $c 'create table items (Id integer)'
        { Invoke-DataQuery $c 'insert into items values (1)' -Timeout 1 -ErrorAction Stop } | Should -Throw '*Timeout*'
        { Copy-DataRow $c 'insert into items values (1) returning Id' $c items -Timeout 1 -ErrorAction Stop } | Should -Throw '*Timeout*'
        { Invoke-DataQuery $c 'insert into items values (1)' -Timeout -1 -ErrorAction Stop } | Should -Throw
        (Invoke-DataQuery $c 'select count(*) as n from items').n | Should -Be 0
        Invoke-DataQuery $c 'insert into items values (1)' -Timeout 0 -ShowRecordsAffected -ErrorAction Stop | Should -Be -1
        (Get-DataQueryResult) | Should -Be -1
        { Invoke-DataQuery $c 'invalid SQL' -ErrorAction Stop } | Should -Throw
        (Invoke-DataQuery $c 'select 42 as v' -ErrorAction Stop).v | Should -Be 42
    }

    It 'delegates supported schema collections and rejects unknown collections' {
        Invoke-DataQuery $c 'create table items (Id integer)'
        @(Get-DataSchema $c -ErrorAction Stop).Count | Should -BeGreaterThan 0
        @(Get-DataSchema $c Tables -ErrorAction Stop).Count | Should -BeGreaterThan 0
        @(Get-DataSchema $c Columns -ErrorAction Stop).Count | Should -BeGreaterThan 0
        { Get-DataSchema $c InvalidCollection -ErrorAction Stop } | Should -Throw
    }

    It 'gives registered names precedence and accepts explicit extensionless files' {
        $name=Join-Path $TestDrive 'registered.duckdb'
        Register-DataConnectionString $name System.Data.SQLite 'Data Source=:memory:'
        try {
            $named=New-DataConnection $name -ErrorAction Stop
            try { $named.GetType().FullName | Should -Be System.Data.SQLite.SQLiteConnection }
            finally { Close-DataConnection $named }
            Test-Path $name | Should -BeFalse
        } finally { Unregister-DataConnectionString $name }
        $path=Join-Path $TestDrive 'extensionless'
        $file=New-DataConnection -ProviderName DuckDB.NET.Data -ConnectionString "Data Source=$path"
        try { (Invoke-DataQuery $file 'select 42 as v').v | Should -Be 42 } finally { Close-DataConnection $file }
        Test-Path $path | Should -BeTrue
    }

    It 'releases owned files after <Operation> fails' -ForEach @(@{Operation='Query'}, @{Operation='Copy'}, @{Operation='Export'}, @{Operation='Schema'}) {
        $path=Join-Path $TestDrive "owned-$Operation.duckdb"
        $file=New-DataConnection -ProviderName DuckDB.NET.Data -ConnectionString "Data Source=$path"
        try { Invoke-DataQuery $file 'create table items (Id integer primary key); insert into items values (1)' }
        finally { Close-DataConnection $file }
        {
            switch ($Operation) {
                Query { Invoke-DataQuery $path 'invalid SQL' -ErrorAction Stop }
                Copy { Copy-DataRow $path 'select 2 as Id union all select 1 as Id' $path items -ErrorAction Stop }
                Export { @([pscustomobject]@{Id=2}, [pscustomobject]@{Id=1}) | Export-DataTable $path items -ErrorAction Stop }
                Schema { Get-DataSchema $path InvalidCollection -ErrorAction Stop }
            }
        } | Should -Throw
        $stream=[IO.File]::Open($path, 'Open', 'ReadWrite', 'None'); $stream.Dispose()
        (Invoke-DataQuery $path 'select count(*) as n from items' -ErrorAction Stop).n | Should -Be 1
    }

    It 'rejects copy timeouts with DuckDB on the <Side> before source or target writes' -ForEach @(@{Side='Source'}, @{Side='Target'}) {
        $sqlite=New-DataConnection memory
        try {
            Invoke-DataQuery $sqlite 'create table items (Id integer)'
            Invoke-DataQuery $c 'create table items (Id integer)'
            $src=if ($Side -eq 'Source') { $c } else { $sqlite }
            $dst=if ($Side -eq 'Target') { $c } else { $sqlite }
            { Copy-DataRow $src 'insert into items values (1) returning Id' $dst items -Timeout 1 -ErrorAction Stop } | Should -Throw '*Timeout*'
            (Invoke-DataQuery $sqlite 'select count(*) as n from items').n | Should -Be 0
            (Invoke-DataQuery $c 'select count(*) as n from items').n | Should -Be 0
        } finally { Close-DataConnection $sqlite }
    }

    It 'binds and copies binary data while safely quoting generated column names' {
        $sqlite=New-DataConnection memory
        try {
            Invoke-DataQuery $c 'create table items ("a""b" blob)'
            Invoke-DataQuery $c 'insert into items values ($bytes)' @{ bytes=[byte[]]@(0,255) } -ErrorAction Stop
            Invoke-DataQuery $sqlite 'create table items (bytes blob)'
            Copy-DataRow $c 'select "a""b" as bytes from items' $sqlite items -ErrorAction Stop
            [Convert]::ToBase64String((Invoke-DataQuery $sqlite 'select bytes from items').bytes) | Should -Be 'AP8='
            Copy-DataRow $sqlite 'select bytes as "a""b" from items' $c items -ErrorAction Stop
            $rows=@(Invoke-DataQuery $c 'select "a""b" as bytes from items')
            $rows.Count | Should -Be 2
            foreach ($row in $rows) { [Convert]::ToBase64String($row.bytes) | Should -Be 'AP8=' }
        } finally { Close-DataConnection $sqlite }
    }

    It 'copies within one DuckDB connection using named source parameters' {
        Invoke-DataQuery $c 'create table items (Id integer)'
        Copy-DataRow $c 'select $value as Id' $c items -SourceParameters @{ '$value'=42 } -ErrorAction Stop
        (Invoke-DataQuery $c 'select Id from items').Id | Should -Be 42
    }

    It 'honors provider removal for factory lookup from a connection' {
        $factory=Get-DbProviderFactory DuckDB.NET.Data
        try {
            Unregister-DbProviderFactory DuckDB.NET.Data
            { Invoke-DataQuery $c 'select 1' -AsDataTable -ErrorAction Stop } | Should -Throw
        } finally { Register-DbProviderFactory DuckDB DuckDB.NET.Data DuckDB $factory.GetType().AssemblyQualifiedName }
    }
}

Describe 'DuckDB on Desktop' -Skip:($PSVersionTable.PSEdition -ne 'Desktop') {
    It 'does not bundle or register DuckDB and reports host requirements' {
        $module=Get-Module HorkerDataQuery
        @(Get-ChildItem (Join-Path $module.ModuleBase 'lib/net48') -Recurse -Filter '*duckdb*').Count | Should -Be 0
        @([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object FullName -Like 'DuckDB*').Count | Should -Be 0
        @((Get-DataConnectionString).GetEnumerator() | Where-Object Name -eq duckdb-memory).Count | Should -Be 0
        { Get-DbProviderFactory DuckDB.NET.Data -ErrorAction Stop } | Should -Throw '*PowerShell 7*'
        { New-DataConnection -ProviderName DuckDB.NET.Data -ConnectionString 'Data Source=:memory:' -ErrorAction Stop } | Should -Throw '*PowerShell 7*'
        { New-DataConnection (Join-Path $TestDrive 'missing.duckdb') -ErrorAction Stop } | Should -Throw '*PowerShell 7*'
    }
}
