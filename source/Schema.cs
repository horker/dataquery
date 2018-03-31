using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

#pragma warning disable CS1591

namespace Horker.Data
{
    /// <summary>
    /// <para type="synopsis">Gets database schema information.</para>
    /// <para type="description">The Get-DataSchema cmdlet gets database schema information that the database engine provides. If a schema collection name (-CollectionName) is not specified, it returns the information of all available schemas. The provided information varies among database products.</para>
    /// </summary>
    [Cmdlet("Get", "DataSchema")]
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
            base.EndProcessing();

            var opener = new ConnectionOpener(FileOrName, Connection, null, null);
            var connection = opener.Connection;
            var connectionOpen = opener.ConnectionOpen;

            try {
                DataTable schema;
                if (CollectionName != null && CollectionName != "") {
                    schema = connection.GetSchema(CollectionName);
                }
                else {
                    schema = connection.GetSchema();
                }

                foreach (var row in schema.Rows) {
                    WriteObject(row);
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
}