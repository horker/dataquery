using System;
using System.Collections.Generic;
using System.Management.Automation;
using System.Data;
using System.Data.Common;

#pragma warning disable CS1591

namespace Horker.Data
{
    /// <summary>
    /// <para type="synopsis">Opens a database connection.</para>
    /// <para type="description">The New-DataConnection cmdlet opens a database connection.</para>
    /// </summary>
    [Cmdlet("New", "DataConnection", DefaultParameterSetName = "FileOrName")]
    [Alias("Open", "DataConnection")]
    [OutputType(typeof(DbConnection))]
    public class NewDataConnection : PSCmdlet
    {
        /// <summary>
        /// <para type="description">A database file name or a connection string name.</para>
        /// </summary>
        [Parameter(Position = 0, ParameterSetName = "FileOrName", Mandatory = true)]
        public string FileOrName { get; set; }

        /// <summary>
        /// <para type="description">A database provider name.</para>
        /// </summary>
        [Parameter(Position = 0, ParameterSetName = "ConnectionString", Mandatory = true)]
        public string ProviderName { get; set; }

        /// <summary>
        /// <para type="description">A connection string.</para>
        /// </summary>
        [Parameter(Position = 1, ParameterSetName = "ConnectionString", Mandatory = true)]
        public string ConnectionString { get; set; }

        protected override void EndProcessing()
        {
            try {
                var opener = new ConnectionSpecifier(FileOrName, null, ProviderName, ConnectionString);

                WriteObject(opener.Connection);
            }
            catch (Exception ex) {
                WriteError(new ErrorRecord(ex, "", ErrorCategory.NotSpecified, null));
            }
        }
    }

    /// <summary>
    /// <para type="synopsis">Closes a database connection.</para>
    /// <para type="description">The Close-DataConnection cmdlet closes a database connection.</para>
    /// </summary>
    [Cmdlet("Close", "DataConnection")]
    [OutputType(typeof(void))]
    public class CloseDataConnection : PSCmdlet
    {
        /// <summary>
        /// <para type="description">A database connection.</para>
        /// </summary>
        [Parameter(Position = 0, Mandatory = true)]
        public DbConnection Connection;

        protected override void EndProcessing()
        {
            try {
                Connection.Close();
                Connection.Dispose();
            }
            catch (Exception ex) {
                WriteError(new ErrorRecord(ex, "", ErrorCategory.NotSpecified, Connection));
            }
        }
    }

    /// <summary>
    /// <para type="synopsis">Gets open database connections in the current session.</para>
    /// <para type="description">The Get-DataConnectionHistory cmdlet gets open database connections in the current session that you have opened explicitly by the New-DataConnection cmdlet,  or implicitly by the other cmdlets you invoked.</para>
    /// <para type="description">This cmdlet is useful when you need to investigate untracked open connections causing a trouble (acquiring a file lock, for example).</para>
    /// </summary>
    [Cmdlet("Get", "DataConnectionHistory")]
    [OutputType(typeof(DbConnection))]
    public class GetDataConnectionHistory : PSCmdlet
    {
        private static List<DbConnection> _connectionHistory = new List<DbConnection>();

        public static void AddToHistory(DbConnection conn)
        {
            RemoveClosedConnection();
            _connectionHistory.Insert(0, conn);
        }

        protected override void EndProcessing()
        {
            RemoveClosedConnection();
            foreach (var c in _connectionHistory) {
                WriteObject(c);
            }
        }

        private static void RemoveClosedConnection()
        {
            _connectionHistory.RemoveAll(c => {
                try
                {
                    return c.State == ConnectionState.Closed;
                }
                catch (ObjectDisposedException)
                {
                    return true;
                }
            });
        }
    }
}
