task . Compile, Build, BuildHelp, ImportDebug, Test

Set-StrictMode -Version 4

############################################################

$SOURCE_PATH = "$PSScriptRoot\source"
$SCRIPT_PATH = "$PSScriptRoot\scripts"

$MODULE_PATH = "$PSScriptRoot\HorkerDataQuery"
$DEBUG_MODULE_PATH = "$PSScriptRoot\debug\HorkerDataQuery"

$HELP_INPUT =  "$SOURCE_PATH\bin\Release\Horker.Data.dll"
$HELP_INTERM = "$SOURCE_PATH\bin\Release\Horker.Data.dll-Help.xml"
$HELP_OUTPUT = "$MODULE_PATH\Horker.Data.dll-Help.xml"

$HELPGEN = "$PSScriptRoot\vendor\XmlDoc2CmdletDoc.0.2.10\tools\XmlDoc2CmdletDoc.exe"

############################################################

function New-FolderSkip {
  param(
    [string]$Path
  )

  try {
    $null = New-Item -Type Directory $Path -EA Stop
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
  msbuild "$SOURCE_PATH\dataquery.sln" /p:Configuration=Debug /nologo /v:quiet
  msbuild "$SOURCE_PATH\dataquery.sln" /p:Configuration=Release /nologo /v:quiet
}

task Build {

  . {
    $ErrorActionPreference = "Continue"

    New-FolderSkip "$MODULE_PATH\x64"
    New-FolderSkip "$MODULE_PATH\x86"

    Copy-ItemSkip "$SCRIPT_PATH\*" $MODULE_PATH
    Copy-ItemSkip "$SOURCE_PATH\bin\Release\Horker.Data.dll" $MODULE_PATH
    Copy-ItemSkip "$SOURCE_PATH\bin\Release\Horker.Data.pdb" $DEBUG_MODULE_PATH
    Copy-ItemSkip "$SOURCE_PATH\bin\Release\System.Data.SQLite.dll" $MODULE_PATH
    Copy-ItemSkip "$SOURCE_PATH\bin\Release\x64\*" "$MODULE_PATH\x64\"
    Copy-ItemSkip "$SOURCE_PATH\bin\Release\x86\*" "$MODULE_PATH\x86\"

    New-FolderSkip "$DEBUG_MODULE_PATH\x64"
    New-FolderSkip "$DEBUG_MODULE_PATH\x86"

    Copy-ItemSkip "$SCRIPT_PATH\*" $DEBUG_MODULE_PATH
    Copy-ItemSkip "$SOURCE_PATH\bin\Debug\Horker.Data.dll" $DEBUG_MODULE_PATH
    Copy-ItemSkip "$SOURCE_PATH\bin\Debug\Horker.Data.pdb" $DEBUG_MODULE_PATH
    Copy-ItemSkip "$SOURCE_PATH\bin\Debug\System.Data.SQLite.dll" $DEBUG_MODULE_PATH
    Copy-ItemSkip "$SOURCE_PATH\bin\Debug\x64\*" "$DEBUG_MODULE_PATH\x64\"
    Copy-ItemSkip "$SOURCE_PATH\bin\Debug\x86\*" "$DEBUG_MODULE_PATH\x86\"
  }
}

task BuildHelp `
  -Inputs $HELP_INPUT `
  -Outputs $HELP_OUTPUT `
{
  . $HELPGEN $HELP_INPUT

  Copy-Item $HELP_INTERM $MODULE_PATH
}

task Test {
  Invoke-Pester "$PSScriptRoot\tests"
}

task ImportDebug {
  Import-Module $DEBUG_MODULE_PATH -Force
}

task Clean {
  Remove-Item "$MODULE_PATH\*" -Force -Recurse -EA Continue
  Remove-Item "$DEBUG_MODULE_PATH\*" -Force -Recurse -EA Continue
}
