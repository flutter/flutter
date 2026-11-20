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
$dartSdkLicense = "$cachePath\LICENSE.dart_sdk_archive.md"
$engineStamp = "$cachePath\engine-dart-sdk.stamp"
$engineVersionStamp = "$cachePath\engine.stamp"
$engineFallbackStamp = "$cachePath\engine_fallback.stamp"
$engineVersion = (Get-Content $engineVersionStamp | Out-String).Trim()
$engineRealm = (Get-Content "$flutterRoot\bin\cache\engine.realm" | Out-String).Trim()

$oldDartSdkPrefix = "dart-sdk.old"

# Make sure that PowerShell has expected version.
$psMajorVersionRequired = 5
$psMajorVersionLocal = $PSVersionTable.PSVersion.Major
if ($psMajorVersionLocal -lt $psMajorVersionRequired) {
    Write-Host "Flutter requires PowerShell $psMajorVersionRequired.0 or newer."
    Write-Host "Current version is $psMajorVersionLocal."
    # Use exit code 2 to signal that shared.bat should exit immediately instead of retrying.
    exit 2
}

$installedEngineVersion = if (Test-Path $engineStamp) { (Get-Content $engineStamp | Out-String).Trim() } else { "" }
if ((Test-Path $engineStamp) -and ($engineVersion -eq $installedEngineVersion)) {
    return
}

$dartSdkBaseUrl = $Env:FLUTTER_STORAGE_BASE_URL
if (-not $dartSdkBaseUrl) {
    $dartSdkBaseUrl = "https://storage.googleapis.com"
}
if ($engineRealm) {
    $dartSdkBaseUrl = "$dartSdkBaseUrl/$engineRealm"
}

# It's important to use the native Dart SDK as the default target architecture
# for Flutter Windows builds depend on the Dart executable's architecture.
# FLUTTER_HOST_ARCH can be set as an override to force download for the specified architecture.
# PROCESSOR_ARCHITECTURE is a standard Windows env var indicating host CPU architecture.
$dartZipNameX64 = "dart-sdk-windows-x64.zip"
$dartZipNameArm64 = "dart-sdk-windows-arm64.zip"
function Get-DartZipName($version) {
    if ($env:FLUTTER_HOST_ARCH -eq "arm64") {
        return $dartZipNameArm64
    } elseif ($env:FLUTTER_HOST_ARCH -eq "x64") {
        return $dartZipNameX64
    } elseif ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
        $dartSdkArm64Url = "$dartSdkBaseUrl/flutter_infra_release/flutter/$version/$dartZipNameArm64"
        Try {
            Invoke-WebRequest -Uri $dartSdkArm64Url -UseBasicParsing -Method Head | Out-Null
            return $dartZipNameArm64
        }
        Catch {
            Write-Host "The current channel's Dart SDK does not support Windows Arm64, falling back to Windows x64..."
        }
    }
    return $dartZipNameX64
}

function Download-DartSdk($url, $destination) {
    Try {
        Import-Module BitsTransfer
        $ProgressPreference = 'SilentlyContinue'
        Start-BitsTransfer -Source $url -Destination $destination -ErrorAction Stop
    }
    Catch {
        Write-Host "Downloading the Dart SDK using the BITS service failed, retrying with WebRequest..."
        # Invoke-WebRequest is very slow when the progress bar is visible - a 28
        # second download can become a 33 minute download. Disable it with
        # $ProgressPreference and then restore the original value afterwards.
        # https://github.com/flutter/flutter/issues/37789
        $OriginalProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        Try {
            Invoke-WebRequest -Uri $url -OutFile $destination -ErrorAction Stop
        }
        Finally {
            $ProgressPreference = $OriginalProgressPreference
        }
    }
}

function Write-StampAtomically($path, $value) {
    $tmpPath = "$path.tmp.$PID"
    try {
        Set-Content -Path $tmpPath -Value $value -Encoding Ascii
        Move-Item -Path $tmpPath -Destination $path -Force
    } finally {
        if (Test-Path -Path $tmpPath) {
            Remove-Item -Path $tmpPath -Force -ErrorAction SilentlyContinue
        }
    }
}

$dartZipName = Get-DartZipName $engineVersion
$dartSdkUrl = "$dartSdkBaseUrl/flutter_infra_release/flutter/$engineVersion/$dartZipName"

