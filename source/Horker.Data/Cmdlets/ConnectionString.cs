using System;
using System.Collections;
using System.Collections.Generic;
using System.Configuration;
using System.Data.Common;
using System.Management.Automation;
using System.Reflection;

#pragma warning disable CS1591

namespace Horker.Data
{
    /// <summary>
    /// <para type="synopsis">Registers a connection string to the ConfigurationManager.</para>
    /// <para type="description">The Register-DataConnectionString cmdlet registers a connection string to the ConfigurationManager.</para>
    /// </summary>
    [Cmdlet("Register", "DataConnectionString")]
    [OutputType(typeof(void))]
    public class RegisterDataConnectionString : PSCmdlet
    {
        /// <summary>
        /// <para type="description">A connection string name.</para>
        /// </summary>
        [Parameter(Position = 0, Mandatory = true)]
        public string Name { get; set; }

        /// <summary>
        /// <para type="description">A database provider name.</para>
        /// </summary>
        [Parameter(Position = 1, Mandatory = true)]
        public string ProviderName { get; set; }

        /// <summary>
        /// <para type="description">A connection string.</para>
        /// </summary>
        [Parameter(Position = 2, Mandatory = true)]
        public string ConnectionString { get; set; }

        protected override void EndProcessing()
        {
            try
            {
                AddConnectionString(Name, ProviderName, ConnectionString);
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "", ErrorCategory.NotSpecified, null));
            }
        }

        public static void AddConnectionString(string name, string providerName, string connectionString)
        {
            if (ConfigurationManager.ConnectionStrings[name] != null)
                throw new RuntimeException("Connection string name already exists");

            // Source:
            // https://stackoverflow.com/questions/360024/how-do-i-set-a-connection-string-config-programmatically-in-net

            var collection = ConfigurationManager.ConnectionStrings;

            var elementReadOnlyField =
                // .NET Framework
                typeof(ConfigurationElementCollection).GetField("_bReadOnly", BindingFlags.Instance | BindingFlags.NonPublic) ??
                // .NET Core
                typeof(ConfigurationElementCollection).GetField("_readOnly", BindingFlags.Instance | BindingFlags.NonPublic);
            elementReadOnlyField.SetValue(collection, false);

            var collectionReadOnlyField =
                // .NET Framework
                typeof(ConfigurationElementCollection).GetField("bReadOnly", BindingFlags.Instance | BindingFlags.NonPublic) ??
                // .NET Core
                typeof(ConfigurationElementCollection).GetField("_readOnly", BindingFlags.Instance | BindingFlags.NonPublic);

            collectionReadOnlyField.SetValue(collection, false);

            collection.Add(new ConnectionStringSettings(name, connectionString, providerName));

            collectionReadOnlyField.SetValue(collection, true);
            elementReadOnlyField.SetValue(collection, true);
        }
    }

    /// <summary>
    /// <para type="synopsis">Removes a connection string definition from the ConfigurationManager.</para>
    /// <para type="description">The Unregister-DataConnectionString cmdlet removes a connection string definition from the ConfigurationManager.</para>
    /// </summary>
    [Cmdlet("Unregister", "DataConnectionString")]
    [OutputType(typeof(void))]
    public class UnregisterDataConnectionString : PSCmdlet
    {
        /// <summary>
        /// <para type="description">A connection string name.</para>
        /// </summary>
        [Parameter(Position = 0, Mandatory = true)]
        public string Name { get; set; }

        protected override void EndProcessing()
        {
            try
            {
                RemoveConnectionString(Name);
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "", ErrorCategory.NotSpecified, null));
            }
        }

        public static void RemoveConnectionString(string name)
        {
            if (ConfigurationManager.ConnectionStrings[name] == null)
                throw new RuntimeException("Connection string name not found");

            var collection = ConfigurationManager.ConnectionStrings;

            var elementReadOnlyField = typeof(ConfigurationElement).
                GetField("_bReadOnly", BindingFlags.Instance | BindingFlags.NonPublic);
            elementReadOnlyField.SetValue(collection, false);

            var collectionReadOnlyField = typeof(ConfigurationElementCollection).
                GetField("bReadOnly", BindingFlags.Instance | BindingFlags.NonPublic);
            collectionReadOnlyField.SetValue(collection, false);


            collection.Remove(name);

            collectionReadOnlyField.SetValue(collection, true);
            elementReadOnlyField.SetValue(collection, true);
        }

        public static void RemoveAllConnectionStrings()
        {
            var collection = ConfigurationManager.ConnectionStrings;

            var names = new List<string>();
            foreach (ConnectionStringSettings cs in collection)
                names.Add(cs.Name);

            foreach (var name in names)
                RemoveConnectionString(name);
        }
    }

    /// <summary>
    /// <para type="synopsis">Gets connection strings defined in the ConfigurationManager.</para>
    /// <para type="description">The Get-DataConnectionString cmdlet gets connection strings defined in the ConfigurationManager.</para>
    /// </summary>
    [Cmdlet("Get", "DataConnectionString")]
    [OutputType(typeof(ConnectionStringSettings))]
    public class GetDataConnectionString : PSCmdlet
    {
        protected override void EndProcessing()
        {
            WriteObject(ConfigurationManager.ConnectionStrings);
        }
    }

    /// <summary>
    /// <para type="synopsis">Creates a connection string based on the given parameters.</para>
    /// <para type="description">The New-DataConnectionString cmdlet creates a connection string based on parameters for a specific database provider.</para>
    /// <para type="description">When the -TestConnection parameter is specified, the cmdlet tries to connect to a database with the newly created connection string.</para>
    /// </summary>
    [Cmdlet("New", "DataConnectionString")]
    [OutputType(typeof(string))]
    public class NewDataConnectionString : PSCmdlet
    {
        /// <summary>
        /// <para type="description">A database provider name.</para>
        /// </summary>
        [Parameter(Position = 0, Mandatory = true)]
        public string ProviderName { get; set; }

        /// <summary>
        /// <para type="description">A set of parameters that should be included in a connection string.</para>
        /// </summary>
        [Parameter(Position = 1, Mandatory = true)]
        public Hashtable Parameters { get; set; }

        /// <summary>
        /// <para type="description">Makes the cmdlet to test connectivity of a generated connection string.</para>
        /// </summary>
        [Parameter(Position = 2, Mandatory = false)]
        public SwitchParameter TestConnection { get; set; }

        protected override void EndProcessing()
        {
            var factory = DbProviderFactories.GetFactory(ProviderName);
            var builder = factory.CreateConnectionStringBuilder();

            foreach (DictionaryEntry entry in Parameters)
                builder.Add(entry.Key.ToString(), entry.Value);

            var cs = builder.ConnectionString;

            if (TestConnection)
            {
                try
                {
                    var connection = factory.CreateConnection();
                    connection.ConnectionString = cs;
                    connection.Open();
                    connection.Close();

                    Host.UI.WriteLine(ConsoleColor.Cyan, Host.UI.RawUI.BackgroundColor, "Connection test succeeded");
                }
                catch (DbException ex)
                {
                    WriteError(new ErrorRecord(ex, "", ErrorCategory.NotSpecified, null));
                }
            }

            WriteObject(builder.ConnectionString);
        }
    }
}
