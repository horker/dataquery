using System;
using System.Data;
using System.IO;
using Xunit;

namespace Horker.Data.Tests
{
    public class DuckDbResultTests
    {
        [Fact]
        public void MaterializedBinaryValuesSurviveReaderAndStreamDisposal()
        {
            using var source = new DataTable();
            source.Columns.Add("Payload", typeof(Stream));
            source.Columns.Add("Optional", typeof(string));
            using var stream = new MemoryStream(new byte[] { 0, 255 });
            source.Rows.Add(stream, DBNull.Value);

            DataTable result;
            using (var reader = source.CreateDataReader())
                result = DuckDbSupport.ReadTable(reader);

            using (result)
            {
                Assert.False(stream.CanRead);
                Assert.Equal(typeof(byte[]), result.Columns[0].DataType);
                Assert.Equal(new byte[] { 0, 255 }, Assert.IsType<byte[]>(result.Rows[0][0]));
                Assert.Same(DBNull.Value, result.Rows[0][1]);
            }
        }

        [Fact]
        public void EmptyResultPreservesColumnTypes()
        {
            using var source = new DataTable();
            source.Columns.Add("Id", typeof(long));
            source.Columns.Add("Payload", typeof(Stream));
            using var reader = source.CreateDataReader();
            using var result = DuckDbSupport.ReadTable(reader);
            Assert.Empty(result.Rows);
            Assert.Equal(2, result.Columns.Count);
            Assert.Equal("Id", result.Columns[0].ColumnName);
            Assert.Equal(typeof(long), result.Columns[0].DataType);
            Assert.Equal(typeof(byte[]), result.Columns[1].DataType);
        }
    }
}
