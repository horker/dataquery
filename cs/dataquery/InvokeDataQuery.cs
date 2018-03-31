using System;
using System.Collections;
using System.Management.Automation;
using System.Data;
using System.Data.Common;

#pragma warning disable CS1591

namespace Horker.Data
{
    /// <summary>
    /// <para type="synopsis">Executes a database query.</para>
    /// <para type="description">The Invoke-DataQuery cmdlet executes a query to a database.</para>
    /// <para type="description">Despite its name, this cmdlet can execute any SQL statement, including INSERT, DELETE and CREATE. When such a statement is executed, no result will return. By specifying the -ShowRecordsAffected parameter, you can get the number of records affected by the statement. You can always obtain the same value by the Get-DataQueryResult cmdlet.</para>
    /// <para type="description">By default, the DBNull values in the result data set are replaced with normal null values, and the results are returned as a stream of PSObject values. You can change this behavior by the -PreserveDbNull and -AsDataRows switch parameters.</para>
    /// </summary>
    [Cmdlet("Invoke", "DataQuery")]
    public class InvokeDataQuery : PSCmdlet
    {
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
        /// <para type="description">A query statement.</para>
        /// </summary>
        [Parameter(Position = 1, Mandatory = true)]
        public string Query { get; set; }

        /// <summary>
        /// <para type="description">Query parameters.</para>
        /// </summary>
        [Parameter(Position = 2, Mandatory = false)]
        public ICollection Parameters { get; set; }

        /// <summary>
        /// <para type="description">A query timeout in seconds.</para>
        /// </summary>
        [Parameter(Position = 3, Mandatory = false)]
        public int Timeout { get; set; }

        /// <summary>
        /// <para type="description">Specifies whether the number of records affected by the query should be returned.</para>
        /// </summary>
        [Parameter(Mandatory = false)]
        public SwitchParameter ShowRecordsAffected { get; set; }

        /// <summary>
        /// <para type="description">Stops replacing the DBNull values in the results with normal null values.</para>
        /// </summary>
        [Parameter(Mandatory = false)]
        public SwitchParameter PreserveDbNull { get; set; }

        /// <summary>
        /// <para type="description">Indicates to return the result data set as System.Data.DataRow instead of PSObject.</para>
        /// </summary>
        [Parameter(Mandatory = false)]
        public SwitchParameter AsDataRow { get; set; }

        protected override void EndProcessing()
        {
            base.EndProcessing();

            var opener = new ConnectionOpener(FileOrName, Connection, null, null);
            var connection = opener.Connection;
            bool connectionOpen = opener.ConnectionOpen;

            try {
                DbCommand cmd = connection.CreateCommand();
                cmd.CommandText = Query;

                if (MyInvocation.BoundParameters.ContainsKey("Timeout")) {
                    cmd.CommandTimeout = Timeout;
                }

                if (Parameters != null) {
                    if (Parameters is IDictionary) {
                        foreach (DictionaryEntry entry in Parameters as IDictionary) {
                            var param = cmd.CreateParameter();
                            param.ParameterName = (string)entry.Key;
                            param.Value = entry.Value;
                            cmd.Parameters.Add(param);
                        }
                    }
                    else {
                        foreach (var value in Parameters) {
                            var param = cmd.CreateParameter();
                            param.Value = value;
                            cmd.Parameters.Add(param);
                        }
                    }
                }

                if (AsDataRow) {
                    var factory = DbProviderFactories.GetFactory(connection);
                    var adaptor = factory.CreateDataAdapter();
                    var dataSet = new DataSet();
                    adaptor.SelectCommand = cmd;
                    adaptor.Fill(dataSet);
                    GetDataQueryResult.RecordsAffected = -1;
                    foreach (var row in dataSet.Tables[0].Rows) {
                        WriteObject(row);
                    }
                }
                else {
                    using (var reader = cmd.ExecuteReader()) {
                        GetDataQueryResult.RecordsAffected = reader.RecordsAffected;

                        var count = reader.FieldCount;

                        string[] fieldNames = new string[count];
                        for (int i = 0; i < count; ++i) {
                            fieldNames[i] = reader.GetName(i);
                        }

                        while (reader.Read()) {
                            var obj = new PSObject();
                            var exprCount = 1;
                            for (int i = 0; i < count; ++i) {
                                object value = null;
                                if (PreserveDbNull || !reader.IsDBNull(i)) {
                                    value = reader.GetValue(i);
                                }

                                PSNoteProperty prop;
                                try {
                                    prop = new PSNoteProperty(fieldNames[i], value);
                                }
                                catch (PSArgumentException) {
                                    prop = new PSNoteProperty("Expr" + exprCount, value);
                                    ++exprCount;
                                }
                                obj.Properties.Add(prop);
                            }
                            WriteObject(obj);
                        }
                    }
                }

                if (ShowRecordsAffected) {
                    WriteObject(GetDataQueryResult.RecordsAffected);
                }
            }
            catch (Exception ex) {
                WriteError(new ErrorRecord(ex, "", ErrorCategory.NotSpecified, null));
            }
            finally {
                if (connectionOpen) {
                    connection.Close();
                }
            }
        }
    }

    /// <summary>
    /// <para type="synopsis">Gets a result of the last query statement.</para>
    /// <para type="description">Gets the number of records affected by the last statement by the Invoke-DataQuery cmdlet. If the previous statement is SELECT, the cmdlet will return -1.</para>
    /// </summary>
    [Cmdlet("Get", "DataQueryResult")]
    public class GetDataQueryResult : PSCmdlet
    {
        static public int RecordsAffected { get; set; }

        protected override void EndProcessing()
        {
            base.EndProcessing();

            WriteObject(RecordsAffected);
        }
    }



}