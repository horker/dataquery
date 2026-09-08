$apiKey = keystore.exe get NUGET_API_KEY
Publish-Module -Path $PSScriptRoot\..\module\release\HorkerDataQuery -NugetApiKey $apikey -Verbose
