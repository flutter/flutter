$url= "https://chrome-infra-packages.appspot.com/p/skia/tools/goldctl/windows-amd64/+/"
$path = "c:\Windows\Temp\flutter sdk\goldctl.zip"

(New-Object System.Net.WebClient).DownloadFile($url, $path)
Expand-Archive -LiteralPath $path -DestinationPath "C:\Windows\Temp\goldctl_tool"
