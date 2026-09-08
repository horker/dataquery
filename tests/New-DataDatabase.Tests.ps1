Describe 'New-DataDatabase' {
    BeforeAll {
        if (-not ('DataQueryDecliningHost' -as [type])) { Add-Type -Path (Join-Path $PSScriptRoot 'helpers/DecliningHost.cs') }
    }
    BeforeEach {
        $folder = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $folder | Out-Null
    }

    It 'creates a valid empty SQLite file for <Extension>' -ForEach @(
        @{Extension='.db'}, @{Extension='.SQLITE'}, @{Extension='.sqlite3'}
    ) {
        $path = Join-Path $folder "sample$Extension"
        @(New-DataDatabase $path -ErrorAction Stop).Count | Should -Be 0
        (Get-Item $path).Length | Should -BeGreaterThan 0
        (Invoke-DataQuery $path "select count(*) as n from sqlite_master where type='table'").n | Should -Be 0
        $stream = [IO.File]::Open($path, 'Open', 'ReadWrite', 'None'); $stream.Dispose()
    }

    It 'resolves literal paths from the PowerShell current location and returns FileInfo' {
        Push-Location $folder
        try {
            $name = 'sample [1] ' + [char]0x65e5 + [char]0x672c + '.db'
            $file = New-DataDatabase $name -PassThru -ErrorAction Stop
            $file | Should -BeOfType ([IO.FileInfo])
            $file.FullName | Should -Be (Join-Path $folder $name)
            Test-Path -LiteralPath $file.FullName | Should -BeTrue
            @(Get-ChildItem -LiteralPath $folder -Force).Count | Should -Be 1
        } finally { Pop-Location }
    }

    It 'accepts explicit types for unknown extensions and rejects ambiguity' {
        New-DataDatabase (Join-Path $folder 'database') -DatabaseType SQLite
        New-DataDatabase (Join-Path $folder 'database.custom') -DatabaseType SQLite
        { New-DataDatabase (Join-Path $folder 'unknown') -ErrorAction Stop } | Should -Throw '*DatabaseType*'
        { New-DataDatabase (Join-Path $folder 'wrong.duckdb') -DatabaseType SQLite -ErrorAction Stop } | Should -Throw '*conflicts*'
        { New-DataDatabase (Join-Path $folder 'wrong.db') -DatabaseType DuckDB -ErrorAction Stop } | Should -Throw '*conflicts*'
        @(Get-ChildItem $folder -Force).Count | Should -Be 2
    }

    It 'rejects invalid paths without creating parent directories' {
        { New-DataDatabase (Join-Path $folder 'missing/data.db') -ErrorAction Stop } | Should -Throw '*parent*'
        { New-DataDatabase $folder -DatabaseType SQLite -Force -ErrorAction Stop } | Should -Throw '*Directories*'
        { New-DataDatabase 'Env:HorkerDatabaseTest' -DatabaseType SQLite -ErrorAction Stop } | Should -Throw '*FileSystem*'
        { New-DataDatabase ':memory:' -DatabaseType SQLite -ErrorAction Stop } | Should -Throw
        @(Get-ChildItem $folder -Force).Count | Should -Be 0
    }

    It 'treats connection names as paths and respects provider removal' {
        $path = Join-Path $folder 'named.db'
        Register-DataConnectionString $path System.Data.SQLite 'Data Source=:memory:'
        try { New-DataDatabase $path; Test-Path $path | Should -BeTrue }
        finally { Unregister-DataConnectionString $path }
        $factory = Get-DbProviderFactory System.Data.SQLite
        try {
            Unregister-DbProviderFactory System.Data.SQLite
            { New-DataDatabase (Join-Path $folder 'unregistered.db') -ErrorAction Stop } | Should -Throw
            Test-Path (Join-Path $folder 'unregistered.db') | Should -BeFalse
        } finally { Register-DbProviderFactory SQLite System.Data.SQLite SQLite $factory.GetType().AssemblyQualifiedName }
    }

    It 'preserves an existing file unless Force is specified' {
        $path = Join-Path $folder 'existing.db'
        [IO.File]::WriteAllText($path, 'original')
        { New-DataDatabase $path -ErrorAction Stop } | Should -Throw '*already exists*'
        [IO.File]::ReadAllText($path) | Should -Be original
        New-DataDatabase $path -Force -Confirm:$false -ErrorAction Stop
        (Invoke-DataQuery $path "select count(*) as n from sqlite_master where type='table'").n | Should -Be 0
    }

    It 'leaves no artifacts under WhatIf for new and existing files' {
        $path = Join-Path $folder 'existing.db'
        [IO.File]::WriteAllText($path, 'original')
        @(New-DataDatabase $path -Force -PassThru -WhatIf).Count | Should -Be 0
        @(New-DataDatabase (Join-Path $folder 'new.db') -PassThru -WhatIf).Count | Should -Be 0
        [IO.File]::ReadAllText($path) | Should -Be original
        @(Get-ChildItem $folder -Force).Count | Should -Be 1
    }

    It 'rejects active connections and read-only files even with Force' {
        $path = Join-Path $folder 'locked.db'
        New-DataDatabase $path
        $c = New-DataConnection $path
        try { { New-DataDatabase $path -Force -ErrorAction Stop } | Should -Throw '*in use*' }
        finally { Close-DataConnection $c }
        [IO.File]::SetAttributes($path, [IO.FileAttributes]::ReadOnly)
        try { { New-DataDatabase $path -Force -ErrorAction Stop } | Should -Throw '*read-only*' }
        finally { [IO.File]::SetAttributes($path, [IO.FileAttributes]::Normal) }
        @(Get-ChildItem $folder -Force).Count | Should -Be 1
    }

    It 'honors confirmation refusal even with Force' {
        $path = Join-Path $folder 'existing.db'
        [IO.File]::WriteAllText($path, 'original')
        $decliningHost = New-Object DataQueryDecliningHost $Host
        $initialState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $entry = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry 'New-DataDatabase', (Get-Command New-DataDatabase).ImplementingType, $null
        $initialState.Commands.Add($entry)
        $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($decliningHost, $initialState)
        $runspace.Open()
        $ps = [powershell]::Create()
        $ps.Runspace = $runspace
        try {
            $null = $ps.AddCommand('New-DataDatabase').AddParameter('Path', $path).AddParameter('Force').AddParameter('PassThru').AddParameter('Confirm', $true)
            @($ps.Invoke()).Count | Should -Be 0
            $ps.HadErrors | Should -BeFalse
            $decliningHost.Prompts | Should -Be 1
        } finally { $ps.Dispose(); $runspace.Dispose() }
        [IO.File]::ReadAllText($path) | Should -Be original
        @(Get-ChildItem $folder -Force).Count | Should -Be 1
    }

    It 'preserves targets with sidecar <Suffix>' -ForEach @(
        @{Suffix='-wal'}, @{Suffix='-shm'}, @{Suffix='-journal'}, @{Suffix='.wal'}
    ) {
        $path = Join-Path $folder 'existing.db'
        [IO.File]::WriteAllText($path, 'original')
        [IO.File]::WriteAllText(($path + $Suffix), 'sidecar')
        { New-DataDatabase $path -Force -ErrorAction Stop } | Should -Throw '*sidecar*'
        [IO.File]::ReadAllText($path) | Should -Be original
        [IO.File]::ReadAllText($path + $Suffix) | Should -Be sidecar
    }

    It 'rejects a directory junction without changing its destination' {
        $target = Join-Path $folder 'target'
        New-Item -ItemType Directory $target | Out-Null
        $junction = Join-Path $folder 'linked.db'
        New-Item -ItemType Junction -Path $junction -Target $target | Out-Null
        try { { New-DataDatabase $junction -Force -ErrorAction Stop } | Should -Throw '*reparse*' }
        finally { [IO.Directory]::Delete($junction) }
        Test-Path $target | Should -BeTrue
    }
}

