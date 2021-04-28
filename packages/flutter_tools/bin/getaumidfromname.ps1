# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Retrieves the AMUID from a given application name
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Name
)
$foo = get-appxpackage | Where-Object { $_.Name -like $name }
$aumid = $foo.packagefamilyname + "!" + (Get-AppxPackageManifest $foo).package.applications.application.id
Write-Output $aumid
