# Retrieves the AMUID from a given application name
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Name
)
$foo = get-appxpackage | Where-Object { $_.Name -like $name }
$aumid = $foo.packagefamilyname + "!" + (Get-AppxPackageManifest $foo).package.applications.application.id
Write-Output $aumid
