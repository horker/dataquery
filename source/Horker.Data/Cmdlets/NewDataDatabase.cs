using System;
using System.IO;
using System.Management.Automation;

#pragma warning disable CS1591

namespace Horker.Data
{
    /// <summary>
    /// <para type="synopsis">Creates an empty SQLite or DuckDB database file.</para>
    /// <para type="description">Infers SQLite from .db, .sqlite or .sqlite3, and DuckDB from .duckdb. Other extensions require DatabaseType. DuckDB requires PowerShell 7. The parent directory must exist. Force replaces a closed existing file after a new database has been created and verified. Sidecars, reparse points and read-only targets are rejected. Concurrent database use is unsupported. Connections are closed before returning; PassThru returns FileInfo.</para>
    /// </summary>
    [Cmdlet("New", "DataDatabase", SupportsShouldProcess = true, ConfirmImpact = ConfirmImpact.Medium)]
    [OutputType(typeof(FileInfo))]
    public class NewDataDatabase : PSCmdlet
    {
        /// <summary><para type="description">A literal filesystem path, relative to the PowerShell current location. Connection names and memory databases are not accepted.</para></summary>
        [Parameter(Position = 0, Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public string Path { get; set; }

        /// <summary><para type="description">SQLite or DuckDB. Must agree with a recognized extension.</para></summary>
        [Parameter]
        [ValidateSet("SQLite", "DuckDB")]
        public string DatabaseType { get; set; }

        /// <summary><para type="description">Replace an existing file. Does not bypass locks, attributes or confirmation.</para></summary>
        [Parameter]
        public SwitchParameter Force { get; set; }

        /// <summary><para type="description">Return the created file as FileInfo after closing database connections.</para></summary>
        [Parameter]
        public SwitchParameter PassThru { get; set; }

        protected override void ProcessRecord()
        {
            try
            {
                ProviderInfo provider;
                PSDriveInfo drive;
                var path = SessionState.Path.GetUnresolvedProviderPathFromPSPath(Path, out provider, out drive);
                if (provider.Name != "FileSystem") throw new ArgumentException("Path must use the FileSystem provider.");
                var type = DatabaseCreation.SelectType(path, DatabaseType);
                if (type == "DuckDB") DuckDbSupport.RequireSupportedHost();
                var factory = ProviderRegistry.GetFactory(type == "SQLite" ? "System.Data.SQLite" : DuckDbSupport.ProviderName);
                bool exists = DatabaseCreation.ValidateDestination(path, Force);
                if (!ShouldProcess(path, exists ? "Replace existing file with an empty " + type + " database" : "Create an empty " + type + " database")) return;
                DatabaseCreation.Create(path, Force, temporary => DatabaseCreation.Initialize(temporary, type, factory));
                if (PassThru) WriteObject(new FileInfo(path));
            }
            catch (Exception error)
            {
                ThrowTerminatingError(new ErrorRecord(error, "NewDataDatabaseFailed", ErrorCategory.InvalidOperation, Path));
            }
        }
    }
}
