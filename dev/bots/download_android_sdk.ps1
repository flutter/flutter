New-Item -Path $env:ANDROID_SDK_ROOT -type directory

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
(New-Object System.Net.WebClient).DownloadFile($env:ANDROID_SDK_TOOLS_URL, 'android_sdk_tools.zip') ;
if ((Get-FileHash android_sdk_tools.zip -Algorithm sha256).Hash -ne $env:ANDROID_SDK_TOOLS_SHA256) {exit 1} ;
Expand-Archive android_sdk_tools.zip -DestinationPath $env:ANDROID_SDK_ROOT ;
Remove-Item -Path android_sdk_tools.zip

New-Item -Path $env:ANDROID_SDK_ROOT\licenses -type directory

Set-Content -NoNewline -Path C:\Android\licenses\android-googletv-license "`r`n601085b94cd77f0b54ff86406957099ebe79c4d6"
Set-Content -NoNewline -Path C:\Android\licenses\android-sdk-license "`r`n24333f8a63b6825ea9c5514f83c2829b004d1fee"
Set-Content -NoNewline -Path C:\Android\licenses\android-sdk-preview-license "`r`n84831b9409646a918e30573bab4c9c91346d8abd"
Set-Content -NoNewline -Path C:\Android\licenses\google-gdk-license "`r`n33b6a2b64607f11b759f320ef9dff4ae5c47d97a"
Set-Content -NoNewline -Path C:\Android\licenses\intel-android-extra-license "`r`nd975f751698a77b662f1254ddbeed3901e976f5a"
Set-Content -NoNewline -Path C:\Android\licenses\mips-android-sysimage-license "`r`ne9acab5b5fbb560a72cfaecce8946896ff6aab9d"

$env:ANDROID_SDK_ROOT\tools\bin\\sdkmanager.bat tools
$env:ANDROID_SDK_ROOT\tools\bin\\sdkmanager.bat platform-tools
# $env:ANDROID_SDK_ROOT\tools\bin\\sdkmanager.bat emulator

$env:ANDROID_SDK_ROOT\tools\bin\\sdkmanager.bat \
    platforms`;android-28 \
    build-tools`;28.0.3 \
    platforms`;android-27 \
    build-tools`;27.0.3 \
    extras`;google`;m2repository \
    extras`;android`;m2repository