Add-Type -Path $PSScriptRoot\System.Data.SQLite.dll

Import-Module $PSScriptRoot\Horker.Data.dll

Register-DataConfiguration $PSScriptRoot\sqlite.config
