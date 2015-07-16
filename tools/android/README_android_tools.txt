* How to update Android SDK for Linux/Mac OS X on GCS

1. Run Android SDK Manager and update packages

  $ third_party/android_tools/sdk/tools/android update sdk

2. Choose/Update packages

   The following packages are currently installed:

  - Android SDK Tools 24.3.2
  - Android SDK platform-tools 22 Rev.2
  - Android SDK Build-tools 22.0.1
  - Android 5.1.1 (API 22)
    - SDK Platform 22
  - Extras
    - Android Support Library 22.2
    - Google Play services 25

3. Run upload_android_tools.py -t sdk

  $ tools/android/upload_android_tools.py -t sdk

----------------------------------------------------------------------
* How to update Android NDK for Linux/Mac OS X on GCS

1. Download a new NDK binary (e.g. android-ndk-r10e-linux-x86_64.bin)
2. cd third_party/android_tools

  $ cd third_party/android_tools

3. Remove the old ndk directory

  $ rm -rf ndk

4. Run the new NDK binary file

  $ ./android-ndk-r10e-linux-x86_64.bin

5. Rename the extracted directory to ndk

  $ mv android-ndk-r10e ndk

6. Run upload_android_tools.py -t ndk

  $ cd ../..
  $ tools/android/upload_android_tools.py -t ndk
