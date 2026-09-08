using System;
using System.Data;
using System.Data.SQLite;
using Xunit;

namespace Horker.Data.Tests
{
    public class SQLiteProviderTests
    {
        [Fact]
        public void InMemoryDatabaseSupportsParameterizedQueriesAndDataAdapters()
        {
            using var connection = new SQLiteConnection("Data Source=:memory:");
            connection.Open();

            using var command = connection.CreateCommand();
            command.CommandText = "create table Test (Id integer, Value text)";
            command.ExecuteNonQuery();
            command.CommandText = "insert into Test values (@id, @value)";
            command.Parameters.AddWithValue("@id", 42);
            command.Parameters.AddWithValue("@value", DBNull.Value);
            Assert.Equal(1, command.ExecuteNonQuery());

            using var adapter = new SQLiteDataAdapter("select Id, Value from Test", connection);
            using var table = new DataTable();
            Assert.Equal(1, adapter.Fill(table));
            Assert.Equal(42L, table.Rows[0]["Id"]);
            Assert.Equal(DBNull.Value, table.Rows[0]["Value"]);
        }
    }
}
