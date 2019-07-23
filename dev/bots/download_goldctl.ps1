$url= "https://storage.googleapis.com/chrome-infra/depot_tools.zip"
$path = "C:\Windows\Temp\depot_tools.zip"

(New-Object System.Net.WebClient).DownloadFile($url, $path)
Expand-Archive -LiteralPath $path -DestinationPath "C:\Windows\Temp\depot_tools"
Get-ChildItem
cd C:\Windows\Temp\depot_tools
Get-ChildItem
cmd.exe /C "C:\Windows\Temp\depot_tools\cipd.bat ensure -ensure-file C:\Windows\Temp\dev\bots\ensure_goldctl.txt -root ."
Get-ChildItem