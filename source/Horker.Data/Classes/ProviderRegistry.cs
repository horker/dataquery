using System;
using System.Data;
using System.Data.Common;
using System.Reflection;
#if !NETFRAMEWORK
using System.Runtime.Loader;
#endif

namespace Horker.Data
{
    internal static class ProviderRegistry
    {
#if NETFRAMEWORK
        private static readonly DataTable Providers = DbProviderFactories.GetFactoryClasses();
        private static readonly object Sync = new object();
#endif

        internal static void Register(string name, string invariant, string description, string typeName)
        {
            var type = ResolveType(typeName);
            if (!typeof(DbProviderFactory).IsAssignableFrom(type) ||
                !(type.GetField("Instance", BindingFlags.Public | BindingFlags.Static)?.GetValue(null) is DbProviderFactory))
                throw new ArgumentException("Provider type must expose a public static DbProviderFactory Instance.");
#if NETFRAMEWORK
            lock (Sync)
            {
                Remove(invariant);
                Providers.Rows.Add(name, description, invariant, type.AssemblyQualifiedName);
            }
#else
            DbProviderFactories.RegisterFactory(invariant, type);
#endif
        }

        private static Type ResolveType(string name)
        {
#if NETFRAMEWORK
            return Type.GetType(name, true);
#else
            var context = AssemblyLoadContext.GetLoadContext(typeof(ProviderRegistry).Assembly);
            return Type.GetType(name, context.LoadFromAssemblyName, null, true);
#endif
        }

        internal static DbProviderFactory GetFactory(string invariant)
        {
            if (invariant == DuckDbSupport.ProviderName) DuckDbSupport.RequireSupportedHost();
#if NETFRAMEWORK
            lock (Sync)
            {
                foreach (DataRow row in Providers.Rows)
                    if ((string)row["InvariantName"] == invariant)
                        return (DbProviderFactory)ResolveType((string)row["AssemblyQualifiedName"])
                            .GetField("Instance", BindingFlags.Public | BindingFlags.Static).GetValue(null);
            }
            throw new ArgumentException("Provider is not registered: " + invariant);
#else
            return DbProviderFactories.GetFactory(invariant);
#endif
        }

        internal static DbProviderFactory GetFactory(DbConnection connection)
        {
            if (DuckDbSupport.IsDuckDb(connection)) return GetFactory(DuckDbSupport.ProviderName);
            // Honor removals for providers supplied by this module.
            if (connection is System.Data.Odbc.OdbcConnection) return GetFactory("System.Data.Odbc");
            if (connection is System.Data.OleDb.OleDbConnection) return GetFactory("System.Data.OleDb");
            if (connection is System.Data.SqlClient.SqlConnection) return GetFactory("System.Data.SqlClient");
            if (connection is System.Data.SQLite.SQLiteConnection) return GetFactory("System.Data.SQLite");
            var factory = DbProviderFactories.GetFactory(connection);
#if NETFRAMEWORK
            lock (Sync)
            {
                foreach (DataRow row in Providers.Rows)
                    if ((string)row["AssemblyQualifiedName"] == factory.GetType().AssemblyQualifiedName)
                        return factory;
            }
            throw new ArgumentException("The connection's provider is not registered.");
#else
            return factory;
#endif
        }

        internal static DataTable GetFactoryClasses()
        {
#if NETFRAMEWORK
            lock (Sync) return Providers.Copy();
#else
            return DbProviderFactories.GetFactoryClasses();
#endif
        }

        internal static void Remove(string invariant)
        {
#if NETFRAMEWORK
            lock (Sync)
                for (int i = Providers.Rows.Count - 1; i >= 0; i--)
                    if ((string)Providers.Rows[i]["InvariantName"] == invariant) Providers.Rows.RemoveAt(i);
#else
            DbProviderFactories.UnregisterFactory(invariant);
#endif
        }

        internal static void Clear()
        {
#if NETFRAMEWORK
            lock (Sync) Providers.Clear();
#else
            foreach (string name in DbProviderFactories.GetProviderInvariantNames()) Remove(name);
#endif
        }
    }
}
