# The following powershell script prepares the VM image
# flutter-engine-windows-server-2016 used by Flutter engine's
# build_windows presubmit tests (see .cirrus.yml).
#
# The exact step of generating the VM image is:
# 1. Create a "Windows Server 2016 Datacenter Core" GCE instance with 50GB disk
# 2. RDP into that GCE instance to run this script with powershell
#    (e.g., `powershell -File prepare_windows_server_2016_core.ps1`)
# 3. Shutdown the instance and take an image of that instance
#
# Note that ` is the escape character in powershell.

# Install visual studio 2017
curl https://aka.ms/vs/15/release/vs_community.exe -o vs_community.exe
./vs_community.exe --passive --wait `
    --add Microsoft.VisualStudio.Workload.NativeCrossPlat `
    --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended

# Install debugger tools
curl https://download.microsoft.com/download/5/C/3/5C3770A3-12B4-4DB4-BAE7-99C624EB32AD/windowssdk/winsdksetup.exe `
    -o winsdksetup.exe
./winsdksetup.exe /features OptionId.WindowsDesktopDebuggers /q

# Download depot tools
curl https://storage.googleapis.com/chrome-infra/depot_tools.zip `
    -o depot_tools.zip
Expand-Archive -LiteralPath depot_tools.zip -DestinationPath c:/depot_tools

# Download git. Although depot_tools has its own git.bat, this is needed for
# Flutter engine's gn to run correctly.
#
# Somehow, curl can't get the MinGit from github. Fortunately, taobo works.
curl https://npm.taobao.org/mirrors/git-for-windows/v2.21.0.windows.1/MinGit-2.21.0-64-bit.zip `
    -o MinGit.zip
Expand-Archive -LiteralPath MinGit.zip -DestinationPath c:/MinGit

# Restarting the terminal (or even the whole VM) is required to let following
# environment variables to take effect.
setx path "c:/depot_tools/;c:/MinGit/cmd;${env:path}"
setx DEPOT_TOOLS_WIN_TOOLCHAIN 0
setx GYP_MSVS_OVERRIDE_PATH "c:/Program Files (x86)/Microsoft Visual Studio/2017/Community"

mkdir c:/flutter/engine
curl https://raw.githubusercontent.com/flutter/engine/master/ci/docker/build/engine_gclient `
    -o c:/flutter/engine/.gclient

# Once the above script finishes successfully, one can make an image of the VM
# for the CI test.
#
# For sanity check, one can also test the VM to make sure that Flutter engine
# can be built in that VM. (The test is optional and our current image is made
# before doing these tests. We only did a reboot before making that image to
# ensure environment variables are loaded. However, Cirrus CI seems to have
# problems reading those environment variables so we ended up setting them in
# ".cirrus.yml" manually.)
#
# To test, first reboot of the terminal (or VM) to ensure that environment
# variables "path", "DEPOT_TOOLS_WIN_TOOLCHAIN", and "GYP_MSVS_OVERRIDE_PATH"
# are set. (Those environment variables are not needed for Cirrus CI as Cirrus
# sets those environment variables by itself.)
#
# After all the environment variables above are loaded correctly, one may test
# build the engine by:
#   cd c:/flutter/engine
#   gclient sync
#   cd src
#   python flutter/tools/gn
#   ninja -C out/host_debug
