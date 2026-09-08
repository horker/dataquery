Describe 'Query result contracts' {
    BeforeEach {
        $connection = New-DataConnection memory
        Invoke-DataQuery $connection 'create table Items (Id integer, Value text)'
        Invoke-DataQuery $connection 'insert into Items values (1, null), (2, null), (3, null)'
    }
    AfterEach { Close-DataConnection $connection }

    It 'returns <Count> rows in <Mode> mode' -ForEach @(
        @{ Count = 0; Mode = 'Object' }; @{ Count = 1; Mode = 'Object' }; @{ Count = 3; Mode = 'Object' }
        @{ Count = 0; Mode = 'Row' }; @{ Count = 1; Mode = 'Row' }; @{ Count = 3; Mode = 'Row' }
        @{ Count = 0; Mode = 'Table' }; @{ Count = 1; Mode = 'Table' }; @{ Count = 3; Mode = 'Table' }
    ) {
        $options = @{}
        if ($Mode -eq 'Row') { $options.AsDataRow = $true }
        if ($Mode -eq 'Table') { $options.AsDataTable = $true }
        $output = @(Invoke-DataQuery $connection "select * from Items where Id <= $Count order by Id" @options -ErrorAction Stop)
        if ($Mode -eq 'Table') {
            $output.Count | Should -Be 1
            # Piping a DataTable to Should enumerates its rows in PowerShell.
            ($output[0] -is [System.Data.DataTable]) | Should -BeTrue
            $output[0].Columns.Count | Should -Be 2
            $rows = @($output[0].Rows)
        }
        else { $rows = $output }
        $rows.Count | Should -Be $Count
        for ($i = 0; $i -lt $Count; $i++) {
            $rows[$i].Id | Should -Be ($i + 1)
            if ($Mode -eq 'Object') {
                $rows[$i] | Should -Not -BeOfType ([System.Data.DataRow])
                ($null -eq $rows[$i].Value) | Should -BeTrue
            }
            else {
                $rows[$i] | Should -BeOfType ([System.Data.DataRow])
                [object]::ReferenceEquals($rows[$i].Value, [DBNull]::Value) | Should -BeTrue
            }
        }
    }

    It 'preserves DBNull in <Mode> mode when explicitly requested' -ForEach @(
        @{ Mode = 'Object' }; @{ Mode = 'Row' }; @{ Mode = 'Table' }
    ) {
        $options = @{ PreserveDbNull = $true }
        if ($Mode -eq 'Row') { $options.AsDataRow = $true }
        if ($Mode -eq 'Table') { $options.AsDataTable = $true }
        $output = Invoke-DataQuery $connection 'select * from Items where Id = 1' @options -ErrorAction Stop
        $row = if ($Mode -eq 'Table') { $output.Rows[0] } else { $output }
        [object]::ReferenceEquals($row.Value, [DBNull]::Value) | Should -BeTrue
    }

    It 'retains all values for <Case> column names' -ForEach @(
        @{ Case = 'duplicate'; Sql = 'select 10 as Name, 20 as Name'; Names = @('Name', 'Name1'); Values = @(10, 20) }
        @{ Case = 'case-insensitive duplicate'; Sql = 'select 10 as Name, 20 as name'; Names = @('Name', 'name1'); Values = @(10, 20) }
        @{ Case = 'existing suffix'; Sql = 'select 10 as Name, 20 as Name1, 30 as name'; Names = @('Name', 'Name1', 'name2'); Values = @(10, 20, 30) }
        @{ Case = 'empty'; Sql = 'select 10 as "", 20 as ""'; Names = @('Expr1', 'Expr2'); Values = @(10, 20) }
        @{ Case = 'empty and existing fallback'; Sql = 'select 10 as Expr1, 20 as ""'; Names = @('Expr1', 'Expr11'); Values = @(10, 20) }
    ) {
        $rows = @(Invoke-DataQuery $connection "$Sql union all $Sql" -ErrorAction Stop)
        $rows.Count | Should -Be 2
        foreach ($row in $rows) {
            @($row.PSObject.Properties).Count | Should -Be $Names.Count
            for ($i = 0; $i -lt $Names.Count; $i++) {
                $row.PSObject.Properties.Name[$i] | Should -BeExactly $Names[$i]
                $row.($Names[$i]) | Should -Be $Values[$i]
            }
        }
    }
}
