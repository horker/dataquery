Add-Type -Path $PSScriptRoot\System.Data.SQLite.dll

Import-Module $PSScriptRoot\Horker.Data.dll

Set-Alias idq Invoke-DataQuery

Register-DataConfiguration $PSScriptRoot\sqlite.config
