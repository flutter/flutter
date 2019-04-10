// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'context.dart';

UserMessages get userMessages => context[UserMessages];

/// Class containing message strings that can be produced by Flutter tools.
class UserMessages {
  // Messages used in FlutterValidator
  String flutterStatusInfo(String channel, String version, String os, String locale) =>
      'Channel $channel, v$version, on $os, locale $locale';
  String flutterVersion(String version, String flutterRoot) =>
      'Flutter version $version at $flutterRoot';
  String flutterRevision(String revision, String age, String date) =>
      'Framework revision $revision ($age), $date';
  String engineRevision(String revision) => 'Engine revision $revision';
  String dartRevision(String revision) => 'Dart version $revision';
  String get flutterBinariesDoNotRun =>
      'Downloaded executables cannot execute on host.\n'
      'See https://github.com/flutter/flutter/issues/6207 for more information';
  String get flutterBinariesLinuxRepairCommands =>
      'On Debian/Ubuntu/Mint: sudo apt-get install lib32stdc++6\n'
      'On Fedora: dnf install libstdc++.i686\n'
      'On Arch: pacman -S lib32-gcc-libs';

  // Messages used in NoIdeValidator
  String get noIdeStatusInfo => 'No supported IDEs installed';
  String get noIdeInstallationInfo => 'IntelliJ - https://www.jetbrains.com/idea/';

  // Messages used in IntellijValidator
  String intellijStatusInfo(String version) => 'version $version';
  String get intellijPluginInfo =>
      'For information about installing plugins, see\n'
      'https://flutter.dev/intellij-setup/#installing-the-plugins';
  String intellijMinimumVersion(String minVersion) =>
      'This install is older than the minimum recommended version of $minVersion.';
  String intellijLocation(String installPath) => 'IntelliJ at $installPath';

  // Message used in IntellijValidatorOnMac
  String get intellijMacUnknownResult => 'Cannot determine if IntelliJ is installed';

  // Messages used in DeviceValidator
  String get devicesMissing => 'No devices available';
  String devicesAvailable(int devices) => '$devices available';

  // Messages used in AndroidValidator
  String androidCantRunJavaBinary(String javaBinary) => 'Cannot execute $javaBinary to determine the version';
  String get androidUnknownJavaVersion => 'Could not determine java version';
  String androidJavaVersion(String javaVersion) => 'Java version $javaVersion';
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
  String androidMissingSdkInstructions(String envKey) =>
      'Unable to locate Android SDK.\n'
      'Install Android Studio from: https://developer.android.com/studio/index.html\n'
      'On first launch it will assist you in installing the Android SDK components.\n'
      '(or visit https://flutter.dev/setup/#android-setup for detailed instructions).\n'
      'If the Android SDK has been installed to a custom location, set $envKey to that location.\n'
      'You may also want to add it to your PATH environment variable.\n';
  String androidSdkLocation(String directory) => 'Android SDK at $directory';
  String androidSdkPlatformToolsVersion(String platform, String tools) =>
      'Platform $platform, build-tools $tools';
  String get androidSdkInstallHelp =>
      'Try re-installing or updating your Android SDK,\n'
      'visit https://flutter.dev/setup/#android-setup for detailed instructions.';
  String get androidMissingNdk => 'Android NDK location not configured (optional; useful for native profiling support)';
  String androidNdkLocation(String directory) => 'Android NDK at $directory';
  // Also occurs in AndroidLicenseValidator
  String androidStatusInfo(String version) => 'Android SDK version $version';

