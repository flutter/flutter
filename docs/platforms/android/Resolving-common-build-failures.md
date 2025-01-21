# Why does my build fail?

Flutter utilizes native build systems on Android and iOS.
As these systems evolve and introduce additional features on their own pace, developers sometimes need to re-adjust the configuration to prevent build failures.

This page collects such errors and the standard procedure to work around them.

## Android

Android builds are handled by the Gradle tool, which is configured using .gradle files.
Android Apps themselves are packaged, compiled & optimized by a variety of tools - all being orchestrated by the Android Gradle Plugin (AGP).

Usually, Android Studio and AGP are aligned in their versions. Android Studio also contains a few assistants to smoothen the upgrade process for existing projects.

### Quick Fix (suitable for most build errors)

- Open Android Studio
- Use the File Menu, then "Check for Updates" & retrieve the latest version if necessary
- After the upgrade, use the File Menu and open the "android/build.gradle" or "example/android/build.gradle" file directly. Android Studio will then import the Android portion of the project and will offer you to upgrade the Gradle plugin and the Gradle wrapper
- If you develop a plugin, you need to manually check `android/build.gradle` and `example/android/build.gradle` afterwards and ensure they are referring to the same AGP version

### Minimum supported Gradle version is 5.4.1. Current version is 4.10.2.

In this example, the Gradle plugin upgrade was stopped mid-way and the build can not continue.

To fix it, open `android/gradle/wrapper/gradle-wrapper.properties` (`example/android/gradle/wrapper/gradle-wrapper.properties` if you develop a plugin) and replace the version in there with the required version.

### The Android Gradle plugin only supports Kotlin Gradle Plugin 1.3.10 or higher

With the steps above, only AGP and the wrapper got upgraded. The Kotlin compiler infrastructure is a secondary dependency which is also dependent on certain AGP/Gradle versions.
To resolve it:
 - Scan your build.gradle files for a placeholder like `ext.kotlin_version = '1.2.71'` and replace it with the latest Kotlin version (or the version named in the error message).
  - Android Studio can recommend the latest version, if you open the build.gradle file in it
 - New Kotlin versions introduce language & syntax optimizations; it is therefore recommended to use Android Studio again and open the native part of the App (see above) and let it run a full compilation, including a clean operation. Android Studio will report build failures and suggestions to optimize your code.

### Gradle task assembleDebug failed with exit code 1

If `assembleDebug` or `assembleRelease` failed but no error message can be seen, you are likely on an older Flutter version (`<= 1.9.1.hotfix4`) which may suppress the root cause of the error.

This problem can be solved in two ways:
 - Please try a more recent channel, like `beta` or `dev` and restart the compilation. It may still fail, but the error will now be printed
 - Open the `$FLUTTER_ROOT/packages/flutter_tools/gradle/flutter.gradle` file in your local installation and comment the line which reads `gradle.useLogger(new FlutterEventLogger())`, then retry your build