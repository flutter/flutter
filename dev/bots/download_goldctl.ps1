$url= "https://chrome-infra-packages.appspot.com/p/skia/tools/goldctl/windows-amd64/+/"
$path = "c:\Windows\Temp\goldctl.zip"

(New-Object System.Net.WebClient).DownloadFile($path, $output)
Expand-Archive -LiteralPath "C:\Windows\Temp\goldctl.zip" -DestinationPath "C:\Windows\Temp\goldctl_tool"