Describe 'New-DataDatabase DuckDB' -Skip:($PSVersionTable.PSEdition -ne 'Core') {
    It 'creates and replaces empty DuckDB databases and releases their files' {
        $path = Join-Path $TestDrive 'new.DUCKDB'
        $file = New-DataDatabase $path -PassThru -ErrorAction Stop
        $file | Should -BeOfType ([IO.FileInfo])
        (Invoke-DataQuery $path "select count(*) as n from information_schema.tables where table_type='BASE TABLE'").n | Should -Be 0
        Invoke-DataQuery $path 'create table items (id integer)'
        New-DataDatabase $path -Force -Confirm:$false -ErrorAction Stop
        (Invoke-DataQuery $path "select count(*) as n from information_schema.tables where table_type='BASE TABLE'").n | Should -Be 0
        $stream = [IO.File]::Open($path, 'Open', 'ReadWrite', 'None'); $stream.Dispose()
        @(Get-ChildItem $TestDrive -Force).Count | Should -Be 1
    }
    It 'supports explicit DuckDB creation and rejects replacing an open database' {
        $path = Join-Path $TestDrive 'explicit'
        New-DataDatabase $path -DatabaseType DuckDB
        $c = New-DataConnection -ProviderName DuckDB.NET.Data -ConnectionString "Data Source=$path"
        try { { New-DataDatabase $path -DatabaseType DuckDB -Force -ErrorAction Stop } | Should -Throw '*in use*' }
        finally { Close-DataConnection $c }
    }
}

Describe 'New-DataDatabase Desktop' -Skip:($PSVersionTable.PSEdition -ne 'Desktop') {
    It 'rejects DuckDB before touching existing files' {
        $path = Join-Path $TestDrive 'existing.duckdb'
        [IO.File]::WriteAllText($path, 'original')
        { New-DataDatabase $path -Force -ErrorAction Stop } | Should -Throw '*PowerShell 7*'
        [IO.File]::ReadAllText($path) | Should -Be original
        @(Get-ChildItem $TestDrive -Force).Count | Should -Be 1
    }
}