$dartSdkPathTemp = "$cachePath\dart-sdk.tmp"
if (Test-Path $dartSdkPathTemp) {
    Remove-Item $dartSdkPathTemp -Recurse -Force
}
New-Item $dartSdkPathTemp -force -type directory | Out-Null
$dartSdkZip = "$cachePath\$dartZipName"

$originalEngineVersion = $null
Try {
    Download-DartSdk $dartSdkUrl $dartSdkZip
}
Catch {
    $originalException = $_
    if (Test-Path $dartSdkZip) {
        Remove-Item $dartSdkZip -Force -ErrorAction SilentlyContinue
    }

    $strictEngineVersion = $false
    if ($env:FLUTTER_STRICT_ENGINE_VERSION -match "^(1|true)$") {
        $strictEngineVersion = $true
    } elseif ($env:FLUTTER_STRICT_ENGINE_VERSION -match "^(0|false)$") {
        $strictEngineVersion = $false
    } elseif (-not [string]::IsNullOrEmpty($env:LUCI_CONTEXT)) {
        $strictEngineVersion = $true
    }

    $fallbackEngineVersion = $null
    if ((-not $strictEngineVersion) -and [string]::IsNullOrEmpty($engineRealm) -and [string]::IsNullOrEmpty($env:FLUTTER_PREBUILT_ENGINE_VERSION)) {
        $Env:GIT_DIR = $null
        $Env:GIT_INDEX_FILE = $null
        $Env:GIT_WORK_TREE = $null
        $ErrorActionPreference = "Continue"
        try {
            $trackedEngineVersion = (git -C "$flutterRoot" ls-files bin/internal/engine.version 2>$null | Out-String).Trim()
            if ([string]::IsNullOrEmpty($trackedEngineVersion)) {
                $mergeBase = git -C "$flutterRoot" merge-base HEAD upstream/master 2>$null
                if (-not $mergeBase) {
                    $mergeBase = git -C "$flutterRoot" merge-base HEAD origin/master 2>$null
                }
                if (-not $mergeBase) {
                    $mergeBase = git -C "$flutterRoot" merge-base HEAD upstream/main 2>$null
                }
                if (-not $mergeBase) {
                    $mergeBase = git -C "$flutterRoot" merge-base HEAD origin/main 2>$null
                }
                if ($mergeBase) {
                    $candidateHash = (& "$flutterRoot\bin\internal\content_aware_hash.ps1" $mergeBase 2>$null | Out-String).Trim()
                    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrEmpty($candidateHash)) {
                        $fallbackEngineVersion = $candidateHash
                    }
                }
            }
        } catch {
            # Ignore errors during fallback resolution and fall through to rethrow $originalException.
        } finally {
            $ErrorActionPreference = "Stop"
        }
    }

    if ($fallbackEngineVersion -and ($fallbackEngineVersion -ne $engineVersion)) {
        [Console]::Error.WriteLine("================================================================================")
        [Console]::Error.WriteLine("WARNING: Engine artifacts for $engineVersion are not available.")
        [Console]::Error.WriteLine("This usually happens when you have local engine changes or are on a commit that")
        [Console]::Error.WriteLine("has not finished building on CI yet.")
        [Console]::Error.WriteLine("Falling back to engine artifacts from merge-base ($fallbackEngineVersion).")
        [Console]::Error.WriteLine("Set FLUTTER_STRICT_ENGINE_VERSION=true to fail instead of falling back, or")
        [Console]::Error.WriteLine("delete bin/cache/engine_fallback.stamp to retry downloading $engineVersion.")
        [Console]::Error.WriteLine("================================================================================")
        $originalEngineVersion = $engineVersion
        $engineVersion = $fallbackEngineVersion

        if ((Test-Path $engineStamp) -and ($engineVersion -eq $installedEngineVersion) -and (Test-Path $dartSdkPath)) {
            if (Test-Path $dartSdkPathTemp) {
                Remove-Item $dartSdkPathTemp -Recurse -Force -ErrorAction SilentlyContinue
            }
            Write-StampAtomically $engineFallbackStamp "${originalEngineVersion}:${engineVersion}"
            Write-StampAtomically $engineVersionStamp $engineVersion
            return
        }

        $dartZipName = Get-DartZipName $engineVersion
        $dartSdkUrl = "$dartSdkBaseUrl/flutter_infra_release/flutter/$engineVersion/$dartZipName"
        $dartSdkZip = "$cachePath\$dartZipName"
        [Console]::Error.WriteLine("Downloading Dart SDK from Flutter engine $engineVersion...")
        Try {
            Download-DartSdk $dartSdkUrl $dartSdkZip
        }
        Catch {
            if (Test-Path $dartSdkZip) {
                Remove-Item $dartSdkZip -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path $dartSdkPathTemp) {
                Remove-Item $dartSdkPathTemp -Recurse -Force -ErrorAction SilentlyContinue
            }
            throw
        }
    } else {
        if (Test-Path $dartSdkPathTemp) {
            Remove-Item $dartSdkPathTemp -Recurse -Force -ErrorAction SilentlyContinue
        }
        throw $originalException
    }
}

