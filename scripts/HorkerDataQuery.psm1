. (Join-Path $PSScriptRoot 'Assert-SupportedHost.ps1')
$release = 0
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    $release = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release
    $target = 'net48'
}
else { $target = 'net10.0' }
Assert-SupportedHost -Edition $PSVersionTable.PSEdition -Version $PSVersionTable.PSVersion -Is64Bit ([Environment]::Is64BitProcess) -Platform ([Environment]::OSVersion.Platform.ToString()) -FrameworkRelease $release
$libraryPath = Join-Path $PSScriptRoot "lib\$target"
$assemblyPath = Join-Path $libraryPath 'Horker.Data.dll'
# Keep provider dependencies separate from assemblies bundled with PowerShell.
if ($PSVersionTable.PSEdition -eq 'Core') {
if (-not ('Horker.Data.ModuleLoadContext' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Collections.Generic;
using System.Reflection;
using System.Runtime.Loader;

namespace Horker.Data
{
    public sealed class ModuleLoadContext : AssemblyLoadContext
    {
        public object Module { get; set; }
        private static readonly Dictionary<string, ModuleLoadContext> Contexts = new Dictionary<string, ModuleLoadContext>(StringComparer.OrdinalIgnoreCase);
        public static ModuleLoadContext ForPath(string path)
        {
            lock (Contexts)
            {
                if (!Contexts.TryGetValue(path, out var context))
                    Contexts[path] = context = new ModuleLoadContext(path);
                return context;
            }
        }
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

$script:LoadContext = [Horker.Data.ModuleLoadContext]::ForPath($assemblyPath)
$script:CmdletAssembly = $LoadContext.LoadFromAssemblyPath($assemblyPath)
}
else {
    # Windows PowerShell shares the Framework's providers with the host.
    Add-Type -AssemblyName System.Data, System.Configuration
    foreach ($file in 'System.Data.SQLite.dll', 'Horker.Data.dll') {
        $path = Join-Path $libraryPath $file
        $name = [Reflection.AssemblyName]::GetAssemblyName($path)
        foreach ($loaded in [AppDomain]::CurrentDomain.GetAssemblies()) {
            if ($loaded.GetName().Name -eq $name.Name -and
                ($loaded.FullName -ne $name.FullName -or $loaded.Location -ne $path)) {
                throw "Assembly conflict: $($loaded.FullName) at $($loaded.Location); required $path. Open a new powershell.exe -NoProfile process and import this module first."
            }
        }
        $assembly = [Reflection.Assembly]::LoadFrom($path)
    }
    $script:CmdletAssembly = $assembly
}
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    Import-Module $assemblyPath -Scope Local -Force -ErrorAction Stop
}
else {
    if ($null -ne $LoadContext.Module) {
        # Reuse the exported command metadata; -Force would load the DLL in Default.
        Import-Module -ModuleInfo $LoadContext.Module -Scope Local -ErrorAction Stop
    }
    else {
        $LoadContext.Module = Import-Module -Assembly $CmdletAssembly -Scope Local -PassThru -ErrorAction Stop
    }
}
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
    if ($PSVersionTable.PSEdition -eq 'Desktop') {
        if ($f.Assembly -eq 'Npgsql') { continue }
        if ($f.Assembly -eq 'System.Data.SQLite') {
            $assembly = [Reflection.Assembly]::LoadFrom((Join-Path $libraryPath 'System.Data.SQLite.dll'))
        }
        else {
            $assembly = [System.Data.Common.DbConnection].Assembly
        }
    }
    else {
        $assembly = $LoadContext.LoadFromAssemblyName([Reflection.AssemblyName]::new($f.Assembly))
    }
    $factoryType = $assembly.GetType($f.Type, $true)
    Register-DbProviderFactory $f.Name $f.InvariantName $f.Description $factoryType.AssemblyQualifiedName -ErrorAction Stop
}

if ($null -eq (Get-DataConnectionString)['memory']) {
    Register-DataConnectionString 'memory' 'System.Data.SQLite' "Data Source=':memory:'" -ErrorAction Stop
}
Export-ModuleMember -Cmdlet * -Alias *
