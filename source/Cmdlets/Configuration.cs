using System;
using System.Management.Automation;
using System.Xml;

#pragma warning disable CS1591

namespace Horker.Data
{
    /// <summary>
    /// <para type="synopsis">Registers connection strings and database provider factories.</para>
    /// <para type="description">The Register-DataConfiguration cmdlet reads a configuration file (app.config or web.config in most cases), finds the /configuration/connectionStrings and /configuration/system.data/DbProviderFactories sections and, according to their contents, registers connection strings and database provider factories to the ConfigurationManager.</para>
    /// </summary>
    [Cmdlet("Register", "DataConfiguration")]
    public class RegisterDataConfiguration : PSCmdlet
    {
        /// <summary>
        /// <para type="description">A configuration file name.</para>
        /// </summary>
        [Parameter(Position = 0, Mandatory = true)]
        public string ConfigurationFile { get; set; }

        protected override void EndProcessing()
        {
            try
            {
                LoadConfiguration(ConfigurationFile);
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "", ErrorCategory.NotSpecified, null));
            }
        }

        public static void LoadConfiguration(string configurationFile)
        {
            var doc = new XmlDocument();
            doc.Load(configurationFile);

            RegisterDbProviderFactories(doc);
            RegisterConnectionString(doc);
        }

        private static void RegisterDbProviderFactories(XmlDocument doc)
        {
            var baseNodes = doc.DocumentElement.SelectNodes("/configuration/system.data/DbProviderFactories");

            foreach (XmlNode node in baseNodes)
            {
                var nodes = node.ChildNodes;

                string invariant;
                foreach (XmlNode n in nodes)
                {
                    switch (n.Name)
                    {
                        case "add":
                            var name = n.Attributes["name"].InnerText;
                            invariant = n.Attributes["invariant"].InnerText;
                            var description = n.Attributes["description"].InnerText;
                            var type = n.Attributes["type"].InnerText;
                            RegisterDbProviderFactory.AddDbProviderFactory(name, invariant, description, type);
                            break;

                        case "remove":
                            invariant = n.Attributes["invariant"].InnerText;
                            try
                            {
                                UnregisterDbProviderFactory.RemoveDbProviderFactory(invariant);
                            }
                            catch (RuntimeException)
                            {
                                // Ignore error
                            }
                            break;

                        case "clear":
                            try
                            {
                                UnregisterDbProviderFactory.RemoveAllDbProviderFactories();
                            }
                            catch (RuntimeException)
                            {
                                // Ignore error
                            }
                            break;

                        default:
                            throw new RuntimeException(String.Format("Unknown element '{0}' under system.data/DbProviderFactories", n.Name));
                    }
                }
            }
        }

        private static void RegisterConnectionString(XmlDocument doc)
        {
            var baseNodes = doc.DocumentElement.SelectNodes("/configuration/connectionStrings");
            foreach (XmlNode node in baseNodes)
            {
                var nodes = node.ChildNodes;

                string name;
                foreach (XmlNode n in nodes)
                {
                    switch (n.Name)
                    {
                        case "add":
                            name = n.Attributes["name"].InnerText;
                            var providerName = n.Attributes["providerName"].InnerText;
                            var connectionString = n.Attributes["connectionString"].InnerText;
                            RegisterDataConnectionString.AddConnectionString(name, providerName, connectionString);

                            break;

                        case "remove":
                            name = n.Attributes["name"].InnerText;
                            try
                            {
                                UnregisterDataConnectionString.RemoveConnectionString(name);
                            }
                            catch (RuntimeException)
                            {
                                // Ignore error
                            }
                            break;

                        case "clear":
                            try
                            {
                                UnregisterDataConnectionString.RemoveAllConnectionStrings();
                            }
                            catch (RuntimeException)
                            {
                                // Ignore error
                            }
                            break;

                        default:
                            throw new RuntimeException(String.Format("Unknown element '{0}' under /connectionStrings", n.Name));
                    }
                }
            }
        }
    }
}
