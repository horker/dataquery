using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.Common;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace Horker.Data.Classes
{
    internal static class Helpers
    {
        public static void SetParameters(DbCommand cmd, object parameters)
        {
            if (parameters == null)
                return;

            if (parameters is IDictionary dictParam)
            {
                foreach (DictionaryEntry entry in dictParam)
                {
                    object value;
                    if (entry.Value is PSObject psobj)
                        value = psobj.BaseObject;
                    else
                        value = entry.Value;

                    var param = cmd.CreateParameter();
                    param.ParameterName = (string)entry.Key;
                    param.Value = value;
                    cmd.Parameters.Add(param);
                }
            }
            else if (parameters is IEnumerable enumParam)
            {
                foreach (var v in enumParam)
                {
                    object value;
                    if (v is PSObject psobj)
                        value = psobj.BaseObject;
                    else
                        value = v;

                    var param = cmd.CreateParameter();
                    param.Value = value;
                    cmd.Parameters.Add(param);
                }
            }
            else
                throw new ArgumentException("Query parameters must be a IDictionary or an IEnumerable");
        }

        public static DbProviderFactory GetDbProviderFactory(DbConnection connection)
        {
            DbProviderFactory factory = null;

            // ODBC, OLEDB and SQLite connections fail to obtain the corresponding factories.
            if (connection is System.Data.Odbc.OdbcConnection)
            {
                factory = DbProviderFactories.GetFactory("System.Data.Odbc");
            }
            else if (connection is System.Data.OleDb.OleDbConnection)
            {
                factory = DbProviderFactories.GetFactory("System.Data.OleDb");
            }
            else if (connection is System.Data.SQLite.SQLiteConnection)
            {
                factory = DbProviderFactories.GetFactory("System.Data.SQLite");
            }
            else
            {
                factory = DbProviderFactories.GetFactory(connection);
            }

            if (factory == null)
                throw new RuntimeException("Failed to obtain a DbProviderFactory object");

            return factory;
        }
    }
}
