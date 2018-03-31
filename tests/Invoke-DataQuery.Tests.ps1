Set-StrictMode -Version 4

$ACCESS = "$PSScriptRoot\test.accdb"

describe "Invoke-DataQuery" {

  It "can make a query to SQLite" {

    $mem = New-DataConnection memory

    $result = Invoke-DataQuery $mem "create table Test (a,b,c)"
    $result | Should -BeNull

    $result = Invoke-DataQuery $mem "insert into Test (a,b,c) values (10, 'abc', null)"
    $result | Should -BeNull
    Get-DataQueryResult | Should -Be 1

    $result = Invoke-DataQuery $mem "select * from Test"

    $result | Should -BeOfType [PSObject]
    $result[0].a | Should -Be 10
    $result[0].b | Should -Be 'abc'
    $result[0].c | Should -Be $null

    Close-DataConnection $mem
  }

}
