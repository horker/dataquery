using System.Data.Common;

#pragma warning disable CS1591

namespace Horker.Data
{
    public class ConnectionSpecifier
    {
        public DbConnection Connection { get; private set; }
        public bool ConnectionOpened { get; private set; }

        public ConnectionSpecifier(string fileOrName, DbConnection connection, string providerName, string connectionString)
        {
            if (fileOrName != null) {
                Connection = new FileConnectionSetting(fileOrName).GetConnection();
                ConnectionOpened = true;
            }
            else if (connection != null) {
                Connection = connection;
                ConnectionOpened = false;
            }
            else {
                Connection = new ProviderConnectionSetting(providerName, connectionString).GetConnection();
                ConnectionOpened = true;
            }

            if (ConnectionOpened) {
                GetDataConnectionHistory.AddToHistory(Connection);
            }
        }

        public void Close()
        {
            if (ConnectionOpened && Connection != null)
                Connection.Close();
            ConnectionOpened = false;
        }

        public static implicit operator ConnectionSpecifier(string fileOrName)
        {
            return new ConnectionSpecifier(fileOrName, null, null, null);
        }

        public static implicit operator ConnectionSpecifier(DbConnection connection)
        {
            return new ConnectionSpecifier(null, connection, null, null);
        }
    }
}