  // Messages used in AndroidLicenseValidator
  String get androidMissingJdk =>
      'No Java Development Kit (JDK) found; You must have the environment '
      'variable JAVA_HOME set and the java binary in your PATH. '
      'You can download the JDK from https://www.oracle.com/technetwork/java/javase/downloads/.';
  String androidJdkLocation(String location) => 'Java binary at: $location';
  String get androidLicensesAll => 'All Android licenses accepted.';
  String get androidLicensesSome => 'Some Android licenses not accepted.  To resolve this, run: flutter doctor --android-licenses';
  String get androidLicensesNone => 'Android licenses not accepted.  To resolve this, run: flutter doctor --android-licenses';
  String get androidLicensesUnknown =>
      'Android license status unknown.\n'
      'Try re-installing or updating your Android SDK Manager.\n'
      'See https://developer.android.com/studio/#downloads or visit '
      'https://flutter.dev/setup/#android-setup for detailed instructions.';
  String androidSdkManagerOutdated(String managerPath) =>
      'A newer version of the Android SDK is required. To update, run:\n'
      '$managerPath --update\n';
  String androidLicensesTimeout(String managerPath) => 'Intentionally killing $managerPath';
  String get androidSdkShort => 'Unable to locate Android SDK.';
  String androidMissingSdkManager(String sdkManagerPath) =>
      'Android sdkmanager tool not found ($sdkManagerPath).\n'
      'Try re-installing or updating your Android SDK,\n'
      'visit https://flutter.dev/setup/#android-setup for detailed instructions.';
  String androidSdkBuildToolsOutdated(String managerPath, int sdkMinVersion, String buildToolsMinVersion) =>
      'Flutter requires Android SDK $sdkMinVersion and the Android BuildTools $buildToolsMinVersion\n'
      'To update using sdkmanager, run:\n'
      '  "$managerPath" "platforms;android-$sdkMinVersion" "build-tools;$buildToolsMinVersion"\n'
      'or visit https://flutter.dev/setup/#android-setup for detailed instructions.';

  // Messages used in AndroidStudioValidator
  String androidStudioVersion(String version) => 'version $version';
  String androidStudioLocation(String location) => 'Android Studio at $location';
  String get androidStudioNeedsUpdate => 'Try updating or re-installing Android Studio.';
  String get androidStudioResetDir =>
      'Consider removing your android-studio-dir setting by running:\n'
      'flutter config --android-studio-dir=';
  String get aaptNotFound =>
      'Could not locate aapt. Please ensure you have the Android buildtools installed.';

  // Messages used in NoAndroidStudioValidator
  String androidStudioMissing(String location) =>
      'android-studio-dir = $location\n'
      'but Android Studio not found at this location.';
  String get androidStudioInstallation =>
      'Android Studio not found; download from https://developer.android.com/studio/index.html\n'
      '(or visit https://flutter.dev/setup/#android-setup for detailed instructions).';

  // Messages used in IOSValidator
  String iOSXcodeLocation(String location) => 'Xcode at $location';
  String iOSXcodeOutdated(int versionMajor, int versionMinor) =>
      'Flutter requires a minimum Xcode version of $versionMajor.$versionMinor.0.\n'
      'Download the latest version or update via the Mac App Store.';
  String get iOSXcodeEula => 'Xcode end user license agreement not signed; open Xcode or run the command \'sudo xcodebuild -license\'.';
  String get iOSXcodeMissingSimct =>
      'Xcode requires additional components to be installed in order to run.\n'
      'Launch Xcode and install additional required components when prompted.';
  String get iOSXcodeMissing =>
      'Xcode not installed; this is necessary for iOS development.\n'
      'Download at https://developer.apple.com/xcode/download/.';
  String get iOSXcodeIncomplete =>
      'Xcode installation is incomplete; a full installation is necessary for iOS development.\n'
      'Download at: https://developer.apple.com/xcode/download/\n'
      'Or install Xcode via the App Store.\n'
      'Once installed, run:\n'
      '  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer';
  String get iOSIMobileDeviceMissing =>
      'libimobiledevice and ideviceinstaller are not installed. To install with Brew, run:\n'
      '  brew update\n'
      '  brew install --HEAD usbmuxd\n'
      '  brew link usbmuxd\n'
      '  brew install --HEAD libimobiledevice\n'
      '  brew install ideviceinstaller';
  String get iOSIMobileDeviceBroken =>
      'Verify that all connected devices have been paired with this computer in Xcode.\n'
      'If all devices have been paired, libimobiledevice and ideviceinstaller may require updating.\n'
      'To update with Brew, run:\n'
      '  brew update\n'
      '  brew uninstall --ignore-dependencies libimobiledevice\n'
      '  brew uninstall --ignore-dependencies usbmuxd\n'
      '  brew install --HEAD usbmuxd\n'
      '  brew unlink usbmuxd\n'
      '  brew link usbmuxd\n'
      '  brew install --HEAD libimobiledevice\n'
      '  brew install ideviceinstaller';
  String get iOSDeviceInstallerMissing =>
      'ideviceinstaller is not installed; this is used to discover connected iOS devices.\n'
      'To install with Brew, run:\n'
      '  brew install --HEAD usbmuxd\n'
      '  brew link usbmuxd\n'
      '  brew install --HEAD libimobiledevice\n'
      '  brew install ideviceinstaller';
  String iOSDeployVersion(String version) => 'ios-deploy $version';
  String iOSDeployOutdated(String minVersion) =>
      'ios-deploy out of date ($minVersion is required). To upgrade with Brew:\n'
      '  brew upgrade ios-deploy';
  String get iOSDeployMissing =>
      'ios-deploy not installed. To install:\n'
      '  brew install ios-deploy';
  String get iOSBrewMissing =>
      'Brew can be used to install tools for iOS device development.\n'
      'Download brew at https://brew.sh/.';

