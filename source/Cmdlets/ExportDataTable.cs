using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Management.Automation;
using System.Text;

#pragma warning disable CS1591

namespace Horker.Data
{
    /// <summary>
    /// <para type="synopsis">Inserts objects into a database table.</para>
    /// <para type="description">The Export-DataTable cmdlet inserts objects from the pipeline into a database table specified by the -TableName parameter.</para>
    /// <para type="description">The properties of the objects are mapped to the database columns with the same names. If there are no corresponding columns in the table, such properties are ignored.</para>
    /// <para type="description">If the specified table does not exist, the cmdlet will create a new table based on the structure of the given object. In the current version, all columns are defined as a string type. (This does not matter for SQLite because it allows to apply arithmetic operations to string columns.) If you need a table with exact types, create a table manually by the Invoke-DataQuery cmdlet beforehand.</para>
    /// </summary>
    [Cmdlet("Export", "DataTable")]
    [OutputType(typeof(void))]
    public class ExportDataTable : PSCmdlet
    {
        /// <summary>
        /// <para type="description">Objects to be inserted into a database table.</para>
        /// </summary>
        [Parameter(ValueFromPipeline = true)]
        public object InputObject { get; set; }

        /// <summary>
        /// <para type="description">A database file name or a connection string name.</para>
        /// </summary>
        [Parameter(Position = 0, ParameterSetName = "FileOrName", Mandatory = true)]
        public string FileOrName { get; set; }

        /// <summary>
        /// <para type="description">A database connection.</para>
        /// </summary>
        [Parameter(Position = 0, ParameterSetName = "Connection", Mandatory = true)]
        public DbConnection Connection { get; set; }

        /// <summary>
        /// <para type="description">A table name into which objects will be inserted. The value is embeded without being quoted into SQL statements that the cmdlet generates internally.</para>
        /// </summary>
        [Parameter(Position = 1, Mandatory = true)]
        public string TableName { get; set; }

        /// <summary>
        /// <para type="description">Additional column names.</para>
        /// </summary>
        [Parameter(Position = 2, Mandatory = false)]
        public string[] AdditionalColumns { get; set; }

        /// <summary>
        /// <para type="description">A type of columns of a newly created table. By default, it is one of 'varchar' (general databases), 'nvarchar' (SQL Server), 'varchar2' (Oracle), or an empty string (SQLite).</para>
        /// </summary>
        [Parameter(Position = 3, Mandatory = false)]
        public string TypeName { get; set; }

        private DbConnection _connection;
        private bool _connectionOpened;
        private DbProviderFactory _factory;
        private DbCommandBuilder _builder;

        private string _qualifiedTableName;

        private HashSet<string> _fieldSet;
        private string _insertStmt;

        private bool _useNamedParameters;

        private DbTransaction _transaction;

        private void DisposeResources()
        {
            if (_connectionOpened)
            {
                if (_connection.State == ConnectionState.Open)
                    _connection.Close();

                try
                {
                    _connection.Dispose();
                }
                catch (ObjectDisposedException) {}
            }

            if (_builder != null)
            {
                try
                {
                    _builder.Dispose();
                }
                catch (ObjectDisposedException) {}
            }

            if (_transaction != null)
            {
                try
                {
                    _transaction.Dispose();
                }
                catch (ObjectDisposedException) {}
            }
        }

        protected override void BeginProcessing()
        {
            var opener = new ConnectionSpecifier(FileOrName, Connection, null, null);
            _connection = opener.Connection;
            _connectionOpened = opener.ConnectionOpened;

            try
            {
                if (_connection == null)
                {
                    WriteError(new ErrorRecord(new RuntimeException("Can't open a connection"), "", ErrorCategory.NotSpecified, null));
                    throw new PipelineStoppedException();
                }

                // ODBC and OLEDB Access connections fail to obtain the corresponding factories.
                if (_connection is System.Data.Odbc.OdbcConnection)
                {
                    _factory = DbProviderFactories.GetFactory("System.Data.Odbc");
                }
                else if (_connection is System.Data.OleDb.OleDbConnection)
                {
                    _factory = DbProviderFactories.GetFactory("System.Data.OleDb");
                }
                else
                {
                    _factory = DbProviderFactories.GetFactory(_connection);
                }

                if (_factory == null)
                {
                    WriteError(new ErrorRecord(new RuntimeException("Failed to obtain a DbProviderFactory object"), "", ErrorCategory.NotSpecified, null));
                    throw new PipelineStoppedException();
                }

                _builder = _factory.CreateCommandBuilder();

                // Supply a command builder with an adaptor object because some providers' builders
                // (including those of ODBC and OLEDB Access) require an active connection to make QuoteIndentifier() work.
                using (var adaptor = _factory.CreateDataAdapter())
                using (var cmd = _connection.CreateCommand())
                {
                    cmd.CommandText = "select 1";
                    adaptor.SelectCommand = cmd;
                    _builder.DataAdapter = adaptor;
                }

                _useNamedParameters = false;
            }
            catch (Exception e)
            {
                DisposeResources();

                WriteError(new ErrorRecord(e, "", ErrorCategory.NotSpecified, null));
                throw new PipelineStoppedException();
            }
        }