If (Get-Command 7z -errorAction SilentlyContinue) {
    Write-Host "Expanding downloaded archive with 7z..."
    # The built-in unzippers are painfully slow. Use 7-Zip, if available.
    & 7z x $dartSdkZip "-o$dartSdkPathTemp" -bd | Out-Null
} ElseIf (Get-Command 7za -errorAction SilentlyContinue) {
    Write-Host "Expanding downloaded archive with 7za..."
    # Use 7-Zip's standalone version 7za.exe, if available.
    & 7za x $dartSdkZip "-o$dartSdkPathTemp" -bd | Out-Null
} ElseIf (Get-Command Microsoft.PowerShell.Archive\Expand-Archive -errorAction SilentlyContinue) {
    Write-Host "Expanding downloaded archive with PowerShell..."
    # Use PowerShell's built-in unzipper, if available (requires PowerShell 5+).
    $global:ProgressPreference='SilentlyContinue'
    Microsoft.PowerShell.Archive\Expand-Archive $dartSdkZip -DestinationPath $dartSdkPathTemp
} Else {
    Write-Host "Expanding downloaded archive with Windows..."
    # As last resort: fall back to the Windows GUI.
    $shell = New-Object -com shell.application
    $zip = $shell.NameSpace($dartSdkZip)
    foreach($item in $zip.items()) {
        $shell.Namespace($dartSdkPathTemp).copyhere($item)
    }
}

Remove-Item $dartSdkZip

if (-not (Test-Path "$dartSdkPathTemp\dart-sdk")) {
    Remove-Item $dartSdkPathTemp -Recurse -Force -ErrorAction SilentlyContinue
    Write-Error "Dart SDK extraction failed: '$dartSdkPathTemp\dart-sdk' not found."
    exit 1
}

# Move old SDK to a new location instead of deleting it in case it is still in use (e.g. by IntelliJ).
if ((Test-Path $dartSdkPath) -or (Test-Path $dartSdkLicense)) {
    $oldDartSdkSuffix = 1
    while (Test-Path "$cachePath\$oldDartSdkPrefix$oldDartSdkSuffix") { $oldDartSdkSuffix++ }

    if (Test-Path $dartSdkPath) {
        Rename-Item $dartSdkPath "$oldDartSdkPrefix$oldDartSdkSuffix" -ErrorAction Stop
    }

    if (Test-Path $dartSdkLicense) {
        Rename-Item $dartSdkLicense "$oldDartSdkPrefix$oldDartSdkSuffix.LICENSE.md" -ErrorAction Stop
    }
}

# The unzip might have extracted LICENSE.dart_sdk_archive.md to the temp dir
$tempLicense = "$dartSdkPathTemp\LICENSE.dart_sdk_archive.md"
if (Test-Path $tempLicense) {
    if (Test-Path $dartSdkLicense) {
        Remove-Item $dartSdkLicense -Force -ErrorAction Stop
    }
    Move-Item $tempLicense $dartSdkLicense -ErrorAction Stop
}

# Move the extracted SDK to the final location
try {
    Move-Item "$dartSdkPathTemp\dart-sdk" $dartSdkPath -ErrorAction Stop
} finally {
    Remove-Item $dartSdkPathTemp -Recurse -Force -ErrorAction SilentlyContinue
}
if ($originalEngineVersion) {
    Write-StampAtomically $engineFallbackStamp "${originalEngineVersion}:${engineVersion}"
    Write-StampAtomically $engineVersionStamp $engineVersion
}
Write-StampAtomically $engineStamp $engineVersion

# Try to delete all old SDKs and license files.
Get-ChildItem -Path $cachePath | Where {$_.BaseName.StartsWith($oldDartSdkPrefix)} | Remove-Item -Recurse -ErrorAction SilentlyContinue
