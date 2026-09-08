Describe 'Supported hosts' {
    BeforeAll {
        . (Join-Path (Get-Module HorkerDataQuery).ModuleBase 'Assert-SupportedHost.ps1')
    }

    It 'rejects unsupported runtime combinations before assembly loading' -ForEach @(
        @{ Edition = 'Core'; Version = '7.5'; Is64Bit = $true; Platform = 'Win32NT'; Release = 0; Message = '*7.6.5*' }
        @{ Edition = 'Desktop'; Version = '5.1'; Is64Bit = $true; Platform = 'Win32NT'; Release = 461808; Message = '*.NET Framework 4.8*' }
        @{ Edition = 'Desktop'; Version = '5.1'; Is64Bit = $false; Platform = 'Win32NT'; Release = 528040; Message = '*64-bit*' }
        @{ Edition = 'Core'; Version = '7.6.5'; Is64Bit = $true; Platform = 'Unix'; Release = 0; Message = '*Windows*' }
    ) {
        { Assert-SupportedHost -Edition $Edition -Version $Version -Is64Bit $Is64Bit -Platform $Platform -FrameworkRelease $Release } | Should -Throw $Message
    }

    It 'accepts the minimum supported Desktop and Core environments' {
        { Assert-SupportedHost Desktop 5.1 $true Win32NT 528040 } | Should -Not -Throw
        { Assert-SupportedHost Core 7.6.5 $true Win32NT 0 } | Should -Not -Throw
    }

    It 'does not ship the PowerShell reference assembly or 32-bit SQLite binaries' {
        $root = (Get-Module HorkerDataQuery).ModuleBase
        @(Get-ChildItem $root -Recurse -Filter System.Management.Automation.dll).Count | Should -Be 0
        Test-Path (Join-Path $root 'lib\net48\x86') | Should -BeFalse
        Test-Path (Join-Path $root 'lib\net48\x64\SQLite.Interop.dll') | Should -BeTrue
    }
}