        protected override void ProcessRecord()
        {
            try
            {
                if (InputObject == null)
                    return;

                if (_fieldSet == null)
                {
                    _qualifiedTableName = GetQualifiedTableName();

                    CreateTable();

                    _useNamedParameters = TestNamedParameterSupport();

                    _insertStmt = "insert into " + _qualifiedTableName + " (";

                    _transaction = _connection.BeginTransaction();
                }

                using (var cmd = _connection.CreateCommand())
                {
                    cmd.CommandText = _insertStmt;
                    cmd.Transaction = _transaction;

                    var buffer = new StringBuilder(_insertStmt);
                    var placeholders = new StringBuilder();

                    string pa = "?";
                    var count = 0;
                    if (InputObject is PSObject)
                    {
                        var obj = (PSObject)InputObject;
                        foreach (var p in obj.Properties)
                        {
                            if (!p.IsGettable || !p.IsInstance)
                                continue;

                            if (_fieldSet.Contains(p.Name))
                            {
                                if (count > 0)
                                {
                                    buffer.Append(',');
                                    placeholders.Append(',');
                                }
                                ++count;

                                var qualified = _builder.QuoteIdentifier(p.Name);
                                buffer.Append(qualified);

                                var param = cmd.CreateParameter();
                                if (_useNamedParameters)
                                {
                                    pa = "@" + count.ToString();
                                    param.ParameterName = pa;
                                }

                                var value = p.Value;
                                if (value != null)
                                {
                                    if (value is PSObject)
                                        value = (value as PSObject).BaseObject;
                                    param.Value = value;
                                }

                                cmd.Parameters.Add(param);

                                placeholders.Append(pa);
                            }
                        }
                    }
                    else
                    {
                        foreach (var p in InputObject.GetType().GetProperties())
                        {
                            if (!p.CanRead)
                                continue;

                            if (_fieldSet.Contains(p.Name))
                            {
                                if (count > 0)
                                {
                                    buffer.Append(',');
                                    placeholders.Append(',');
                                }
                                ++count;

                                var qualified = _builder.QuoteIdentifier(p.Name);
                                buffer.Append(qualified);

                                var param = cmd.CreateParameter();
                                if (_useNamedParameters)
                                {
                                    pa = "@" + count.ToString();
                                    param.ParameterName = pa;
                                }

                                var value = p.GetValue(InputObject);
                                if (value != null)
                                {
                                    if (value is PSObject)
                                        value = (value as PSObject).BaseObject;
                                    param.Value = value;
                                }

                                cmd.Parameters.Add(param);

                                placeholders.Append(pa);
                            }
                        }
                    }

                    // If there are no columns to be inserted, just skip.
                    if (placeholders.Length == 0)
                        return;

                    buffer.Append(") values (");
                    buffer.Append(placeholders);
                    buffer.Append(')');
                    var stmt = buffer.ToString();
                    WriteVerbose(stmt);

                    cmd.CommandText = stmt;

                    var rowsAffected = cmd.ExecuteNonQuery();
                    if (rowsAffected != 1)
                        throw new RuntimeException("Insertion failed");
                }
            }
            catch (Exception e)
            {
                if (_transaction != null)
                    _transaction.Rollback();

                DisposeResources();

                WriteError(new ErrorRecord(e, "", ErrorCategory.NotSpecified, null));
                throw new PipelineStoppedException();
            }
        }

        protected override void EndProcessing()
        {
            try
            {
                if (_transaction != null)
                    _transaction.Commit();
            }
            catch (Exception e)
            {
                WriteError(new ErrorRecord(e, "", ErrorCategory.NotSpecified, null));
                throw new PipelineStoppedException();
            }
            finally
            {
                DisposeResources();
            }
        }

