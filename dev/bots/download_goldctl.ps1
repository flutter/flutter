$url= "https://storage.googleapis.com/chrome-infra/depot_tools.zip"
#"https://chrome-infra-packages.appspot.com/p/skia/tools/goldctl/windows-amd64/+/"
$path = "C:\Windows\Temp\flutter sdk\depot_tools.zip"
#"c:\Windows\Temp\flutter sdk\goldctl.zip"

(New-Object System.Net.WebClient).DownloadFile($url, $path)
Expand-Archive -LiteralPath $path -DestinationPath "C:\Windows\Temp\flutter sdk\depot_tools"
Get-ChildItem
cd C:\Windows\Temp\flutter sdk\depot_tools
Get-ChildItem
cmd.exe /C "C:\Windows\Temp\flutter sdk\depot_tools\cipd.bat ensure -ensure-file C:\Windows\Temp\flutter sdk\dev\bots\ensure_goldctl.txt -root ."
Get-ChildItem