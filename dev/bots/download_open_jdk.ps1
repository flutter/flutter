New-Item -Path $env:APPDATA\Java -type directory


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
(New-Object System.Net.WebClient).DownloadFile($env:OPEN_JDK_URL, 'openjdk.zip') ;
if ((Get-FileHash openjdk.zip -Algorithm sha256).Hash -ne $env:JAVA_SHA256) {exit 1} ;
Expand-Archive openjdk.zip -DestinationPath $env:APPDATA\Java ;
$env:PATH = '{0}\bin;{1}' -f $env:JAVA_HOME, $env:PATH ;
[Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine) ;
Remove-Item -Path openjdk.zip
