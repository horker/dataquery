using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Management.Automation;
using System.IO;

namespace Horker.Data
{
    internal static class DuckDbSupport
    {
        internal const string ProviderName = "DuckDB.NET.Data";
        internal static bool IsDuckDb(DbConnection connection)
        {
#if NETFRAMEWORK
            return false;
#else
            return connection is DuckDB.NET.Data.DuckDBConnection;
#endif
        }

        internal static void RequireSupportedHost()
        {
#if NETFRAMEWORK
            throw new NotSupportedException("DuckDB requires PowerShell 7.6.5 or later; Windows PowerShell 5.1 is not supported.");
#endif
        }

        internal static void ValidateTimeout(int timeout, params DbConnection[] connections)
        {
            if (timeout < 0) throw new ArgumentOutOfRangeException(nameof(timeout), "Timeout must be nonnegative.");
            foreach (var connection in connections)
                if (timeout > 0 && IsDuckDb(connection))
                    throw new NotSupportedException("DuckDB does not support a positive Timeout. Omit Timeout or specify 0.");
        }

        internal static string QuoteIdentifier(string name) => "\"" + name.Replace("\"", "\"\"") + "\"";

        internal static void SetParameters(DbCommand command, object parameters)
        {
            if (parameters is PSObject wrapper) parameters = wrapper.BaseObject;
            if (parameters == null) return;
            if (parameters is IDictionary dictionary)
            {
                var names = new HashSet<string>(StringComparer.Ordinal);
                foreach (DictionaryEntry entry in dictionary)
                {
                    var name = (string)entry.Key;
                    if (name.StartsWith("$", StringComparison.Ordinal)) name = name.Substring(1);
                    if (name.Length == 0 || !names.Add(name)) throw new ArgumentException("DuckDB parameter names must be nonempty and unique.");
                    AddParameter(command, name, entry.Value);
                }
            }
            else if (parameters is ICollection values)
            {
                foreach (var value in values) AddParameter(command, "", value);
            }
            else AddParameter(command, "", parameters);
        }

        internal static void AddParameter(DbCommand command, string name, object value)
        {
            if (value is PSObject wrapper) value = wrapper.BaseObject;
            var parameter = command.CreateParameter();
            parameter.ParameterName = name;
            parameter.Value = value ?? DBNull.Value;
            command.Parameters.Add(parameter);
        }

        internal static DataTable ReadTable(DbDataReader reader)
        {
            var table = new DataTable();
            var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            int expression = 1;
            for (int i = 0; i < reader.FieldCount; i++)
            {
                var original = reader.GetName(i);
                if (string.IsNullOrEmpty(original)) original = "Expr" + expression++;
                var name = original;
                int suffix = 1;
                while (!names.Add(name)) name = original + suffix++;
                var type = reader.GetFieldType(i);
                table.Columns.Add(name, typeof(Stream).IsAssignableFrom(type) ? typeof(byte[]) : type);
            }
            while (reader.Read())
            {
                var values = new object[reader.FieldCount];
                for (int i = 0; i < values.Length; i++) values[i] = ReadValue(reader, i);
                table.Rows.Add(values);
            }
            return table;
        }

        internal static object ReadValue(DbDataReader reader, int ordinal)
        {
            var value = reader.GetValue(ordinal);
            // DuckDB BLOB streams point into the current native result. Copy before
            // the reader advances or is disposed so returned values remain usable.
            if (value is Stream stream)
            {
                using (stream)
                using (var buffer = new MemoryStream())
                {
                    stream.CopyTo(buffer);
                    return buffer.ToArray();
                }
            }
            return value;
        }

        internal static bool IsMissingTable(Exception error)
        {
#if NETFRAMEWORK
            return false;
#else
            // 1.5.5 reports Invalid for prepare errors, including missing tables.
            // Match the specific catalog diagnostic, not all catalog/SQL errors.
            return error is DuckDB.NET.Data.DuckDBException duck &&
                duck.Message.StartsWith("Catalog Error: Table with name ", StringComparison.Ordinal) &&
                duck.Message.Split('\n')[0].EndsWith(" does not exist!", StringComparison.Ordinal);
#endif
        }

        internal static void TryCleanup(Action action)
        {
            try { action(); } catch (Exception) { /* Preserve the original operation error. */ }
        }
    }
}
