Describe 'Connection ownership after errors' {
    It 'keeps a caller-owned connection usable after a SQL syntax error' {
        $connection = New-DataConnection memory
        try {
            { Invoke-DataQuery $connection 'SELEC 1' -ErrorAction Stop } | Should -Throw '*syntax error*'
            $connection.State | Should -Be ([System.Data.ConnectionState]::Open)
            (Invoke-DataQuery $connection 'select 42 as Value' -ErrorAction Stop).Value | Should -Be 42
        }
        finally { Close-DataConnection $connection }
    }

    It 'releases internally opened files after <Operation> fails' -ForEach @(
        @{ Operation = 'Query' }; @{ Operation = 'Copy' }; @{ Operation = 'Export' }
    ) {
        $sourcePath = Join-Path $TestDrive 'source.db'
        $targetPath = Join-Path $TestDrive 'target.db'
        foreach ($path in $sourcePath, $targetPath) {
            New-Item $path -ItemType File -Force | Out-Null
            Invoke-DataQuery $path 'create table Items (Id integer primary key)' -ErrorAction Stop
            Invoke-DataQuery $path 'insert into Items values (1)' -ErrorAction Stop
        }
        if ($Operation -eq 'Query') {
            { Invoke-DataQuery $sourcePath 'SELEC 1' -ErrorAction Stop } | Should -Throw '*syntax error*'
        }
        elseif ($Operation -eq 'Copy') {
            { Copy-DataRow $sourcePath 'SELEC 1' $targetPath Items -ErrorAction Stop } | Should -Throw '*syntax error*'
        }
        else {
            { [pscustomobject]@{ Id = 1 } | Export-DataTable $targetPath Items -ErrorAction Stop } | Should -Throw '*UNIQUE constraint failed*'
        }
        # An exclusive file handle detects native database handles retained after failure.
        foreach ($path in $sourcePath, $targetPath) {
            $stream = [IO.File]::Open($path, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
            $stream.Dispose()
            (Invoke-DataQuery $path 'select count(*) as Total from Items' -ErrorAction Stop).Total | Should -Be 1
        }
        @(Get-DataConnectionHistory).Count | Should -Be 0
    }
}
