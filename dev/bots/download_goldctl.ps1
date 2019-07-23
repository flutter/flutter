$url= "https://storage.googleapis.com/chrome-infra/depot_tools.zip"
$zipPath = "C:\Windows\Temp\flutter^ sdk\depot_tools.zip"
$path = "C:\Windows\Temp\flutter^ sdk\depot_tools"

(New-Object System.Net.WebClient).DownloadFile($url, $zipPath)
Expand-Archive -LiteralPath $zipPath -DestinationPath $path
Get-ChildItem
cd $path
Get-ChildItem
cmd.exe /C "C:\Windows\Temp\flutter ^ sdk\depot_tools\cipd.bat ensure -ensure-file C:\Windows\Temp\flutter^ sdk\dev\bots\ensure_goldctl.txt -root $path"
Get-ChildItem