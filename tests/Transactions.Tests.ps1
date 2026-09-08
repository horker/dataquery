Describe 'Atomic database writes' {
    BeforeEach {
        $source = New-DataConnection memory
        $target = New-DataConnection memory
        Invoke-DataQuery $source 'create table Items (Id integer, Value text)'
        Invoke-DataQuery $source "insert into Items values (2, 'first'), (1, 'duplicate')"
        Invoke-DataQuery $target 'create table Items (Id integer primary key, Value text)'
        Invoke-DataQuery $target "insert into Items values (1, 'original')"
    }
    AfterEach {
        Close-DataConnection $source
        Close-DataConnection $target
    }

    It 'rolls back the first insert when the second <Operation> insert violates a constraint' -ForEach @(
        @{ Operation = 'CopyTable' }; @{ Operation = 'CopySql' }; @{ Operation = 'Export' }
    ) {
        $failure = $null
        try {
            if ($Operation -eq 'CopyTable') {
                Copy-DataRow $source 'select * from Items order by rowid' $target Items -ErrorAction Stop
            }
            elseif ($Operation -eq 'CopySql') {
                Copy-DataRow $source 'select * from Items order by rowid' $target -TargetSql 'insert into Items values (@Id, @Value)' -ErrorAction Stop
            }
            else {
                @([pscustomobject]@{ Id = 2; Value = 'first' }, [pscustomobject]@{ Id = 1; Value = 'duplicate' }) |
                    Export-DataTable $target Items -ErrorAction Stop
            }
        }
        catch { $failure = $_ }
        $failure | Should -Not -BeNullOrEmpty
        $failure.Exception.Message | Should -Match 'UNIQUE constraint failed'
        $rows = @(Invoke-DataQuery $target 'select * from Items' -ErrorAction Stop)
        $rows.Count | Should -Be 1
        $rows[0].Id | Should -Be 1
        $rows[0].Value | Should -Be 'original'
        # The caller still owns both connections and can start another transaction.
        $source.State | Should -Be ([System.Data.ConnectionState]::Open)
        $target.State | Should -Be ([System.Data.ConnectionState]::Open)
        $transaction = $target.BeginTransaction()
        try { $transaction.Rollback() } finally { $transaction.Dispose() }
    }
}
