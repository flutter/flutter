FROM cirrusci/windowsservercore:2019

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV JAVA_VERSION jdku202-b08
ENV JAVA_ZIP_VERSION OpenJDK8U-jdk_x64_windows_hotspot_8u202b08.zip
ENV JAVA_SHA256 2637dab3bc81274e19991eebc27684276b482dd71d0f84fedf703d4fba3576e5

ENV JAVA_HOME C:\\${JAVA_VERSION}

ENV ANDROID_HOME C:\\Android
# comes from https://developer.android.com/studio/
ENV ANDROID_SDK_TOOLS_VERSION 4333796
ENV ANDROID_SDK_TOOLS_SHA256 7e81d69c303e47a4f0e748a6352d85cd0c8fd90a5a95ae4e076b5e5f960d3c7a


RUN (New-Object System.Net.WebClient).DownloadFile(('https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/{0}/{1}' -f $env:JAVA_VERSION, $env:JAVA_ZIP_VERSION), 'openjdk.zip') ; \
    if ((Get-FileHash openjdk.zip -Algorithm sha256).Hash -ne $env:JAVA_SHA256) {exit 1} ; \
    Expand-Archive openjdk.zip -DestinationPath C:\ ; \
    $env:PATH = '{0}\bin;{1}' -f $env:JAVA_HOME, $env:PATH ; \
    [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine) ; \
    Remove-Item -Path openjdk.zip

RUN (New-Object System.Net.WebClient).DownloadFile(('https://dl.google.com/android/repository/sdk-tools-windows-{0}.zip' -f $env:ANDROID_SDK_TOOLS_VERSION), 'android_sdk_tools.zip') ; \
    if ((Get-FileHash android_sdk_tools.zip -Algorithm sha256).Hash -ne $env:ANDROID_SDK_TOOLS_SHA256) {exit 1} ; \
    Expand-Archive android_sd_tools.zip -DestinationPath C:\ ; \
    Remove-Item -Path android_sdk_tools.zip

ENV PATH ${PATH}:${ANDROID_HOME}\\tools:${ANDROID_HOME}\\tools\\bin:${ANDROID_HOME}\\platform-tools

RUN echo y | sdkmanager --licenses

RUN sdkmanager tools
RUN sdkmanager platform-tools
RUN sdkmanager emulator

RUN echo y | sdkmanager \
    "platforms;android-28" \
    "build-tools;28.0.3" \
    "platforms;android-27" \
    "build-tools;27.0.3" \
    "extras;google;m2repository" \
    "extras;android;m2repository"
