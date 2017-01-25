# Copyright 2017 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


# ---------------------------------- NOTE ---------------------------------- #
#
# Please keep the logic in this file consistent with the logic in the
# `flutter` script in the same directory to ensure that Flutter continues to
# work across all platforms!
#
# -------------------------------------------------------------------------- #

$ErrorActionPreference = "Stop"

$progName = split-path -parent $MyInvocation.MyCommand.Definition
$flutterRoot = (get-item $progName ).parent.FullName
$env:FLUTTER_ROOT = $flutterRoot

$flutterToolsDir =  "$flutterRoot\packages\flutter_tools"
$snapshotPath = "$flutterRoot\bin\cache\flutter_tools.snapshot"
$stampPath = "$flutterRoot\bin\cache\flutter_tools.stamp"
$scriptPath = "$flutterToolsDir\bin\flutter_tools.dart"
$dartSdkPath = "$flutterRoot\bin\cache\dart-sdk"

$dart = "$dartSdkPath\bin\dart.exe"
$pub = "$dartSdkPath\bin\pub.bat"

# Test if Git is available on the Host
if ((Get-Command "git.exe" -ErrorAction SilentlyContinue) -eq $null) { 
   Write-Host "Error: Unable to find git.exe in your PATH."
   exit
}
# Test if the flutter directory is a git clone (otherwise git rev-parse HEAD would fail)
if (-not (Test-Path "$flutterRoot\.git")) {
   Write-Host "Error: The Flutter directory is not a clone of the GitHub project."
   exit
}

Push-Location
Set-Location $flutterRoot
$revision = Invoke-Expression "git rev-parse HEAD"
Pop-Location

if (!(Test-Path $snapshotPath) `
        -or !(Test-Path $stampPath) `
        -or ((Get-Content $stampPath) -ne  $revision) `
        -or !(Test-Path "$flutterToolsDir\pubspec.lock") `
        -or ((ls "$flutterToolsDir\pubspec.lock").LastWriteTime -lt (ls "$flutterToolsDir\pubspec.yaml").LastWriteTime)) {
    New-Item "$flutterRoot\bin\cache" -force -type directory | Out-Null
    New-Item "$flutterRoot\bin\cache\.dartignore" -force -type file | Out-Null
    Invoke-Expression "$flutterRoot\bin\internal\update_dart_sdk.ps1"

    Write-Host "Building flutter tool..."
    Set-Location $flutterToolsDir
    if (Test-Path "$flutterToolsDir\pubspec.lock") { Remove-Item "$flutterToolsDir\pubspec.lock" }
    Invoke-Expression "$pub get --verbosity=error --no-packages-dir" 
    Set-Location $flutterRoot
    Invoke-Expression "$dart --snapshot=`"$snapshotPath`" `"$scriptPath`" --packages=`"$flutterToolsDir\.packages`""
    $revision | Out-File  $stampPath
}

# Switch PowerShell to UTF8 encoding for Dart.
$encoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Invoke-Expression "$dart `"$snapshotPath`" $args"

# The VM exits with code 253 if the snapshot version is out-of-date.
if ($LASTEXITCODE -eq 253) {
    Invoke-Expression "$dart --snapshot=`"$snapshotPath`" `"$scriptPath`" --packages=`"$flutterToolsDir\.packages`""
    Invoke-Expression "$dart `"$snapshotPath`" $args"
}

# Reset PowerShell to whatever the user's encoding was.
[Console]::OutputEncoding = $encoding