  // Messages used in CocoaPodsValidator
  String cocoaPodsVersion(String version) => 'CocoaPods version $version';
  String cocoaPodsUninitialized(String consequence) =>
      'CocoaPods installed but not initialized.\n'
      '$consequence\n'
      'To initialize CocoaPods, run:\n'
      '  pod setup\n'
      'once to finalize CocoaPods\' installation.';
  String cocoaPodsMissing(String consequence, String installInstructions) =>
      'CocoaPods not installed.\n'
      '$consequence\n'
      'To install:\n'
      '$installInstructions';
  String cocoaPodsUnknownVersion(String consequence, String upgradeInstructions) =>
      'Unknown CocoaPods version installed.\n'
      '$consequence\n'
      'To upgrade:\n'
      '$upgradeInstructions';
  String cocoaPodsOutdated(String recVersion, String consequence, String upgradeInstructions) =>
      'CocoaPods out of date ($recVersion is recommended).\n'
      '$consequence\n'
      'To upgrade:\n'
      '$upgradeInstructions';

  // Messages used in VsCodeValidator
  String vsCodeVersion(String version) => 'version $version';
  String vsCodeLocation(String location) => 'VS Code at $location';
  String vsCodeFlutterExtensionMissing(String url) => 'Flutter extension not installed; install from\n$url';

  // Messages used in FlutterCommand
  String flutterElapsedTime(String name, String elapsedTime) => '"flutter $name" took $elapsedTime.';
  String get flutterNoDevelopmentDevice =>
      "Unable to locate a development device; please run 'flutter doctor' "
      'for information about installing additional components.';
  String flutterNoMatchingDevice(String deviceId) => 'No devices found with name or id '
      "matching '$deviceId'";
  String get flutterNoDevicesFound => 'No devices found';
  String get flutterNoSupportedDevices => 'No supported devices connected.';
  String flutterFoundSpecifiedDevices(int count, String deviceId) =>
      'Found $count devices with name or id matching $deviceId:';
  String get flutterSpecifyDeviceWithAllOption =>
      'More than one device connected; please specify a device with '
      "the '-d <deviceId>' flag, or use '-d all' to act on all devices.";
  String get flutterSpecifyDevice =>
      'More than one device connected; please specify a device with '
      "the '-d <deviceId>' flag.";
  String get flutterNoConnectedDevices => 'No connected devices.';
  String get flutterNoPubspec =>
      'Error: No pubspec.yaml file found.\n'
      'This command should be run from the root of your Flutter project.\n'
      'Do not run this command from the root of your git clone of Flutter.';
  String get flutterMergeYamlFiles =>
      'Please merge your flutter.yaml into your pubspec.yaml.\n\n'
      'We have changed from having separate flutter.yaml and pubspec.yaml\n'
      'files to having just one pubspec.yaml file. Transitioning is simple:\n'
      'add a line that just says "flutter:" to your pubspec.yaml file, and\n'
      'move everything from your current flutter.yaml file into the\n'
      'pubspec.yaml file, below that line, with everything indented by two\n'
      'extra spaces compared to how it was in the flutter.yaml file. Then, if\n'
      'you had a "name:" line, move that to the top of your "pubspec.yaml"\n'
      'file (you may already have one there), so that there is only one\n'
      '"name:" line. Finally, delete the flutter.yaml file.\n\n'
      'For an example of what a new-style pubspec.yaml file might look like,\n'
      'check out the Flutter Gallery pubspec.yaml:\n'
      'https://github.com/flutter/flutter/blob/master/examples/flutter_gallery/pubspec.yaml\n';
  String flutterTargetFileMissing(String path) => 'Target file "$path" not found.';
  String get flutterBasePatchFlagsExclusive => 'Error: Only one of --baseline, --patch is allowed.';
  String get flutterBaselineRequiresTraceFile => 'Error: --baseline requires --compilation-trace-file to be specified.';
  String get flutterPatchRequiresTraceFile => 'Error: --patch requires --compilation-trace-file to be specified.';

