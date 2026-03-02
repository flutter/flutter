// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../android/gradle_utils.dart' as gradle_utils;
import 'platform.dart';

/// Class containing some message strings that can be produced by Flutter tools.
//
// This allows partial reimplementations of the flutter tool to override
// certain messages.
// TODO(andrewkolos): It is unclear if this is worth keeping. See
// https://github.com/flutter/flutter/issues/125155.
class UserMessages {
  // Messages used in multiple components.
  String get flutterToolBugInstructions =>
      'Please report a bug at https://github.com/flutter/flutter/issues.';

  // Messages used in AndroidValidator
  String androidJavaMinimumVersion(String javaVersion) =>
      'Java version $javaVersion is older than the minimum recommended version of ${gradle_utils.warnJavaMinVersionAndroid}';
  String androidSdkLicenseOnly(String envKey) =>
      'Android SDK contains licenses only.\n'
      'Your first build of an Android application will take longer than usual, '
      'while gradle downloads the missing components. This functionality will '
      'only work if the licenses in the licenses folder in $envKey are valid.\n'
      'If the Android SDK has been installed to another location, set $envKey to that location.\n'
      'You may also want to add it to your PATH environment variable.\n\n'
      'Certain features, such as `flutter emulators` and `flutter devices`, will '
      'not work without the currently missing SDK components.';
  String androidBadSdkDir(String envKey, String homeDir) =>
      '$envKey = $homeDir\n'
      'but Android SDK not found at this location.';
  String androidMissingSdkInstructions(Platform platform) =>
      'Unable to locate Android SDK.\n'
      'Install Android Studio from: https://developer.android.com/studio/index.html\n'
      'On first launch it will assist you in installing the Android SDK components.\n'
      '(or visit ${androidSdkInstallUrl(platform)} for detailed instructions).\n'
      'If the Android SDK has been installed to a custom location, please use\n'
      '`flutter config --android-sdk` to update to that location.\n';
  String androidSdkInstallHelp(Platform platform) =>
      'Try re-installing or updating your Android SDK,\n'
      'visit ${androidSdkInstallUrl(platform)} for detailed instructions.';
  // Also occurs in AndroidLicenseValidator
  String androidStatusInfo(String version) => 'Android SDK version $version';

  // Messages used in AndroidLicenseValidator
  String androidLicensesUnknown(Platform platform) =>
      'Android license status unknown.\n'
      'Run `flutter doctor --android-licenses` to accept the SDK licenses.\n'
      'See ${androidSdkInstallUrl(platform)} for more details.';
  String androidMissingSdkManager(String sdkManagerPath, Platform platform) =>
      'Android sdkmanager tool not found ($sdkManagerPath).\n'
      'Try re-installing or updating your Android SDK,\n'
      'visit ${androidSdkInstallUrl(platform)} for detailed instructions.';
  String androidCannotRunSdkManager(String sdkManagerPath, String error, Platform platform) =>
      'Android sdkmanager tool was found, but failed to run ($sdkManagerPath): "$error".\n'
      'Try re-installing or updating your Android SDK,\n'
      'visit ${androidSdkInstallUrl(platform)} for detailed instructions.';
  String androidSdkBuildToolsOutdated(
    int sdkMinVersion,
    String buildToolsMinVersion,
    Platform platform,
  ) =>
      'Flutter requires Android SDK $sdkMinVersion and the Android BuildTools $buildToolsMinVersion\n'
      'To update the Android SDK visit ${androidSdkInstallUrl(platform)} for detailed instructions.';

  // Messages used in NoAndroidStudioValidator
  String androidStudioInstallation(Platform platform) =>
      'Android Studio not found; download from https://developer.android.com/studio/index.html\n'
      '(or visit ${androidSdkInstallUrl(platform)} for detailed instructions).';

  // Messages used in XcodeValidator
  String get xcodeMissing =>
      'Xcode not installed; this is necessary for iOS and macOS development.\n'
      'Download at https://developer.apple.com/xcode/.';
  String get xcodeIncomplete =>
      'Xcode installation is incomplete; a full installation is necessary for iOS and macOS development.\n'
      'Download at: https://developer.apple.com/xcode/\n'
      'Or install Xcode via the App Store.\n'
      'Once installed, run:\n'
      '  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer\n'
      '  sudo xcodebuild -runFirstLaunch';

  // Messages used in CocoaPodsValidator
  String cocoaPodsVersion(String version) => 'CocoaPods version $version';
  String cocoaPodsMissing(String consequence, String installInstructions) =>
      'CocoaPods not installed.\n'
      '$consequence\n'
      'For installation instructions, $installInstructions';
  String cocoaPodsUnknownVersion(String consequence, String upgradeInstructions) =>
      'Unknown CocoaPods version installed.\n'
      '$consequence\n'
      'To update CocoaPods, $upgradeInstructions';
  String cocoaPodsOutdated(
    String currentVersion,
    String recVersion,
    String consequence,
    String upgradeInstructions,
  ) =>
      'CocoaPods $currentVersion out of date ($recVersion is recommended).\n'
      '$consequence\n'
      'To update CocoaPods, $upgradeInstructions';
  String cocoaPodsBrokenInstall(String consequence, String reinstallInstructions) =>
      'CocoaPods installed but not working.\n'
      '$consequence\n'
      'For re-installation instructions, $reinstallInstructions';

