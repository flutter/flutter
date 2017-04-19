# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# How to use this script:
#  - Allow the execution of PowerShell scripts (ByPass, etc.), for example:
#     Set-ExecutionPolicy Unrestricted
#  - Download the latest Dart SDK into cache folder: UpdateDartSdk.ps1

# This function unzip a zip file without any external depandencies
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

# Get the flutter root directory
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$flutterRoot = (get-item $scriptPath ).parent.parent.FullName
$flutterBinCache = $flutterRoot + '\bin\cache\'
$dartSdkPath = $flutterRoot + '\bin\cache\dart-sdk'
$dartSdkStampPath = $flutterRoot + '\bin\cache\dart-sdk.stamp'
$dartSdkVersionPath = $flutterRoot + '\bin\cache\dart-sdk.version'
$dartSdkVersion = Get-Content $dartSdkVersionPath

if ( (-not (Test-Path $dartSdkStampPath)) -Or ($dartSdkVersion -ne $(Get-Content $dartSdkVersionPath))) {
	Write-Host "Downloading Dart SDK $dartSdkVersion..."
	if ([System.IntPtr]::Size -eq 4) {
		$dartZipName = "dartsdk-windows-ia32-release.zip"
	} else {
		$dartZipName = "dartsdk-windows-x64-release.zip"
	}
	$dartZipName = "dartsdk-windows-x64-release.zip"
	$dartChannel = "stable"
	if ($dartSdkVersion -like '*-dev.*') {
		$dartChannel = "dev"
	}
	$dartSdkUrl = "https://storage.googleapis.com/dart-archive/channels/$dartChannel/raw/$dartSdkVersion/sdk/$dartZipName"
	
	$dartZipPath = "$flutterRoot\bin\cache\$dartZipName"
    $request = [System.Net.WebRequest]::Create($dartSdkUrl)
	try {
		$response = $request.GetResponse()
		$totalLength = [System.Math]::Floor($response.get_ContentLength()/1024) 
		$responseStream = $response.GetResponseStream() 
		$targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $dartZipPath, Create
		$buffer = new-object byte[] 100KB
		$count = $responseStream.Read($buffer, 0, $buffer.length)
		$downloadedBytes = $count
		while ($count -gt 0)
		{ 
			$targetStream.Write($buffer, 0, $count) 
			$count = $responseStream.Read($buffer,0,$buffer.length) 
			$downloadedBytes = $downloadedBytes + $count 
			Write-Progress -activity "Downloading file $dartZipName" -status "Downloaded ($([System.Math]::Floor($downloadedBytes/1024))K of $($totalLength)K): " -PercentComplete ((([System.Math]::Floor($downloadedBytes/1024)) / $totalLength)  * 100)
		} 
		$targetStream.Flush()
		$targetStream.Close() 
		$targetStream.Dispose() 
		$responseStream.Dispose()
	}
	catch [System.Net.WebException] {
		$request = $_.Exception.Response
		if ($request.StatusCode -eq $Null) {
			Write-Host "unreachable host"
		} else {
			Write-Host "We got an unexpected response ( $($request.StatusCode) ). Please check your proxy settings."
		}
		exit
	}
	catch {
		Write-Error $_.Exception
		exit
	}
	#Unzip the dart SDK and remove temporary files
	if (Test-Path $dartSdkPath) {
		Remove-Item -Recurse -Force $dartSdkPath
	}
	Unzip $dartZipPath $flutterBinCache
	$dartSdkVersion >> $dartSdkStampPath
}
