using System.Data.Common;

#pragma warning disable CS1591

namespace Horker.Data
{
    class ConnectionOpener
    {
        public DbConnection Connection { get; private set; }
        public bool ConnectionOpened { get; private set; }

        public ConnectionOpener(string fileOrName, DbConnection connection, string providerName, string connectionString)
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
    }
}
