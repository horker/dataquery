using System;
using System.Collections.Generic;
using System.Configuration;
using System.Reflection;

namespace Horker.Data
{
    internal static class ConnectionStringMutation
    {
        private static readonly object Sync = new object();

        internal static void Apply(Action<ConnectionStringSettingsCollection> change)
        {
            lock (Sync)
            {
                var collection = ConfigurationManager.ConnectionStrings;
                var fields = new List<FieldInfo>();
                for (var type = collection.GetType(); type != null; type = type.BaseType)
                    foreach (var field in type.GetFields(BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.DeclaredOnly))
                        if (field.FieldType == typeof(bool) &&
                            (field.Name == "_bReadOnly" || field.Name == "bReadOnly" || field.Name == "_readOnly"))
                            fields.Add(field);
                if (fields.Count == 0)
                    throw new NotSupportedException("Cannot update connection strings on this runtime.");
                var previous = new List<bool>();
                try
                {
                    foreach (var field in fields)
                    {
                        previous.Add((bool)field.GetValue(collection));
                        field.SetValue(collection, false);
                    }
                    change(collection);
                }
                finally
                {
                    for (int i = previous.Count - 1; i >= 0; i--)
                        fields[i].SetValue(collection, previous[i]);
                }
            }
        }
    }
}
