Set-StrictMode -Version 4

$db1 = "$PSScriptRoot\testdb1.db"
$db2 = "$PSScriptRoot\testdb2.db"

Describe "Copy-DataRow" {

    BeforeEach {
        New-Item -Force $db1
        New-Item -Force $db2
        $conn1 = New-DataConnection $db1
        $conn2 = New-DataConnection $db2
    }

    AfterEach {
        Close-DataConnection $conn1
        Close-DataConnection $conn2
        Remove-Item $db1
        Remove-Item $db2
    }

    It "can copy data to another database by the specified SQL" {
        Invoke-DataQuery $conn1 "create table T (a, b, c)"
        Invoke-DataQuery $conn1 "insert into T (a, b, c) values (1, 'foo', 'bar')"
        Invoke-DataQuery $conn1 "insert into T (a, b, c) values (2, 'xxx', 'yyy')"
        Invoke-DataQuery $conn1 "insert into T (a, b, c) values (3, 'nnn', 'mmm')"

        Invoke-DataQuery $conn2 "create table U (x, y)"

        Copy-DataRow $conn1 "select a, c from T where a >= 2" $conn2 -TargetSql "insert into U values (@a, @c)"

        $result = Invoke-DataQuery $conn2 "select * from U"

        $result[0].x | Should -Be 2
        $result[0].y | Should -Be "yyy"
        $result[1].x | Should -Be 3
        $result[1].y | Should -Be "mmm"
    }

    It "can copy data to the specified table of another database" {
        Invoke-DataQuery $conn1 "create table T (a, b, c)"
        Invoke-DataQuery $conn1 "insert into T (a, b, c) values (1, 'foo', 'bar')"
        Invoke-DataQuery $conn1 "insert into T (a, b, c) values (2, 'xxx', 'yyy')"
        Invoke-DataQuery $conn1 "insert into T (a, b, c) values (3, 'nnn', 'mmm')"

        Invoke-DataQuery $conn2 "create table U (x, y)"

        Copy-DataRow $conn1 "select a as y, c as x from T where a >= 2" $conn2 "U"

        $result = Invoke-DataQuery $conn2 "select * from U"

        $result[0].x | Should -Be "yyy"
        $result[0].y | Should -Be 2
        $result[1].x | Should -Be "mmm"
        $result[1].y | Should -Be 3
    }
}
