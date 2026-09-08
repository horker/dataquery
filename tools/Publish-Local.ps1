if (Test-Path ~\localpsrepo\HorkerDataQuery.*.nupkg) {
    rm ~\localpsrepo\HorkerDataQuery.*.nupkg
}

Publish-Module -path $PSScriptRoot\..\module\release\HorkerDataQuery -Repository LocalPSrepo -NuGetApiKey any -vb -ErrorAction Stop
Install-Module HorkerDataQuery -force -Repository LocalPSRepo
