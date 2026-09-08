using System;
using System.Configuration;
using System.Data;
using System.Data.Common;
using System.Management.Automation;


#pragma warning disable CS1591

namespace Horker.Data
{
    /// <summary>
    /// <para type="synopsis">Registers a database provider factory to the ConfigurationManager.</para>
    /// <para type="description">The Register-DbProviderFactory cmdlet registers a database provider factory to the ConfigurationManager.</para>
    /// </summary>
    [Cmdlet("Register", "DbProviderFactory")]
    [OutputType(typeof(void))]
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
            try
            {
                AddDbProviderFactory(Name, Invariant, Description, Type);
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "", ErrorCategory.NotSpecified, null));
            }
        }

        public static void AddDbProviderFactory(string name, string invariant, string description, string type)
        {
            ProviderRegistry.Register(name, invariant, description, type);
        }
    }

    /// <summary>
    /// <para type="synopsis">Removes a database provider factory from the ConfigurationManager.</para>
    /// <para type="description">The Unregister-DbProviderFactory cmdlet removes a database provider factory from the ConfigurationManager.</para>
    /// </summary>
    [Cmdlet("Unregister", "DbProviderFactory")]
    [OutputType(typeof(void))]
    public class UnregisterDbProviderFactory : PSCmdlet
    {
        /// <summary>
        /// <para type="description">A database provider name.</para>
        /// </summary>
        [Parameter(Position = 0, Mandatory = true)]
        public string ProviderName { get; set; }

        protected override void EndProcessing()
        {
            try
            {
                RemoveDbProviderFactory(ProviderName);
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "", ErrorCategory.NotSpecified, null));
            }
        }

        public static void RemoveDbProviderFactory(string invariant)
        {
            ProviderRegistry.Remove(invariant);
        }

        public static void RemoveAllDbProviderFactories()
        {
            ProviderRegistry.Clear();
        }
    }

    /// <summary>
    /// <para type="synopsis">Gets database provider factories defined in the ConfigurationManager.</para>
    /// <para type="description">The Get-DbProviderFactory cmdlet gets database provider factories defined in the ConfigurationManager.</para>
    /// <para type="description">If the -ProviderName parameter is not specified, it returns all database provider factories.</para>
    /// </summary>
    [Cmdlet("Get", "DbProviderFactory")]
    [OutputType(typeof(DataTable))]
    public class GetDbProviderFactory : PSCmdlet
    {
        /// <summary>
        /// <para type="description">A database provider name.</para>
        /// </summary>
        [Parameter(Position = 0, Mandatory = false)]
        public string ProviderName { get; set; }

        protected override void EndProcessing()
        {
            if (ProviderName != null && ProviderName != "")
            {
                WriteObject(ProviderRegistry.GetFactory(ProviderName));
                return;
            }

            WriteObject(ProviderRegistry.GetFactoryClasses());
        }
    }
}
