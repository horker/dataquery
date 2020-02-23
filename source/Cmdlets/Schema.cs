using System;
using System.Data;
using System.Data.Common;
using System.Management.Automation;

#pragma warning disable CS1591

namespace Horker.Data
{
    /// <summary>
    /// <para type="synopsis">Gets database schema information.</para>
    /// <para type="description">The Get-DataSchema cmdlet gets database schema information that the database engine provides. If a schema collection name (-CollectionName) is not specified, it returns the information of all available schemas. The provided information varies among database products.</para>
    /// </summary>
    [Cmdlet("Get", "DataSchema")]
    [OutputType(typeof(DataRow))]
    public class GetDataSchema : PSCmdlet
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
        /// <para type="description">A schama collection name.</para>
        /// </summary>
        [Parameter(Position = 1, Mandatory = false)]
        public string CollectionName { get; set; }

        protected override void EndProcessing()
        {
            var opener = new ConnectionSpecifier(FileOrName, Connection, null, null);
            var connection = opener.Connection;
            var connectionOpen = opener.ConnectionOpened;

            try
            {
                DataTable schema;
                if (CollectionName != null && CollectionName != "")
                    schema = connection.GetSchema(CollectionName);
                else
                    schema = connection.GetSchema();

                try
                {
                    foreach (var row in schema.Rows)
                        WriteObject(row);
                }
                finally
                {
                    schema.Dispose();
                }
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "", ErrorCategory.NotSpecified, null));
            }
            finally
            {
                if (connectionOpen)
                {
                    connection.Close();
                    connection.Dispose();
                }
            }
        }
    }
}