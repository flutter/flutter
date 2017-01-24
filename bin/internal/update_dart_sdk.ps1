# Copyright 2017 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


# ---------------------------------- NOTE ---------------------------------- #
#
# Please keep the logic in this file consistent with the logic in the
# `update_dart_sdk.sh` script in the same directory to ensure that Flutter
# continues to work across all platforms!
#
# -------------------------------------------------------------------------- #

$ErrorActionPreference = "Stop"

$progName = split-path -parent $MyInvocation.MyCommand.Definition
$flutterRoot = (get-item $progName ).parent.parent.FullName

$dartSdkPath = "$flutterRoot\bin\cache\dart-sdk"
$dartSdkStampPath = "$flutterRoot\bin\cache\dart-sdk.stamp"
$dartSdkVersion = (Get-Content "$flutterRoot\bin\internal\dart-sdk.version")

if ((Test-Path $dartSdkStampPath) -and ($dartSdkVersion -eq (Get-Content $dartSdkStampPath))) {
    return
}

Write-Host "Downloading Dart SDK $dartSdkVersion..."
$dartZipName = "dartsdk-windows-x64-release.zip"
$dartChannel = if ($dartSdkVersion.Contains("-dev.")) {"dev"} else {"stable"}
$dartSdkUrl = "https://storage.googleapis.com/dart-archive/channels/$dartChannel/raw/$dartSdkVersion/sdk/$dartZipName"

if (Test-Path $dartSdkPath) { Remove-Item $dartSdkPath -Recurse }
New-Item $dartSdkPath -force -type directory | Out-Null
$dartSdkZip = "$flutterRoot\bin\cache\dart-sdk.zip"

Start-BitsTransfer -Source $dartSdkUrl -Destination $dartSdkZip
Add-Type -assembly "system.io.compression.filesystem"
[io.compression.zipfile]::ExtractToDirectory($dartSdkZip, "$flutterRoot\bin\cache")
Remove-Item $dartSdkZip
$dartSdkVersion | out-file $dartSdkStampPath
