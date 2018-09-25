Set-StrictMode -Version 4

$ACCESS = "$PSScriptRoot\test.accdb"

Describe "Invoke-DataQuery" {

  BeforeEach {
    $mem = New-DataConnection memory
    Invoke-DataQuery $mem "create table Test (a, b, c)"
  }

  AfterEach {
    Close-DataConnection $mem
  }

  It "can make a query to SQLite" {

    $result = Invoke-DataQuery $mem "insert into Test (a, b, c) values (10, 'abc', null)"
    $result | Should -BeNull
    Get-DataQueryResult | Should -Be 1

    $result = Invoke-DataQuery $mem "select * from Test"

    $result | Should -BeOfType [PSObject]
    $result[0].a | Should -Be 10
    $result[0].b | Should -Be 'abc'
    $result[0].c | Should -Be $null
  }

  It "can take parameters as hashtable" {

    $result = Invoke-DataQuery $mem "insert into Test (a, b, c) values (@a, @b, @c)" @{ a = 10; b = "xxx"; c = $null }
    $result | Should -BeNull
    Get-DataQueryResult | Should -Be 1

    $result = Invoke-DataQuery $mem "select * from Test"

    $result | Should -BeOfType [PSObject]
    $result[0].a | Should -Be 10
    $result[0].b | Should -Be 'xxx'
    $result[0].c | Should -Be $null
  }

  It "can take parameters as array" {

    $result = Invoke-DataQuery $mem "insert into Test (a, b, c) values (?, ?, ?)" @(10, "xxx", $null)
    $result | Should -BeNull
    Get-DataQueryResult | Should -Be 1

    $result = Invoke-DataQuery $mem "select * from Test"

    $result | Should -BeOfType [PSObject]
    $result[0].a | Should -Be 10
    $result[0].b | Should -Be 'xxx'
    $result[0].c | Should -Be $null
  }

  It "can take parameters as single object" {

    $result = Invoke-DataQuery $mem "insert into Test (a, b, c) values (?, 'xxx', 3)" 999
    $result | Should -BeNull
    Get-DataQueryResult | Should -Be 1

    $result = Invoke-DataQuery $mem "select * from Test"

    $result | Should -BeOfType [PSObject]
    $result[0].a | Should -Be 999
  }
}
