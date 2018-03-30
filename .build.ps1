task . Build, BuildHelp, ImportDebug

Set-StrictMode -Version 4

# a bug-fixed version to handle errors correctly
function Copy-ItemError {
  param(
    [string]$Source,
    [string]$Dest
  )

  try {
    Copy-Item $Source $Dest
  }
  catch {
    Write-Error $_
  }
}

$ModulePath = "$PSScriptRoot\HorkerDataQuery"
$DebugModulePath = "$PSScriptRoot\debug\HorkerDataQuery"

task Build {

  . {
    $ErrorActionPreference = "Continue"

    $void = mkdir $ModulePath
    $void = mkdir "$ModulePath\x64"
    $void = mkdir "$ModulePath\x86"

    Copy-ItemError "$PSScriptRoot\scripts\*" $ModulePath
    Copy-ItemError "$PSScriptRoot\cs\dataquery\bin\Release\Horker.Data.dll" $ModulePath
    Copy-ItemError "$PSScriptRoot\cs\dataquery\bin\Release\System.Data.SQLite.dll" $ModulePath
    Copy-ItemError "$PSScriptRoot\cs\dataquery\bin\Release\x64\*" "$ModulePath\x64"
    Copy-ItemError "$PSScriptRoot\cs\dataquery\bin\Release\x86\*" "$ModulePath\x86"

    $void = mkdir "debug"
    $void = mkdir $DebugModulePath
    $void = mkdir "$DebugModulePath\x64"
    $void = mkdir "$DebugModulePath\x86"

    Copy-ItemError "$PSScriptRoot\scripts\*" $DebugModulePath
    Copy-ItemError "$PSScriptRoot\cs\dataquery\bin\Debug\Horker.Data.dll" $DebugModulePath
    Copy-ItemError "$PSScriptRoot\cs\dataquery\bin\Debug\System.Data.SQLite.dll" $DebugModulePath
    Copy-ItemError "$PSScriptRoot\cs\dataquery\bin\Debug\x64\*" "$DebugModulePath\x64"
    Copy-ItemError "$PSScriptRoot\cs\dataquery\bin\Debug\x86\*" "$DebugModulePath\x86"
  }
}

$HELP_INPUT = "$PSScriptRoot\cs\dataquery\bin\Release\Horker.Data.dll"
$HELP_INTERM = "$PSScriptRoot\cs\dataquery\bin\Release\Horker.Data.dll-Help.xml"
$HELP_OUTPUT = "$ModulePath\Horker.Data.dll-Help.xml"

task BuildHelp `
  -Inputs $HELP_INPUT `
  -Outputs $HELP_OUTPUT `
{
  vendor\XmlDoc2CmdletDoc.0.2.10\tools\XmlDoc2CmdletDoc.exe $HELP_INPUT

  Copy-Item $HELP_INTERM $ModulePath
}

task ImportDebug {
  Import-Module .\debug\HorkerDataQuery -Force
}

task Clean {
  Remove-Item "$PSScriptRoot\HorkerDataQuery\*" -Force -EA Continue
}