  // Messages used in VisualStudioValidator
  String visualStudioVersion(String name, String version) => '$name version $version';
  String visualStudioLocation(String location) => 'Visual Studio at $location';
  String windows10SdkVersion(String version) => 'Windows 10 SDK version $version';
  String visualStudioMissingComponents(String workload, List<String> components) =>
      'Visual Studio is missing necessary components. Please re-run the '
      'Visual Studio installer for the "$workload" workload, and include these components:\n'
      '  ${components.join('\n  ')}\n'
      '  Windows 10 SDK';
  String get windows10SdkNotFound =>
      'Unable to locate a Windows 10 SDK. If building fails, install the Windows 10 SDK in Visual Studio.';
  String visualStudioMissing(String workload) =>
      'Visual Studio not installed; this is necessary to develop Windows apps.\n'
      'Download at https://visualstudio.microsoft.com/downloads/.\n'
      'Please install the "$workload" workload, including all of its default components';
  String visualStudioTooOld(String minimumVersion, String workload) =>
      'Visual Studio $minimumVersion or later is required.\n'
      'Download at https://visualstudio.microsoft.com/downloads/.\n'
      'Please install the "$workload" workload, including all of its default components';
  String get visualStudioIsPrerelease =>
      'The current Visual Studio installation is a pre-release version. It may not be '
      'supported by Flutter yet.';
  String get visualStudioNotLaunchable =>
      'The current Visual Studio installation is not launchable. Please reinstall Visual Studio.';
  String get visualStudioIsIncomplete =>
      'The current Visual Studio installation is incomplete.\n'
      'Please use Visual Studio Installer to complete the installation or reinstall Visual Studio.';
  String get visualStudioRebootRequired =>
      'Visual Studio requires a reboot of your system to complete installation.';

  // Messages used in LinuxDoctorValidator
  String get clangMissing =>
      'clang++ is required for Linux development.\n'
      'It is likely available from your distribution (e.g.: apt install clang), or '
      'can be downloaded from https://releases.llvm.org/';
  String clangTooOld(String minimumVersion) => 'clang++ $minimumVersion or later is required.';
  String get cmakeMissing =>
      'CMake is required for Linux development.\n'
      'It is likely available from your distribution (e.g.: apt install cmake), or '
      'can be downloaded from https://cmake.org/download/';
  String cmakeTooOld(String minimumVersion) => 'cmake $minimumVersion or later is required.';
  String ninjaVersion(String version) => 'ninja version $version';
  String get ninjaMissing =>
      'ninja is required for Linux development.\n'
      'It is likely available from your distribution (e.g.: apt install ninja-build), or '
      'can be downloaded from https://github.com/ninja-build/ninja/releases';
  String ninjaTooOld(String minimumVersion) => 'ninja $minimumVersion or later is required.';
  String pkgConfigVersion(String version) => 'pkg-config version $version';
  String get pkgConfigMissing =>
      'pkg-config is required for Linux development.\n'
      'It is likely available from your distribution (e.g.: apt install pkg-config), or '
      'can be downloaded from https://www.freedesktop.org/wiki/Software/pkg-config/';
  String pkgConfigTooOld(String minimumVersion) =>
      'pkg-config $minimumVersion or later is required.';
  String get gtkLibrariesMissing =>
      'GTK 3.0 development libraries are required for Linux development.\n'
      'They are likely available from your distribution (e.g.: apt install libgtk-3-dev)';
  String get eglinfoMissing =>
      "Unable to access driver information using 'eglinfo'.\n"
      'It is likely available from your distribution (e.g.: apt install mesa-utils)';

  // Messages used in FlutterCommand
  String flutterElapsedTime(String name, String elapsedTime) =>
      '"flutter $name" took $elapsedTime.';
  String get flutterNoDevelopmentDevice =>
      "Unable to locate a development device; please run 'flutter doctor' "
      'for information about installing additional components.';
  String get flutterNoSupportedDevices => 'No supported devices connected.';
  String flutterMissPlatformProjects(List<String> unsupportedDevicesType) =>
      'If you would like your app to run on ${unsupportedDevicesType.join(' or ')}, consider running `flutter create .` to generate projects for these platforms.';
  String get flutterSpecifyDeviceWithAllOption =>
      'More than one device connected; please specify a device with '
      "the '-d <deviceId>' flag, or use '-d all' to act on all devices.";
  String get flutterSpecifyDevice =>
      'More than one device connected; please specify a device with '
      "the '-d <deviceId>' flag.";
  String get flutterNoPubspec =>
      'Error: No pubspec.yaml file found.\n'
      'This command should be run from the root of your Flutter project.';
  String flutterTargetFileMissing(String path) => 'Target file "$path" not found.';

  // Messages used in FlutterCommandRunner
  String runnerNoRoot(String error) => 'Unable to locate flutter root: $error';
  String runnerWrapColumnInvalid(dynamic value) =>
      'Argument to --wrap-column must be a positive integer. You supplied $value.';
  String runnerWrapColumnParseError(dynamic value) =>
      'Unable to parse argument --wrap-column=$value. Must be a positive integer.';
  String runnerNoEngineSrcDir(String enginePackageName, String engineEnvVar) =>
      'Unable to detect local Flutter engine src directory.\n'
      'Either specify a dependency_override for the $enginePackageName package in your pubspec.yaml and '
      'ensure --package-root is set if necessary, or set the \$$engineEnvVar environment variable, or '
      'use --local-engine-src-path to specify the path to the root of your flutter/engine repository.';

  String androidSdkInstallUrl(Platform platform) {
    const baseUrl = 'https://flutter.dev/to/';
    if (platform.isMacOS) {
      return '${baseUrl}macos-android-setup';
    } else if (platform.isLinux) {
      return '${baseUrl}linux-android-setup';
    } else if (platform.isWindows) {
      return '${baseUrl}windows-android-setup';
    } else {
      return '${baseUrl}android-setup';
    }
  }

  /// Overridable message to be shown when detected from device logs that UIScene migration is
  /// still required.
  String? uiSceneMigrationWarning;
}