        protected override void StopProcessing()
        {
            DisposeResources();
        }

        private string GetQualifiedTableName()
        {
            // Do nothing. Because TableName is a paramater, users can quote it appropriately.
            return TableName;
        }

        private void CreateTable()
        {
            string stmt;

            // Try to select from a table given by TableName in order to find whether such a table exists.

            bool tableExists = false;
            try
            {
                stmt = "select * from " + _qualifiedTableName;
                WriteVerbose(stmt);

                using (var cmd = _connection.CreateCommand())
                using (var adaptor = _factory.CreateDataAdapter())
                {
                    cmd.CommandText = stmt;
                    adaptor.SelectCommand = cmd;

                    using (var dataSet = new DataSet())
                    {
                        adaptor.FillSchema(dataSet, SchemaType.Mapped);

                        var table = dataSet.Tables[0];

                        _fieldSet = new HashSet<string>();
                        foreach (DataColumn c in table.Columns)
                            _fieldSet.Add(c.ColumnName);
                    }

                    tableExists = true;
                }
            }
            catch (DbException)
            {
                // Ignore an exception
            }

            if (tableExists)
                return;

            // Collect field names from the input object

            var fields = new List<string>();
            if (InputObject is PSObject)
            {
                var obj = (PSObject)InputObject;
                foreach (var p in obj.Properties)
                    fields.Add(p.Name);
            }
            else
            {
                foreach (var p in InputObject.GetType().GetProperties())
                {
                    if (!p.CanRead)
                        continue;
                    fields.Add(p.Name);
                }
            }

            if (AdditionalColumns != null)
            {
                foreach (var c in AdditionalColumns)
                    fields.Add(c);
            }

            _fieldSet = new HashSet<string>(fields);

            // Create a table

            string stringType = "varchar(4000)"; // ANSI SQL standard

            if (TypeName != null)
            {
                // User-specified type name
                stringType = TypeName;
            }
            else if (_connection is System.Data.SQLite.SQLiteConnection)
            {
                // SQLite can omit a type
                stringType = "";
            }
            else if (_connection is System.Data.SqlClient.SqlConnection)
            {
                // SQL Server supports nvarchar that represents a UTF-16 string.
                // It is safe for any database encoding.
                stringType = "nvarchar(4000)";
            }
            else if (_connection.GetType().FullName.Contains("Oracle"))
            {
                // Conventional type name of string for Oracle
                stringType = "nvarchar2(4000)";
            }
            else
            {
                long length = 4000;
                try
                {
                    using (var schema = _connection.GetSchema("DataTypes"))
                    {
                        foreach (DataRow row in schema.Rows)
                        {
                            var columnName = row.Field<string>("TypeName");
                            if (columnName == "varchar" || columnName == "VARCHAR" || columnName == "Varchar")
                            {
                                long l = row.Field<long>("ColumnSize");
                                length = Math.Min(4000, l);
                                break;
                            }
                        }
                    }
                    stringType = String.Format("varchar({0})", length);
                }
                catch (Exception)
                {
                    // Because schema information varies from provider to provider,
                    // when an error occurs, just ignore it and apply standard type definition.
                }
            }

            var templ = new StringBuilder();
            templ.Append("create table ");
            templ.Append(_qualifiedTableName);
            templ.Append(" (\r\n");
            bool first = true;
            foreach (var f in fields)
            {
                if (!first)
                    templ.AppendLine(",");

                first = false;
                templ.Append("    ");
                templ.Append(_builder.QuoteIdentifier(f));
                templ.Append(" {0}");
            }
            templ.AppendLine("\r\n)");

            stmt = String.Format(templ.ToString(), stringType);
            WriteVerbose(stmt);

            using (var cmd = _connection.CreateCommand())
            {
                cmd.CommandText = stmt;
                cmd.ExecuteNonQuery();
            }
        }

        private bool TestNamedParameterSupport()
        {
            using (var cmd = _connection.CreateCommand())
            {
                try
                {
                    var stmt = "select 1 + @param";
                    cmd.CommandText = stmt;
                    WriteVerbose(stmt);

                    var param = cmd.CreateParameter();
                    param.ParameterName = "@param";
                    param.Value = 1;

                    cmd.Parameters.Add(param);

                    using (var reader = cmd.ExecuteReader())
                    {
                        reader.Read();
                        reader.GetValue(0);
                    }

                    return true;
                }
                catch (DbException)
                {
                    return false;
                }
            }
        }
    }
}
