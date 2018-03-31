task . Compile, Build, BuildHelp, ImportDebug

Set-StrictMode -Version 4

############################################################

$SourcePath = "$PSScriptRoot\cs\dataquery"
$ModulePath = "$PSScriptRoot\HorkerDataQuery"
$DebugModulePath = "$PSScriptRoot\debug\HorkerDataQuery"

############################################################

function New-FolderSkip {
  param(
    [string]$Path
  )

  try {
    New-Item -Type Directory $Path -EA Stop
  }
  catch {
    Write-Host -ForegroundColor DarkCyan $_
  }
}

function Copy-ItemSkip {
  param(
    [string]$Source,
    [string]$Dest
  )

  try {
    Copy-Item $Source $Dest
  }
  catch {
    Write-Host -ForegroundColor DarkCyan $_
  }
}

############################################################

task Compile {
  msbuild "$SourcePath\dataquery.sln" /p:Configuration=Debug /nologo /v:minimal
  msbuild "$SourcePath\dataquery.sln" /p:Configuration=Release /nologo /v:minimal
}

task Build {

  . {
    $ErrorActionPreference = "Continue"

    New-FolderSkip $ModulePath
    New-FolderSkip "$ModulePath\x64"
    New-FolderSkip "$ModulePath\x86"

    Copy-ItemSkip "$PSScriptRoot\scripts\*" $ModulePath
    Copy-ItemSkip "$PSScriptRoot\cs\dataquery\bin\Release\Horker.Data.dll" $ModulePath
    Copy-ItemSkip "$PSScriptRoot\cs\dataquery\bin\Release\System.Data.SQLite.dll" $ModulePath
    Copy-ItemSkip "$PSScriptRoot\cs\dataquery\bin\Release\x64\*" "$ModulePath\x64"
    Copy-ItemSkip "$PSScriptRoot\cs\dataquery\bin\Release\x86\*" "$ModulePath\x86"

    New-FolderSkip "debug"
    New-FolderSkip $DebugModulePath
    New-FolderSkip "$DebugModulePath\x64"
    New-FolderSkip "$DebugModulePath\x86"

    Copy-ItemSkip "$PSScriptRoot\scripts\*" $DebugModulePath
    Copy-ItemSkip "$PSScriptRoot\cs\dataquery\bin\Debug\Horker.Data.dll" $DebugModulePath
    Copy-ItemSkip "$PSScriptRoot\cs\dataquery\bin\Debug\Horker.Data.pdb" $DebugModulePath
    Copy-ItemSkip "$PSScriptRoot\cs\dataquery\bin\Debug\System.Data.SQLite.dll" $DebugModulePath
    Copy-ItemSkip "$PSScriptRoot\cs\dataquery\bin\Debug\x64\*" "$DebugModulePath\x64"
    Copy-ItemSkip "$PSScriptRoot\cs\dataquery\bin\Debug\x86\*" "$DebugModulePath\x86"
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
