$url= "https://chrome-infra-packages.appspot.com/p/skia/tools/goldctl/windows-amd64/+/"
$path = "c:\Windows\Temp\goldctl.zip"

Write-Output "ls:"
Get-ChildItem
Write-Output "pwd:"
Get-Location
(New-Object System.Net.WebClient).DownloadFile($url, $path)
Write-Output "File Downloaded"
Expand-Archive -LiteralPath $path -DestinationPath "C:\Windows\Temp\goldctl_tool"
