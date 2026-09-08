# Keep provider dependencies separate from assemblies bundled with PowerShell.
if (-not ('Horker.Data.ModuleLoadContext' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Reflection;
using System.Runtime.Loader;

namespace Horker.Data
{
    public sealed class ModuleLoadContext : AssemblyLoadContext
    {
        private readonly AssemblyDependencyResolver resolver;
        private readonly string directory;

        public ModuleLoadContext(string assemblyPath) : base("HorkerDataQuery")
        {
            resolver = new AssemblyDependencyResolver(assemblyPath);
            directory = Path.GetDirectoryName(assemblyPath);
        }

        protected override Assembly Load(AssemblyName name)
        {
            // Cmdlets and the host must share PowerShell's type identities.
            if (name.Name == "System.Management.Automation")
                return null;
            string path = resolver.ResolveAssemblyToPath(name);
            return path == null ? null : LoadFromAssemblyPath(path);
        }

        protected override IntPtr LoadUnmanagedDll(string name)
        {
            string path = resolver.ResolveUnmanagedDllToPath(name);
            if (path == null)
            {
                string candidate = Path.Combine(directory, name);
                if (File.Exists(candidate)) path = candidate;
            }
            return path == null ? IntPtr.Zero : LoadUnmanagedDllFromPath(path);
        }
    }
}
"@
}

$script:LoadContext = [Horker.Data.ModuleLoadContext]::new((Join-Path $PSScriptRoot 'Horker.Data.dll'))
$script:CmdletAssembly = $LoadContext.LoadFromAssemblyPath((Join-Path $PSScriptRoot 'Horker.Data.dll'))
Import-Module -Assembly $CmdletAssembly -Scope Local -ErrorAction Stop
$script:DefaultDbProviderFactories = @(
    @{
        Name = "Odbc Data Provider"
        InvariantName = "System.Data.Odbc"
        Description = ".Net Framework Data Provider for Odbc"
        Assembly = "System.Data.Odbc"; Type = "System.Data.Odbc.OdbcFactory"
    }
    @{
        Name = "OleDb Data Provider"
        InvariantName = "System.Data.OleDb"
        Description = ".Net Framework Data Provider for OleDb"
        Assembly = "System.Data.OleDb"; Type = "System.Data.OleDb.OleDbFactory"
    }
    @{
        Name = "SqlClient Data Provider"
        InvariantName = "System.Data.SqlClient"
        Description = ".Net Framework Data Provider for SqlServer"
        Assembly = "System.Data.SqlClient"; Type = "System.Data.SqlClient.SqlClientFactory"
    }
    @{
        Name = "SQLite Data Provider"
        InvariantName = "System.Data.SQLite"
        Description = ".NET Framework Data Provider for SQLite"
        Assembly = "System.Data.SQLite"; Type = "System.Data.SQLite.SQLiteFactory"
    }
    @{
        Name = "Npgsql Data Provider"
        InvariantName = "Npgsql"
        Description = ".Net Data Provider for PostgreSQL"
        Assembly = "Npgsql"; Type = "Npgsql.NpgsqlFactory"
    }
)

foreach ($f in $DefaultDbProviderFactories) {
    $assembly = $LoadContext.LoadFromAssemblyName([Reflection.AssemblyName]::new($f.Assembly))
    $factory = $assembly.GetType($f.Type, $true).GetField("Instance").GetValue($null)
    [System.Data.Common.DbProviderFactories]::RegisterFactory($f.InvariantName, $factory)
}

Register-DataConnectionString "memory" "System.Data.SQLite" "Data Source=':memory:'"

Export-ModuleMember -Cmdlet * -Alias *
