# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

$url= "https://storage.googleapis.com/chrome-infra/depot_tools.zip"
$zipPath = "C:\Windows\Temp\depot_tools.zip"
$path = "C:\Windows\Temp\depot_tools"
$gclient = "C:\Windows\Temp\depot_tools\gclient.bat"
$cipd = "C:\Windows\Temp\depot_tools\cipd.bat"
$ensureFile = "C:\Windows\Temp\depot_tools\ensure.txt"
$text = "# Ensure File`n`$ServiceURL https://chrome-infra-packages.appspot.com`n`n# Skia Gold Client goldctl`nskia/tools/goldctl/`${platform} git_revision:b57f561ad4ad624bd399b8b7b500aa1955276d41"

(New-Object System.Net.WebClient).DownloadFile($url, $zipPath)
Expand-Archive -LiteralPath $zipPath -DestinationPath $path
cd $path
cmd.exe /C "$gclient"
$text | Out-File -filePath $ensureFile -encoding ascii
cmd.exe /C "$cipd ensure -ensure-file $ensureFile -root $path"
