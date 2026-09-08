task . Compile, Build, ImportDebug, Test

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
        dotnet publish "$SOURCE_PATH\Horker.Data\Horker.Data.csproj" -c $configuration -r win-x64 --self-contained false -o $modulePath -nologo -v minimal
        if ($LASTEXITCODE -ne 0) { throw "Publishing $configuration failed." }
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
    $configuration = New-PesterConfiguration
    $configuration.Run.Path = "$PSScriptRoot\tests"
    $configuration.Run.PassThru = $true
    $configuration.TestRegistry.Enabled = $false
    $result = Invoke-Pester -Configuration $configuration
    if ($result.Result -ne 'Passed') { throw "PowerShell tests failed." }
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
