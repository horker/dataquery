Describe 'Database paths follow the PowerShell current location' {
    BeforeEach {
        $originalDirectory = [Environment]::CurrentDirectory
        $folder = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $processFolder = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $folder, $processFolder | Out-Null
        Push-Location $folder
        [Environment]::CurrentDirectory = $processFolder
    }
    AfterEach {
        [Environment]::CurrentDirectory = $originalDirectory
        Pop-Location
    }

    It 'uses the same SQLite file for creation, connection, queries, export, schema and both copy arguments' {
        New-DataDatabase source.sqlite
        New-DataDatabase target.sqlite
        [pscustomobject]@{ Id=42 } | Export-DataTable source.sqlite Items -TypeName INTEGER -ErrorAction Stop
        (Invoke-DataQuery source.sqlite 'select Id from Items' -ErrorAction Stop).Id | Should -Be 42
        @(Get-DataSchema source.sqlite Tables -ErrorAction Stop | Where-Object TABLE_NAME -eq Items).Count | Should -Be 1
        $c = New-DataConnection source.sqlite -ErrorAction Stop
        try { (Invoke-DataQuery $c 'select Id from Items').Id | Should -Be 42 }
        finally { Close-DataConnection $c }
        Invoke-DataQuery target.sqlite 'create table Items (Id integer)' -ErrorAction Stop
        Copy-DataRow source.sqlite 'select * from Items' target.sqlite Items -ErrorAction Stop
        (Invoke-DataQuery target.sqlite 'select Id from Items').Id | Should -Be 42
        [Environment]::CurrentDirectory | Should -Be $processFolder
        @(Get-ChildItem $processFolder -Force).Count | Should -Be 0
    }

    It 'does not accidentally open an identically named file in the process directory' {
        New-DataDatabase same.db
        New-DataDatabase (Join-Path $processFolder 'same.db')
        Invoke-DataQuery (Join-Path $processFolder 'same.db') 'create table WrongFile (Id integer)'
        (Invoke-DataQuery same.db "select count(*) as n from sqlite_master where name='WrongFile'" -ErrorAction Stop).n | Should -Be 0
    }

    It 'preserves registered-name precedence before filesystem resolution' {
        Register-DataConnectionString 'Env:NamedDatabase' System.Data.SQLite 'Data Source=:memory:'
        try { (Invoke-DataQuery 'Env:NamedDatabase' 'select 42 as Id' -ErrorAction Stop).Id | Should -Be 42 }
        finally { Unregister-DataConnectionString 'Env:NamedDatabase' }
        { New-DataConnection 'Env:NamedDatabase' -ErrorAction Stop } | Should -Throw '*FileSystem*'
    }

    It 'supports literal special characters and a session-local filesystem PSDrive' {
        $name = 'data [1] ' + [char]0x65e5 + [char]0x672c + '.sqlite'
        New-DataDatabase $name
        $driveName = 'HorkerPath' + [guid]::NewGuid().ToString('N')
        New-PSDrive -Name $driveName -PSProvider FileSystem -Root $folder | Out-Null
        try {
            $drivePath = $driveName + ':\' + $name
            [pscustomobject]@{ Id=42 } | Export-DataTable $drivePath Items -ErrorAction Stop
            (Invoke-DataQuery $name 'select Id from Items' -ErrorAction Stop).Id | Should -Be 42
            (Invoke-DataQuery (Join-Path $folder $name) 'select Id from Items' -ErrorAction Stop).Id | Should -Be 42
        } finally { Remove-PSDrive $driveName }
    }

    It 'uses relative DuckDB paths throughout the same operations' -Skip:($PSVersionTable.PSEdition -ne 'Core') {
        New-DataDatabase source.duckdb
        New-DataDatabase target.duckdb
        [pscustomobject]@{ Id=42 } | Export-DataTable source.duckdb Items -TypeName INTEGER -ErrorAction Stop
        (Invoke-DataQuery source.duckdb 'select Id from Items').Id | Should -Be 42
        @(Get-DataSchema source.duckdb Tables -ErrorAction Stop).Count | Should -BeGreaterThan 0
        $c = New-DataConnection source.duckdb -ErrorAction Stop
        try { (Invoke-DataQuery $c 'select Id from Items').Id | Should -Be 42 }
        finally { Close-DataConnection $c }
        Invoke-DataQuery target.duckdb 'create table Items (Id integer)'
        Copy-DataRow source.duckdb 'select * from Items' target.duckdb Items -ErrorAction Stop
        (Invoke-DataQuery target.duckdb 'select Id from Items').Id | Should -Be 42
        [Environment]::CurrentDirectory | Should -Be $processFolder
        @(Get-ChildItem $processFolder -Force).Count | Should -Be 0
    }
}
