task . Build, BuildHelp, ImportLocally

Set-StrictMode -Version 4

$ModulePath = "$PSScriptRoot\HorkerDataQuery"

task Build {

  if (!(Test-Path $ModulePath)) {
    $void = mkdir $ModulePath
  }

  try {
    Copy-Item "$PSScriptRoot\scripts\*" $ModulePath
    Copy-Item "$PSScriptRoot\cs\dataquery\bin\Release\Horker.Data.dll" $ModulePath
    Copy-Item "$PSScriptRoot\cs\dataquery\bin\Release\System.Data.SQLite.dll" $ModulePath
    Copy-Item "$PSScriptRoot\cs\dataquery\bin\Release\x64" $ModulePath
    Copy-Item "$PSScriptRoot\cs\dataquery\bin\Release\x86" $ModulePath
  }
  catch {
    # Ignore
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
