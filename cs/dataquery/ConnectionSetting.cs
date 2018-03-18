using System;
using System.IO;
using System.Management.Automation;
using System.Data.Common;
using System.Configuration;

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
            DbProviderFactory factory = DbProviderFactories.GetFactory(ProviderName);

            var conn = factory.CreateConnection();
            conn.ConnectionString = ConnectionString;
            conn.Open();

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
            if (cs != null) {
                return new ProviderConnectionSetting(cs.ProviderName, cs.ConnectionString).GetConnection();
            }

            // Access file?
            if (FileOrName.EndsWith(".accdb") || FileOrName.EndsWith(".mdb")) {
                var builder = new System.Data.Odbc.OdbcConnectionStringBuilder();
                builder.Add("Driver", "{Microsoft Access Driver (*.mdb, *.accdb)}");
                builder.Add("Dbq", FileOrName);

                var conn = new System.Data.Odbc.OdbcConnection();
                conn.ConnectionString = builder.ConnectionString;
                conn.Open();

                return conn;
            }

            // Assume a SQLite file
            // Restricts to an exsiting file to prevent mistyping from creating a new database
            if (File.Exists(FileOrName)) {
                var builder = new System.Data.SQLite.SQLiteConnectionStringBuilder();
                builder.Add("Data Source", FileOrName);

                var conn = new System.Data.SQLite.SQLiteConnection();
                conn.ConnectionString = builder.ConnectionString;
                conn.Open();

                return conn;
            }

            throw new RuntimeException(String.Format("'{0}' is not a database file name nor connection string name", FileOrName));
        }
    }
}