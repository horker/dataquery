using System;
using System.Management.Automation;
using System.Data;
using System.Data.Common;
using System.Configuration;

namespace Horker.Data
{
    /// <summary>
    /// <para type="synopsis">Registers a database provider factory to the ConfigurationManager.</para>
    /// <para type="description">The Register-DbProviderFactory cmdlet registers a database provider factory to the ConfigurationManager.</para>
    /// </summary>
    [Cmdlet("Register", "DbProviderFactory")]
    public class RegisterDbProviderFactory : PSCmdlet
    {
        /// <summary>
        /// <para type="description">A database provider name.</para>
        /// </summary>
        [Parameter(Position = 0, Mandatory = true)]
        public string Name { get; set; }

        /// <summary>
        /// <para type="description">An invariant name.</para>
        /// </summary>
        [Parameter(Position = 1, Mandatory = true)]
        public string Invariant { get; set; }

        /// <summary>
        /// <para type="description">A human readable description.</para>
        /// </summary>
        [Parameter(Position = 2, Mandatory = true)]
        public string Description { get; set; }

        /// <summary>
        /// <para type="description">Factory classes specification.</para>
        /// </summary>
        [Parameter(Position = 3, Mandatory = true)]
        public string Type { get; set; }

        protected override void EndProcessing()
        {
            base.EndProcessing();

            try {
                AddDbProviderFactory(Name, Invariant, Description, Type);
            }
            catch (Exception ex) {
                WriteError(new ErrorRecord(ex, "", ErrorCategory.NotSpecified, null));
            }
        }

        public static void AddDbProviderFactory(string name, string invariant, string description, string type)
        {
            DataSet dataSet = ConfigurationManager.GetSection("system.data") as DataSet;
            var rows = dataSet.Tables[0].Rows;

            foreach (DataRow r in rows) {
                if (r["InvariantName"].ToString() == invariant) {
                    throw new RuntimeException("Invariant name already exists");
                }
            }

            rows.Add(name, description, invariant, type);
        }
    }

    /// <summary>
    /// <para type="synopsis">Removes a database provider factory from the ConfigurationManager.</para>
    /// <para type="description">The Unregister-DbProviderFactory cmdlet removes a database provider factory from the ConfigurationManager.</para>
    /// </summary>
    [Cmdlet("Unregister", "DbProviderFactory")]
    public class UnregisterDbProviderFactory : PSCmdlet
    {
        /// <summary>
        /// <para type="description">A database provider name.</para>
        /// </summary>
        [Parameter(Position = 0, Mandatory = true)]
        public string ProviderName { get; set; }

        protected override void EndProcessing()
        {
            base.EndProcessing();

            try {
                RemoveDbProviderFactory(ProviderName);
            }
            catch (Exception ex) {
                WriteError(new ErrorRecord(ex, "", ErrorCategory.NotSpecified, null));
            }
        }

        public static void RemoveDbProviderFactory(string invariant)
        {
            DataSet dataSet = ConfigurationManager.GetSection("system.data") as DataSet;
            var rows = dataSet.Tables[0].Rows;

            foreach (DataRow r in rows) {
                if (r["InvariantName"].ToString() == invariant) {
                    rows.Remove(r);
                    return;
                }
            }

            throw new RuntimeException("Invariant name not found");
        }

        public static void RemoveAllDbProviderFactories()
        {
            DataSet dataSet = ConfigurationManager.GetSection("system.data") as DataSet;
            var rows = dataSet.Tables[0].Rows;

            while (rows.Count > 0) {
                rows.RemoveAt(rows.Count - 1);
            }
        }
    }

    /// <summary>
    /// <para type="synopsis">Gets database provider factories defined in the ConfigurationManager.</para>
    /// <para type="description">The Get-DbProviderFactory cmdlet gets database provider factories defined in the ConfigurationManager.</para>
    /// <para type="description">If the -ProviderName parameter is not specified, it returns all database provider factories.</para>
    /// </summary>
    [Cmdlet("Get", "DbProviderFactory")]
    public class GetDbProviderFactory : PSCmdlet
    {
        /// <summary>
        /// <para type="description">A database provider name.</para>
        /// </summary>
        [Parameter(Position = 0, Mandatory = false)]
        public string ProviderName { get; set; }

        protected override void EndProcessing()
        {
            base.EndProcessing();

            if (ProviderName != null && ProviderName != "") {
                WriteObject(DbProviderFactories.GetFactory(ProviderName));
                return;
            }

            WriteObject(DbProviderFactories.GetFactoryClasses());
        }
    }
}