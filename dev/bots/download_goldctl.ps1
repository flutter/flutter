$url= "https://storage.googleapis.com/chrome-infra/depot_tools.zip"
$zipPath = "C:\Windows\Temp\depot_tools.zip"
$path = "C:\Windows\Temp\depot_tools"
$cipd = "C:\Windows\Temp\depot_tools\cipd.bat"
$ensureFile = "C:\Windows\Temp\depot_tools\ensure.txt"
$text = "# Ensure File\n$ServiceURL https://chrome-infra-packages.appspot.com\n\n# Skia Gold Client goldctl\nskia/tools/goldctl/${platform} latest"

(New-Object System.Net.WebClient).DownloadFile($url, $zipPath)
Expand-Archive -LiteralPath $zipPath -DestinationPath $path
Get-ChildItem
cd $path
Get-ChildItem
#Out-File $text -FilePath $ensureFile
$text > $ensureFile
Get-ChildItem
cmd.exe /C "$cipd ensure -ensure-file $ensureFile -root $path"
Get-ChildItem