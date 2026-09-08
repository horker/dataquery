$repositoryName = 'LocalPSRepo'
$repository = Get-PSRepository -Name $repositoryName -ErrorAction Stop
$publishDirectory = Get-Item -LiteralPath $repository.PublishLocation -ErrorAction Stop
if ($publishDirectory.PSProvider.Name -ne 'FileSystem' -or -not $publishDirectory.PSIsContainer) {
    throw 'LocalPSRepo PublishLocation must be an existing filesystem directory.'
}

Get-ChildItem -LiteralPath $publishDirectory.FullName -Filter 'HorkerDataQuery.*.nupkg' -File -ErrorAction Stop |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -ErrorAction Stop }

$previousNuGetLanguage = [Environment]::GetEnvironmentVariable('NUGET_CLI_LANGUAGE', 'Process')
try {
    # PowerShellGet parses the English success message from nuget.exe.
    $env:NUGET_CLI_LANGUAGE = 'en-us'
    Publish-Module -Path $PSScriptRoot\..\module\release\HorkerDataQuery -Repository $repositoryName -NuGetApiKey any -Verbose -ErrorAction Stop
}
finally {
    [Environment]::SetEnvironmentVariable('NUGET_CLI_LANGUAGE', $previousNuGetLanguage, 'Process')
}

Install-Module HorkerDataQuery -Force -Repository $repositoryName -ErrorAction Stop
