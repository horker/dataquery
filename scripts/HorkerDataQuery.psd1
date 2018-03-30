#
# Module manifest for module 'HorkerDataQuery'
#
# Generated by: horker
#
# Generated on: 2017/12/03
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'HorkerDataQuery.psm1'

# Version number of this module.
ModuleVersion = '1.0.2'

# Supported PSEditions
# CompatiblePSEditions = ''

# ID used to uniquely identify this module
GUID = 'fb732285-38d2-40da-93d1-be7cde81ddf7'

# Author of this module
Author = 'horker'

# Company or vendor of this module
CompanyName = ''

# Copyright statement for this module
Copyright = '(c) 2018 horker. All rights reserved.'

# Description of the functionality provided by this module
Description = "Horker DataQuery is a database query utility based on ADO.NET.

The main features are:
- Written in C#, so that it works fast for large data
- Supports every database product that provides the ADO.NET driver, including SQL Server, Oracle, MySQL, PostgreSQL, SQLite, Access, OLEDB, and ODBC
- Returns query results as PowerShell objects, and exports PowerShell objects into database tables
- Reads app.config` or web.config` to define database providers and connection strings
- Gets information from the database schema
- Provides the built-in SQLite driver

This module would be helpful for software development, data analysis, and various data manipulation tasks.

For more details, see the project site: https://github.com/horker/dataquery"

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
DotNetFrameworkVersion = '4.5'

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @()

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @(
  "Invoke-DataQuery"
  "Get-DataQueryResult"

  "Export-DataTable"

  "New-DataConnection"
  "Close-DataConnection"
  "Get-DataConnectionHistory"

  "Register-DataConnectionString"
  "Unregister-DataConnectionString"
  "Get-DataConnectionString"
  "New-DataConnectionString"

  "Register-DbProviderFactory"
  "Unregister-DbProviderFactory"
  "Get-DbProviderFactory"

  "Register-DataConfiguration"

  "Get-DataSchema"
)

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @(
  "idq"
)

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @(
          'database', 'relational', 'rdb', 'rdbms', 'query', 'schema'
          'sql', 'server', 'sqlserver', 'oracle', 'mysql', 'postgresql', 'sqlite', 'access', 'msaccess',
          'data', 'analysis', 'conversion',
          'pandas', 'dplyr'
        )

        # A URL to the license for this module.
        LicenseUri = 'https://opensource.org/licenses/MIT'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/horker/dataquery'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = @"
v1.0.2
Several bug fixes

v1.0.1
Bug fix: Added a missing file in the 32-bit environment

v1.0.0
First release
"@

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
