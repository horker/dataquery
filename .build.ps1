task . Build, BuildHelp, ImportLocally

Set-StrictMode -Version 4

# a bug-fixed version to handle errors correctly
function Copy-ItemBugFixed {
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

task Build {

  if (!(Test-Path $ModulePath)) {
    $void = mkdir $ModulePath
  }
  if (!(Test-Path "$ModulePath\x64")) {
    $void = mkdir "$ModulePath\x64"
  }
  if (!(Test-Path "$ModulePath\x86")) {
    $void = mkdir "$ModulePath\x86"
  }

  . {
    $ErrorActionPreference = "Continue"
    Copy-ItemBugFixed "$PSScriptRoot\scripts\*" $ModulePath
    Copy-ItemBugFixed "$PSScriptRoot\cs\dataquery\bin\Release\Horker.Data.dll" $ModulePath
    Copy-ItemBugFixed "$PSScriptRoot\cs\dataquery\bin\Release\System.Data.SQLite.dll" $ModulePath
    Copy-ItemBugFixed "$PSScriptRoot\cs\dataquery\bin\Release\x64\*" "$ModulePath\x64"
    Copy-ItemBugFixed "$PSScriptRoot\cs\dataquery\bin\Release\x86\*" "$ModulePath\x86"
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

task ImportLocally {
  Import-Module .\HorkerDataQuery -Force
}

task Clean {
  Remove-Item "$PSScriptRoot\HorkerDataQuery\*" -Force -EA Continue
}
