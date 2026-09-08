using System;
using System.Data.Common;
using System.IO;

namespace Horker.Data
{
    internal static class DatabaseCreation
    {
        internal static string SelectType(string path, string explicitType)
        {
            string inferred = null;
            switch (Path.GetExtension(path).ToLowerInvariant())
            {
                case ".db": case ".sqlite": case ".sqlite3": inferred = "SQLite"; break;
                case ".duckdb": inferred = "DuckDB"; break;
            }
            if (explicitType != null && inferred != null && !string.Equals(explicitType, inferred, StringComparison.OrdinalIgnoreCase))
                throw new ArgumentException("DatabaseType conflicts with the file extension.");
            var type = explicitType ?? inferred;
            if (type == null) throw new ArgumentException("Specify DatabaseType SQLite or DuckDB for this file extension.");
            return string.Equals(type, "DuckDB", StringComparison.OrdinalIgnoreCase) ? "DuckDB" : "SQLite";
        }

        internal static bool ValidateDestination(string path, bool force)
        {
            if (string.IsNullOrEmpty(Path.GetFileName(path)) || Path.GetFileName(path).IndexOfAny(Path.GetInvalidFileNameChars()) >= 0)
                throw new ArgumentException("Path must name a regular database file.");
            if (!Directory.Exists(Path.GetDirectoryName(path))) throw new DirectoryNotFoundException("The parent directory must already exist.");
            FileAttributes? attributes = null;
            try { attributes = File.GetAttributes(path); }
            catch (FileNotFoundException) { }
            if (attributes.HasValue)
            {
                if ((attributes.Value & (FileAttributes.Directory | FileAttributes.ReparsePoint)) != 0)
                    throw new IOException("Directories and reparse points cannot be database targets.");
                if (!force) throw new IOException("The target file already exists. Use Force to replace it.");
                if ((attributes.Value & FileAttributes.ReadOnly) != 0) throw new IOException("The target file is read-only.");
            }
            foreach (var suffix in new[] { "-wal", "-shm", "-journal", ".wal" })
                if (File.Exists(path + suffix) || Directory.Exists(path + suffix))
                    throw new IOException("A database sidecar exists: " + path + suffix + ". Close database connections and resolve pending recovery before retrying.");
            if (attributes.HasValue)
            {
                try { using (File.Open(path, FileMode.Open, FileAccess.ReadWrite, FileShare.None)) { } }
                catch (IOException error) { throw new IOException("The database target is in use. Close its connections before retrying.", error); }
            }
            return attributes.HasValue;
        }

        internal static void Create(string path, bool force, Action<string> initialize)
        {
            bool replace = ValidateDestination(path, force);
            var temporaryDirectory = Path.Combine(Path.GetDirectoryName(path), ".horker-create-" + Guid.NewGuid().ToString("N"));
            var temporaryPath = Path.Combine(temporaryDirectory, "database");
            bool failed = false;
            Directory.CreateDirectory(temporaryDirectory);
            try
            {
                initialize(temporaryPath);
                // Recheck before committing. Concurrent database use is unsupported.
                bool nowExists = ValidateDestination(path, force);
                if (nowExists != replace) throw new IOException("The target changed during database creation; retry without concurrent file operations.");
                if (replace) File.Replace(temporaryPath, path, null);
                else File.Move(temporaryPath, path);
            }
            catch { failed = true; throw; }
            finally
            {
                Action cleanup = () =>
                {
                    // Delete only files belonging to this operation, never the destination.
                    foreach (var suffix in new[] { "", "-wal", "-shm", "-journal", ".wal" })
                        File.Delete(temporaryPath + suffix);
                    Directory.Delete(temporaryDirectory, false);
                };
                if (failed) DuckDbSupport.TryCleanup(cleanup);
                else cleanup();
            }
        }

        internal static void Initialize(string path, string type, DbProviderFactory factory)
        {
            var builder = factory.CreateConnectionStringBuilder();
            builder["Data Source"] = path;
            if (type == "SQLite") builder["Pooling"] = false;
            Execute(factory, builder.ConnectionString, type == "SQLite" ? "VACUUM" : "CHECKPOINT", false);
            Execute(factory, builder.ConnectionString, type == "SQLite"
                ? "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
                : "SELECT COUNT(*) FROM information_schema.tables WHERE table_type='BASE TABLE'", true);
        }

        private static void Execute(DbProviderFactory factory, string connectionString, string sql, bool verify)
        {
            var connection = factory.CreateConnection();
            DbCommand command = null;
            bool failed = false;
            try
            {
                connection.ConnectionString = connectionString;
                connection.Open();
                command = connection.CreateCommand();
                command.CommandText = sql;
                if (verify)
                {
                    if (Convert.ToInt64(command.ExecuteScalar()) != 0) throw new InvalidDataException("The newly created database is not empty.");
                }
                else command.ExecuteNonQuery();
            }
            catch { failed = true; throw; }
            finally
            {
                if (failed)
                {
                    if (command != null) DuckDbSupport.TryCleanup(command.Dispose);
                    DuckDbSupport.TryCleanup(connection.Dispose);
                }
                else { try { command?.Dispose(); } finally { connection.Dispose(); } }
            }
        }
    }
}
