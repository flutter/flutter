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

$progName = Split-Path -parent $MyInvocation.MyCommand.Definition
$flutterRoot = (Get-Item $progName).parent.parent.FullName

$cachePath = "$flutterRoot\bin\cache"
$dartSdkPath = "$cachePath\dart-sdk"
$dartSdkStampPath = "$cachePath\dart-sdk.stamp"
$dartSdkVersion = (Get-Content "$flutterRoot\bin\internal\dart-sdk.version")

$oldDartSdkPrefix = "dart-sdk.old"

if ((Test-Path $dartSdkStampPath) -and ($dartSdkVersion -eq (Get-Content $dartSdkStampPath))) {
    return
}

Write-Host "Downloading Dart SDK $dartSdkVersion..."
$dartZipName = "dartsdk-windows-x64-release.zip"
$dartChannel = if ($dartSdkVersion.Contains("-dev.")) {"dev"} else {"stable"}
$dartSdkUrl = "https://storage.googleapis.com/dart-archive/channels/$dartChannel/raw/$dartSdkVersion/sdk/$dartZipName"

if (Test-Path $dartSdkPath) {
    # Move old SDK to a new location instead of deleting it in case it is still in use (e.g. by IntelliJ).
    $oldDartSdkSuffix = 1
    while (Test-Path "$cachePath\$oldDartSdkPrefix$oldDartSdkSuffix") { $oldDartSdkSuffix++ }
    Rename-Item $dartSdkPath "$oldDartSdkPrefix$oldDartSdkSuffix"
}
New-Item $dartSdkPath -force -type directory | Out-Null
$dartSdkZip = "$cachePath\dart-sdk.zip"

Start-BitsTransfer -Source $dartSdkUrl -Destination $dartSdkZip
Add-Type -assembly "system.io.compression.filesystem"
[io.compression.zipfile]::ExtractToDirectory($dartSdkZip, $cachePath)
Remove-Item $dartSdkZip
$dartSdkVersion | Out-File $dartSdkStampPath -Encoding ASCII

# Try to delete all old SDKs.
Get-ChildItem -Path $cachePath | Where {$_.BaseName.StartsWith($oldDartSdkPrefix)} | Remove-Item -Recurse -ErrorAction SilentlyContinue
