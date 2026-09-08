task . Compile, Build, Test

Set-StrictMode -Version 4

############################################################

$SOURCE_PATH = "$PSScriptRoot\source"
$SCRIPT_PATH = "$PSScriptRoot\scripts"

$MODULE_PATH = "$PSScriptRoot\module\{0}\HorkerDataQuery"

task Compile {
    dotnet build "$SOURCE_PATH\dataquery.sln" -c Debug -nologo -v minimal
    if ($LASTEXITCODE -ne 0) { throw "Debug build failed." }
    dotnet build "$SOURCE_PATH\dataquery.sln" -c Release -nologo -v minimal
    if ($LASTEXITCODE -ne 0) { throw "Release build failed." }
}

task Build {
    foreach ($configuration in 'Release', 'Debug') {
        $modulePath = $MODULE_PATH -f $configuration
        $moduleRoot = [IO.Path]::GetFullPath("$PSScriptRoot\module") + [IO.Path]::DirectorySeparatorChar
        $modulePath = [IO.Path]::GetFullPath($modulePath)
        if (-not $modulePath.StartsWith($moduleRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Module output must be inside $moduleRoot"
        }
        if (Test-Path -LiteralPath $modulePath) {
            Get-ChildItem -LiteralPath $modulePath -Force | Remove-Item -Recurse -Force -ErrorAction Stop
        }
        # Publish resolves managed and native dependencies from the current NuGet packages.
        dotnet publish "$SOURCE_PATH\Horker.Data\Horker.Data.csproj" -f net10.0 -c $configuration -r win-x64 --self-contained false -o "$modulePath\lib\net10.0" -nologo -v minimal
        if ($LASTEXITCODE -ne 0) { throw "Publishing $configuration failed." }
        $desktopPath = "$modulePath\lib\net48"
        New-Item -ItemType Directory -Path "$desktopPath\x64" -Force | Out-Null
        $desktopBuild = "$SOURCE_PATH\Horker.Data\bin\$configuration\net48"
        Copy-Item "$desktopBuild\Horker.Data.*", "$desktopBuild\System.Data.SQLite.dll*" $desktopPath -ErrorAction Stop
        Copy-Item "$desktopBuild\x64\SQLite.Interop.dll" "$desktopPath\x64" -ErrorAction Stop
        Copy-Item "$SCRIPT_PATH\*" $modulePath -ErrorAction Stop
    }
}
task UpdateHelp {
    Update-MarkdownHelp HorkerDataQuery $PSScriptRoot\docs
}
task BuildHelp {
    $outputFolder = "$PSScriptRoot\module\release\HorkerDataQuery\en-US"
    New-ExternalHelp -Path $PSScriptRoot\docs -OutputPath $outputFolder
    Copy-Item $outputFolder\* $PSScriptRoot\module\debug\HorkerDataQuery\en-US\
}

task Test {
    dotnet test "$SOURCE_PATH\dataquery.sln" -c Release --no-build -nologo
    if ($LASTEXITCODE -ne 0) { throw "Unit tests failed." }
    $pesterPath = (Get-Module -ListAvailable Pester | Where-Object Version -ge '5.0' | Sort-Object Version -Descending | Select-Object -First 1).Path
    foreach ($engine in 'powershell.exe', 'pwsh') {
        & $engine -NoProfile -File "$PSScriptRoot\tools\Test-Module.ps1" -ModulePath ($MODULE_PATH -f 'Release') -PesterPath $pesterPath
        if ($LASTEXITCODE -ne 0) { throw "$engine tests failed." }
    }
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
