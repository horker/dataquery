using System;
using System.Configuration;
using System.Data.Common;
using System.IO;
using System.Management.Automation;

#pragma warning disable CS1591

namespace Horker.Data
{
    public abstract class ConnectionSetting
    {
        public abstract DbConnection GetConnection();
    }

    public class ProviderConnectionSetting : ConnectionSetting
    {
        public string ProviderName { get; set; }
        public string ConnectionString { get; set; }

        public ProviderConnectionSetting(string providerName, string connectionString)
        {
            ProviderName = providerName;
            ConnectionString = connectionString;
        }

        public override DbConnection GetConnection()
        {
            DbProviderFactory factory = ProviderRegistry.GetFactory(ProviderName);

            var conn = factory.CreateConnection();
            try { conn.ConnectionString = ConnectionString; conn.Open(); }
            catch { DuckDbSupport.TryCleanup(conn.Dispose); throw; }

            return conn;
        }
    }

    public class FileConnectionSetting : ConnectionSetting
    {
        public string FileOrName { get; private set; }

        public FileConnectionSetting(string fileOrName)
        {
            FileOrName = fileOrName;
        }

        public override DbConnection GetConnection()
        {
            // Look up configuration
            var cs = ConfigurationManager.ConnectionStrings[FileOrName];
            if (cs != null)
                return new ProviderConnectionSetting(cs.ProviderName, cs.ConnectionString).GetConnection();

            // Use the active PowerShell session even during Copy-DataRow's argument
            // conversion. The process current directory is shared across runspaces
            // and need not match PowerShell's current location.
            var path = DatabasePath.Resolve(FileOrName, new SessionState());

            if (FileOrName.EndsWith(".duckdb", StringComparison.OrdinalIgnoreCase))
            {
                DuckDbSupport.RequireSupportedHost();
                if (!File.Exists(path))
                    throw new RuntimeException("DuckDB file does not exist. Use New-DataDatabase filename.duckdb, or New-DataConnection -ProviderName DuckDB.NET.Data -ConnectionString 'Data Source=filename.duckdb'.");
                var builder = ProviderRegistry.GetFactory(DuckDbSupport.ProviderName).CreateConnectionStringBuilder();
                builder["Data Source"] = path;
                return new ProviderConnectionSetting(DuckDbSupport.ProviderName, builder.ConnectionString).GetConnection();
            }

            // Access file?
            if (FileOrName.EndsWith(".accdb") || FileOrName.EndsWith(".mdb"))
            {
                var builder = new System.Data.Odbc.OdbcConnectionStringBuilder();
                builder.Add("Driver", "{Microsoft Access Driver (*.mdb, *.accdb)}");
                builder.Add("Dbq", path);

                var conn = new System.Data.Odbc.OdbcConnection();
                conn.ConnectionString = builder.ConnectionString;
                conn.Open();

                return conn;
            }

            // Assume a SQLite file
            // Restricts to an exsiting file to prevent mistyping from creating a new database
            if (File.Exists(path))
            {
                var builder = new System.Data.SQLite.SQLiteConnectionStringBuilder();
                builder.Add("Data Source", path);

                var conn = new System.Data.SQLite.SQLiteConnection();
                conn.ConnectionString = builder.ConnectionString;
                conn.Open();

                return conn;
            }

            throw new RuntimeException(String.Format("'{0}' is not a database file name nor connection string name. Use New-DataDatabase to create a SQLite or DuckDB file.", FileOrName));
        }
    }
}
