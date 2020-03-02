using Horker.Data.Classes;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.Common;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

#pragma warning disable CS1591

namespace Horker.Data.Cmdlets
{
    /// <summary>
    /// <para type="synopsis">Copy data from a database to another.</para>
    /// <para type="description">The Copy-DataRow cmdlet obtains a dataset from a database specified by the -SourceConnection parameter by executing the -SourceSql statement and inserts them to a table of another database spceified bu the -TargetConnection parameter.</para>
    /// <para type="description">When you specify a target table name by the -TargetTable parameter, the cmdlet assumes the specified table contains the same set of columns as the source dataset and inserts them into the corresponding columns.</para>
    /// <para type="description">When you specify a SQL statement for copying by the -TargetSql parameter, the cmdlet executes it for each data row of the source dataset. The SQL statement should contain named parameters corresponding to the columns of the source dataset.</para>
    /// <para type="description">You can specify either one of the -TargetTable or -TargetSql parameters.</para>
    /// </summary>
    [Cmdlet("Copy", "DataRow")]
    [OutputType(typeof(void))]
    public class CopyDataRow : PSCmdlet
    {
        /// <summary>
        /// <para type="description">A DbConnection object, a connection string name or a database file name (SQLite or Access) of the source database.</para>
        /// </summary>
        [Parameter(Position = 0, Mandatory = true)]
        public ConnectionSpecifier SourceConnection { get; set; }

        /// <summary>
        /// <para type="description">An SQL statement to obtain data from the source database.</para>
        /// </summary>
        [Parameter(Position = 1, Mandatory = true)]
        public string SourceSql { get; set; }

        /// <summary>
        /// <para type="description">A DbConnection object, a connection string name or a database file name (SQLite or Access) of the target database.</para>
        /// </summary>
        [Parameter(Position = 2, Mandatory = true)]
        public ConnectionSpecifier TargetConnection { get; set; }

        /// <summary>
        /// <para type="description">A name of the table into which data will be inserted.</para>
        /// </summary>
        [Parameter(Position = 3, Mandatory = false)]
        public string TargetTable { get; set; }

        /// <summary>
        /// <para type="description">Query parameters applied to the -SourceSql statement.</para>
        /// </summary>
        [Parameter(Position = 4, Mandatory = false)]
        public object SourceParameters { get; set; }

        /// <summary>
        /// <para type="description">An SQL statement to be used for copying the data. It is usually an INSERT or UPDATE statement with the corresponding named parameters to the columns of the source dataset.</para>
        /// </summary>
        [Parameter(Position = 5, Mandatory = false)]
        public string TargetSql { get; set; }

        /// <summary>
        /// <para type="description">A timeout in seconds.</para>
        /// </summary>
        [Parameter(Position = 6, Mandatory = false)]
        public int Timeout { get; set; }

        protected override void BeginProcessing()
        {
            DbTransaction transaction = null;
            try
            {
                if ((TargetTable == null && TargetSql == null) || (TargetTable != null && TargetSql != null))
                    throw new ArgumentException("Specify either one of TargetTable or TargetSql");

                bool timeoutGiven = MyInvocation.BoundParameters.ContainsKey("Timeout");

                var connection = TargetConnection.Connection;

                transaction = connection.BeginTransaction();

                using (var selectCmd = SourceConnection.Connection.CreateCommand())
                {
                    selectCmd.CommandText = SourceSql;

                    if (timeoutGiven)
                        selectCmd.CommandTimeout = Timeout;

                    Helpers.SetParameters(selectCmd, SourceParameters);

                    using (var reader = selectCmd.ExecuteReader())
                    {
                        string[] paramNames = null;

                        while (reader.Read())
                        {
                            if (paramNames == null)
                            {
                                paramNames = new string[reader.FieldCount];
                                for (var i = 0; i < reader.FieldCount; ++i)
                                    paramNames[i] = reader.GetName(i);
                            }

                            using (var insertCmd = TargetConnection.Connection.CreateCommand())
                            {
                                insertCmd.Transaction = transaction;

                                if (TargetSql == null)
                                {
                                    var factory = Helpers.GetDbProviderFactory(connection);
                                    using (var builder = factory.CreateCommandBuilder())
                                    {
                                        var columns = string.Join(", ", paramNames.Select(p => builder.QuoteIdentifier(p)));
                                        var paras = "@" + string.Join(", @", paramNames);
                                        TargetSql = $"insert into {TargetTable} ({columns}) values ({paras})";
                                    }
                                }

                                insertCmd.CommandText = TargetSql;

                                for (var i = 0; i < reader.FieldCount; ++i)
                                {
                                    var param = insertCmd.CreateParameter();
                                    param.ParameterName = paramNames[i];
                                    param.Value = reader.GetValue(i);
                                    insertCmd.Parameters.Add(param);
                                }

                                if (timeoutGiven)
                                    insertCmd.CommandTimeout = Timeout;

                                insertCmd.ExecuteNonQuery();
                            }
                        }
                    }
                }

                transaction.Commit();
            }
            catch (Exception e)
            {
                if (transaction != null)
                    transaction.Rollback();

                WriteError(new ErrorRecord(e, "", ErrorCategory.NotSpecified, null));
            }
            finally
            {
                SourceConnection.Close();
                TargetConnection.Close();
            }
        }
    }
}
