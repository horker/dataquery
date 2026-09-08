param(
    [Parameter(Mandatory = $true)][string]$ModulePath,
    [Parameter(Mandatory = $true)][string]$PesterPath
)
$ErrorActionPreference = 'Stop'
Import-Module $ModulePath -Force
Import-Module $PesterPath -Force
$configuration = New-PesterConfiguration
$configuration.Run.Path = Join-Path $PSScriptRoot '..\tests'
$configuration.Run.PassThru = $true
$configuration.TestRegistry.Enabled = $false
$configuration.Output.Verbosity = 'Detailed'
$result = Invoke-Pester -Configuration $configuration
if ($result.Result -ne 'Passed') { exit 1 }
