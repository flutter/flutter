# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# How to use this script:
#  - Allow the execution of PowerShell scripts (ByPass, etc.), for example:
#     Set-ExecutionPolicy Unrestricted
#  - Invoke any flutter command: Flutter.ps1 doctor
#  - Force the path to Dart SDK: Flutter.ps1 -DartPath "c:\tools\dart\"

[CmdletBinding()]
param (
  [Parameter(Mandatory=$False)]
  [string]$DartPath,
  [Parameter(Mandatory=$False)]
  [switch]$Diag,
  [parameter(mandatory=$False, position=1, ValueFromRemainingArguments=$true)]
  $Remaining
)

# This function creates a snapshot of the latest version of flutter framework
function Do-Snapshot
{
	Set-Location $flutterToolsDir
	Write-Host "Info: Updating flutter tool..."
	Invoke-Expression "pub.bat get $(&{If($Diag) {"--verbose"}})" 
	Set-Location $flutterDir
	# Allows us to check if sky_engine's REVISION is correct
	Write-Host "Info: Updating sky engine..."
	Invoke-Expression "pub.bat get $(&{If($Diag) {"--verbose"}})"
	Set-Location $flutterRoot
	Invoke-Expression "$dartExe --snapshot=`"$snapshotPath`" `"$scriptPath`" --packages=`"$flutterToolsDir\.packages`""
	$revision | Out-File  $stampPath
}

# Save the current location
Push-Location

# Get the parent directory
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$flutterRoot = (get-item $scriptPath ).parent.FullName

$flutterToolsDir = $flutterRoot + '\packages\flutter_tools'
$flutterDir = $flutterRoot + '\packages\flutter'
$snapshotPath = $flutterRoot + '\bin\cache\flutter_tools.snapshot'
$stampPath = $flutterRoot + '\bin\cache\flutter_tools.stamp'
$scriptPath = $flutterToolsDir + '\bin\flutter_tools.dart'
$dartExe = [io.path]::combine($DartPath, 'dart.exe')

# Set current working directory to the flutter directory
Set-Location $flutterRoot

# Test if Git is available on the Host
if ((Get-Command "git.exe" -ErrorAction SilentlyContinue) -eq $null) { 
   Write-Host "Error: Unable to find git.exe in your PATH"
   Pop-Location
   exit
}
# Test if the flutter directory is a git clone (otherwise git rev-parse HEAD would fail)
if (-not (Test-Path '.git')) {
   Write-Host "Error: The flutter directory is not a clone of the GH project"
   Pop-Location
   exit
}
# Test if pub.bat is available on the Host
if ((Get-Command "pub.bat" -ErrorAction SilentlyContinue) -eq $null) { 
   Write-Host "Error: Unable to find Dart SDK in your PATH"
   Pop-Location
   exit
}

# Check if the snapshot version is out-of-date.
$revision = Invoke-Expression "git rev-parse HEAD"
if ( (-not (Test-Path $snapshotPath)) -Or (-not (Test-Path $stampPath)) ) {
	Write-Host "Info: Snapshot doesn't exist"
	Do-Snapshot
}
$stampValue = Get-Content $stampPath | Where-Object {$_ -match '\S'}
if ($stampValue -ne $revision) {
	Write-Host "Info: Timestamp differs from revision"
	Do-Snapshot
}
$yamltLastWriteTime = (ls "$flutterToolsDir\pubspec.yaml").LastWriteTime
$locktLastWriteTime = (ls "$flutterToolsDir\pubspec.lock").LastWriteTime
if ($locktLastWriteTime -lt $yamltLastWriteTime) {
	Write-Host "Info: Mismatch between yaml and lock files"
	Do-Snapshot
}

# Go back to last working directory
Pop-Location
Invoke-Expression "$dartExe `"$snapshotPath`" $Remaining"

# The VM exits with code 253 if the snapshot version is out-of-date.
if ($LASTEXITCODE -eq 253) {
	Write-Host "Info: VM exited with code 253, we need to snapshot it again."
	Invoke-Expression "$dartExe --snapshot=`"$snapshotPath`" `"$scriptPath`" --packages=`"$flutterToolsDir\.packages`""
	Invoke-Expression "$dartExe `"$snapshotPath`" $Remaining"
}
