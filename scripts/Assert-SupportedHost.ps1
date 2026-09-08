function Assert-SupportedHost {
    param(
        [string]$Edition,
        [version]$Version,
        [bool]$Is64Bit,
        [string]$Platform,
        [int]$FrameworkRelease
    )
    if (-not $Is64Bit -or $Platform -ne 'Win32NT') {
        throw 'HorkerDataQuery requires 64-bit PowerShell on Windows.'
    }
    if ($Edition -eq 'Core') {
        if ($Version -lt [version]'7.6.5') { throw 'HorkerDataQuery requires PowerShell 7.6.5 or later on Core.' }
    }
    elseif ($Edition -eq 'Desktop') {
        if ($Version -lt [version]'5.1') { throw 'HorkerDataQuery requires Windows PowerShell 5.1.' }
        if ($FrameworkRelease -lt 528040) { throw 'HorkerDataQuery requires .NET Framework 4.8 or later.' }
    }
    else { throw "Unsupported PowerShell edition: $Edition" }
}