  // Messages used in FlutterCommandRunner
  String runnerNoRoot(String error) => 'Unable to locate flutter root: $error';
  String runnerWrapColumnInvalid(dynamic value) =>
      'Argument to --wrap-column must be a positive integer. You supplied $value.';
  String runnerWrapColumnParseError(dynamic value) =>
      'Unable to parse argument --wrap-column=$value. Must be a positive integer.';
  String runnerBugReportFinished(String zipFileName) =>
      'Bug report written to $zipFileName.\n'
      'Warning: this bug report contains local paths, device identifiers, and log snippets.';
  String get runnerNoRecordTo => 'record-to location not specified';
  String get runnerNoReplayFrom => 'replay-from location not specified';
  String runnerNoEngineSrcDir(String enginePackageName, String engineEnvVar) =>
      'Unable to detect local Flutter engine src directory.\n'
      'Either specify a dependency_override for the $enginePackageName package in your pubspec.yaml and '
      'ensure --package-root is set if necessary, or set the \$$engineEnvVar environment variable, or '
      'use --local-engine-src-path to specify the path to the root of your flutter/engine repository.';
  String runnerNoEngineBuildDirInPath(String engineSourcePath) =>
      'Unable to detect a Flutter engine build directory in $engineSourcePath.\n'
      'Please ensure that $engineSourcePath is a Flutter engine \'src\' directory and that '
      'you have compiled the engine in that directory, which should produce an \'out\' directory';
  String get runnerLocalEngineRequired =>
      'You must specify --local-engine if you are using a locally built engine.';
  String runnerNoEngineBuild(String engineBuildPath) =>
      'No Flutter engine build found at $engineBuildPath.';
  String runnerWrongFlutterInstance(String flutterRoot, String currentDir) =>
      'Warning: the \'flutter\' tool you are currently running is not the one from the current directory:\n'
      '  running Flutter  : $flutterRoot\n'
      '  current directory: $currentDir\n'
      'This can happen when you have multiple copies of flutter installed. Please check your system path to verify '
      'that you\'re running the expected version (run \'flutter --version\' to see which flutter is on your path).\n';
  String runnerRemovedFlutterRepo(String flutterRoot, String flutterPath) =>
      'Warning! This package referenced a Flutter repository via the .packages file that is '
      'no longer available. The repository from which the \'flutter\' tool is currently '
      'executing will be used instead.\n'
      '  running Flutter tool: $flutterRoot\n'
      '  previous reference  : $flutterPath\n'
      'This can happen if you deleted or moved your copy of the Flutter repository, or '
      'if it was on a volume that is no longer mounted or has been mounted at a '
      'different location. Please check your system path to verify that you are running '
      'the expected version (run \'flutter --version\' to see which flutter is on your path).\n';
  String runnerChangedFlutterRepo(String flutterRoot, String flutterPath) =>
      'Warning! The \'flutter\' tool you are currently running is from a different Flutter '
      'repository than the one last used by this package. The repository from which the '
      '\'flutter\' tool is currently executing will be used instead.\n'
      '  running Flutter tool: $flutterRoot\n'
      '  previous reference  : $flutterPath\n'
      'This can happen when you have multiple copies of flutter installed. Please check '
      'your system path to verify that you are running the expected version (run '
      '\'flutter --version\' to see which flutter is on your path).\n';
  String invalidVersionSettingHintMessage(String invalidVersion) =>
      'Invalid version $invalidVersion found, default value will be used.\n'
      'In pubspec.yaml, a valid version should look like: build-name+build-number.\n'
      'In Android, build-name is used as versionName while build-number used as versionCode.\n'
      'Read more about Android versioning at https://developer.android.com/studio/publish/versioning\n'
      'In iOS, build-name is used as CFBundleShortVersionString while build-number used as CFBundleVersion.\n'
      'Read more about iOS versioning at\n'
      'https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html\n';
}
