$url= "https://storage.googleapis.com/chrome-infra/depot_tools.zip"
$zipPath = "C:\Windows\Temp\flutter sdk\depot_tools.zip"
$path = "C:\Windows\Temp\flutter sdk\depot_tools"
$cipd = "C:\Windows\Temp\flutter sdk\depot_tools\cipd.bat"
$ensureFile = "C:\Windows\Temp\flutter sdk\dev\bots\ensure_goldctl.txt"


(New-Object System.Net.WebClient).DownloadFile($url, $zipPath)
Expand-Archive -LiteralPath $zipPath -DestinationPath $path
Get-ChildItem
cd $path
Get-ChildItem
cmd.exe /C "$cipd ensure -ensure-file $ensureFile -root $path"
Get-ChildItem