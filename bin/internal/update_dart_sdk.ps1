# Copyright 2014 The Flutter Authors. All rights reserved.
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
$engineStamp = "$cachePath\engine-dart-sdk.stamp"
$engineVersion = (Get-Content "$flutterRoot\bin\internal\engine.version")

$oldDartSdkPrefix = "dart-sdk.old"

# Make sure that PowerShell has expected version.
$psMajorVersionRequired = 5
$psMajorVersionLocal = $PSVersionTable.PSVersion.Major
if ($psMajorVersionLocal -lt $psMajorVersionRequired) {
    Write-Host "Flutter requires PowerShell $psMajorVersionRequired.0 or newer."
    Write-Host "See https://flutter.dev/docs/get-started/install/windows for more."
    Write-Host "Current version is $psMajorVersionLocal."
    # Use exit code 2 to signal that shared.bat should exit immediately instead of retrying.
    exit 2
}

if ((Test-Path $engineStamp) -and ($engineVersion -eq (Get-Content $engineStamp))) {
    return
}

Write-Host "Downloading Dart SDK from Flutter engine $engineVersion..."
$dartSdkBaseUrl = $Env:FLUTTER_STORAGE_BASE_URL
if (-not $dartSdkBaseUrl) {
    $dartSdkBaseUrl = "https://storage.googleapis.com"
}
$dartZipName = "dart-sdk-windows-x64.zip"
$dartSdkUrl = "$dartSdkBaseUrl/flutter_infra/flutter/$engineVersion/$dartZipName"

if (Test-Path $dartSdkPath) {
    # Move old SDK to a new location instead of deleting it in case it is still in use (e.g. by IntelliJ).
    $oldDartSdkSuffix = 1
    while (Test-Path "$cachePath\$oldDartSdkPrefix$oldDartSdkSuffix") { $oldDartSdkSuffix++ }
    Rename-Item $dartSdkPath "$oldDartSdkPrefix$oldDartSdkSuffix"
}
New-Item $dartSdkPath -force -type directory | Out-Null
$dartSdkZip = "$cachePath\$dartZipName"

Try {
    Import-Module BitsTransfer
    Start-BitsTransfer -Source $dartSdkUrl -Destination $dartSdkZip
}
Catch {
    Write-Host "Downloading the Dart SDK using the BITS service failed, retrying with WebRequest..."
    # Invoke-WebRequest is very slow when the progress bar is visible - a 28
    # second download can become a 33 minute download. Disable it with
    # $ProgressPreference and then restore the original value afterwards.
    # https://github.com/flutter/flutter/issues/37789
    $OriginalProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $dartSdkUrl -OutFile $dartSdkZip
    $ProgressPreference = $OriginalProgressPreference
}

Write-Host "Unzipping Dart SDK..."
If (Get-Command 7z -errorAction SilentlyContinue) {
    # The built-in unzippers are painfully slow. Use 7-Zip, if available.
    & 7z x $dartSdkZip "-o$cachePath" -bd | Out-Null
} ElseIf (Get-Command 7za -errorAction SilentlyContinue) {
    # Use 7-Zip's standalone version 7za.exe, if available.
    & 7za x $dartSdkZip "-o$cachePath" -bd | Out-Null
} ElseIf (Get-Command Expand-Archive -errorAction SilentlyContinue) {
    # Use PowerShell's built-in unzipper, if available (requires PowerShell 5+).
    Expand-Archive $dartSdkZip -DestinationPath $cachePath
} Else {
    # As last resort: fall back to the Windows GUI.
    $shell = New-Object -com shell.application
    $zip = $shell.NameSpace($dartSdkZip)
    foreach($item in $zip.items()) {
        $shell.Namespace($cachePath).copyhere($item)
    }
}

Remove-Item $dartSdkZip
$engineVersion | Out-File $engineStamp -Encoding ASCII

# Try to delete all old SDKs.
Get-ChildItem -Path $cachePath | Where {$_.BaseName.StartsWith($oldDartSdkPrefix)} | Remove-Item -Recurse -ErrorAction SilentlyContinue
