task . Compile, Build, ImportDebug, Test

Set-StrictMode -Version 4

############################################################

$SOURCE_PATH = "$PSScriptRoot\source"
$SCRIPT_PATH = "$PSScriptRoot\scripts"

$DLL_PATH = "$SOURCE_PATH\Horker.Data.Tests\bin\{0}\netcoreapp3.1"

$MODULE_PATH = "$PSScriptRoot\module\{0}\HorkerDataQuery"

$HELP_INPUT =  "$SOURCE_PATH\Horker.Data.Tests\bin\Release\netcoreapp3.1\Horker.Data.dll"
$HELP_INTERM = "$SOURCE_PATH\Horker.Data.Tests\bin\Release\netcoreapp3.1\Horker.Data.dll-Help.xml"
$HELP_OUTPUT = "$MODULE_PATH\Horker.Data.dll-Help.xml" -f "Release"

$HELPGEN = "$PSScriptRoot\vendor\XmlDoc2CmdletDoc.0.2.13\tools\XmlDoc2CmdletDoc.exe"

$OBJECT_FILES = @(
    "Horker.Data.dll"
    "Horker.Data.pdb"
    "System.Data.Odbc.dll"
    "System.Data.OleDb.dll"
    "System.Data.SqlClient.dll"
    "System.Data.SQLite.dll"
    "Npgsql.dll"
)

$NATIVE_PATH = "$PSScriptRoot\vendor\System.Data.SQLite.Core.1.0.112.0\runtimes\win-x64\native\netstandard2.0"

############################################################

function New-FolderSkip {
    param(
        [string]$Path
    )

    try {
        $null = New-Item -Type Directory $Path -EA Stop
        Write-Host -ForegroundColor DarkCyan $Path
    }
    catch {
        Write-Host -ForegroundColor DarkYellow $_
    }
}

function Copy-ItemSkip {
    param(
        [string]$Source,
        [string]$Dest
    )

    try {
        Copy-Item $Source $Dest
        Write-Host -ForegroundColor DarkCyan "$Source => $Dest"
    }
    catch {
        Write-Host -ForegroundColor DarkYellow $_
    }
}

############################################################

task Compile {
    dotnet build "$SOURCE_PATH\dataquery.sln" -c Debug -nologo -v minimal
    dotnet build "$SOURCE_PATH\dataquery.sln" -c Release -nologo -v minimal
}

task Build {

    . {
        $ErrorActionPreference = "Continue"

        "Release", "Debug" | foreach {
            $modulePath = $MODULE_PATH -f $_
            $dllPath = $DLL_PATH -f "Release"

            New-FolderSkip "$modulePath\x64"

            Copy-ItemSkip "$SCRIPT_PATH\*" $modulePath

            foreach ($f in $OBJECT_FILES) {
                Copy-ItemSkip "$dllPath\$f" $modulePath
            }

            Copy-ItemSkip "$NATIVE_PATH\*" "$modulePath\x64\"
        }
    }
}

task BuildHelp `
    -Inputs $HELP_INPUT `
    -Outputs $HELP_OUTPUT `
{
    $xmlFile = "$SOURCE_PATH\Horker.Data\bin\Release\netcoreapp2.1\Horker.Data.xml"
    Copy-Item $xmlFile (Split-Path -Parent $HELP_INPUT)
    . $HELPGEN $HELP_INPUT

    "Release", "Debug" | foreach {
        $modulePath = $MODULE_PATH -f $_
        Copy-Item $HELP_INTERM $modulePath
    }
}

task Test {
    Invoke-Pester "$PSScriptRoot\tests"
}

task ImportDebug {
    Import-Module ($MODULE_PATH -f "Debug") -Force
}

task Clean {
    "Release", "Debug" | foreach {
        $modulePath = $MODULE_PATH -f $_
        Remove-Item "$modulePath\*" -Force -Recurse -EA Continue
    }
}
