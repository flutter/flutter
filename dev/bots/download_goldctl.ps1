$url= "https://storage.googleapis.com/chrome-infra/depot_tools.zip"
$zipPath = "C:\Windows\Temp\depot_tools.zip"
$path = "C:\Windows\Temp\depot_tools"
$gclient = "C:\Windows\Temp\depot_tools\gclient.bat"
$cipd = "C:\Windows\Temp\depot_tools\cipd.bat"
$ensureFile = "C:\Windows\Temp\depot_tools\ensure.txt"
$text = "# Ensure File\n$ServiceURL https://chrome-infra-packages.appspot.com\n\n# Skia Gold Client goldctl\nskia/tools/goldctl/${platform} latest"

# Check version for changing the the default encoding
Write-Output "PS Version"
$PSVersionTable.PSVersion
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

(New-Object System.Net.WebClient).DownloadFile($url, $zipPath)
Expand-Archive -LiteralPath $zipPath -DestinationPath $path
#Get-ChildItem
cd $path
Write-Output "Running gclient"
cmd.exe /C "$gclient"
#Get-ChildItem
#Out-File $text -FilePath $ensureFile
$text > $ensureFile
#Get-ChildItem
Write-Output "Running cipd"
cmd.exe /C "$cipd ensure -ensure-file $ensureFile -root $path"
Get-ChildItem
