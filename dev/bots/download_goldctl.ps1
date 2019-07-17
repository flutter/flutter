$url= "https://chrome-infra-packages.appspot.com/p/skia/tools/goldctl/windows-amd64/+/"
$path = "c:\Windows\Temp\flutter sdk\goldctl.zip"

Write-Output "ls:"
Get-ChildItem
Write-Output "pwd:"
Get-Location
(New-Object System.Net.WebClient).DownloadFile($url, $path)
Write-Output "File Downloaded"
Write-Output "ls:"
Get-ChildItem
Write-Output "pwd:"
Get-Location
Expand-Archive -LiteralPath $path -DestinationPath "C:\Windows\Temp\goldctl_tool"
