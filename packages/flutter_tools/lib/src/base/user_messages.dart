// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'platform.dart';


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
      'Visual Studio not installed; this is necessary for Windows development.\n'
      'Download at https://visualstudio.microsoft.com/downloads/.\n'
      'Please install the "$workload" workload, including all of its default components';
  String visualStudioTooOld(String minimumVersion, String workload) =>
      'Visual Studio $minimumVersion or later is required.\n'
      'Download at https://visualstudio.microsoft.com/downloads/.\n'
      'Please install the "$workload" workload, including all of its default components';
  String get visualStudioIsPrerelease => 'The current Visual Studio installation is a pre-release version. It may not be '
      'supported by Flutter yet.';
  String get visualStudioNotLaunchable =>
      'The current Visual Studio installation is not launchable. Please reinstall Visual Studio.';
  String get visualStudioIsIncomplete => 'The current Visual Studio installation is incomplete. Please reinstall Visual Studio.';
  String get visualStudioRebootRequired => 'Visual Studio requires a reboot of your system to complete installation.';

  // Messages used in LinuxDoctorValidator
  String get clangMissing => 'clang++ is required for Linux development.\n'
      'It is likely available from your distribution (e.g.: apt install clang), or '
      'can be downloaded from https://releases.llvm.org/';
  String clangTooOld(String minimumVersion) => 'clang++ $minimumVersion or later is required.';
  String get cmakeMissing => 'CMake is required for Linux development.\n'
      'It is likely available from your distribution (e.g.: apt install cmake), or '
      'can be downloaded from https://cmake.org/download/';
  String cmakeTooOld(String minimumVersion) => 'cmake $minimumVersion or later is required.';
  String ninjaVersion(String version) => 'ninja version $version';
  String get ninjaMissing => 'ninja is required for Linux development.\n'
      'It is likely available from your distribution (e.g.: apt install ninja-build), or '
      'can be downloaded from https://github.com/ninja-build/ninja/releases';
  String ninjaTooOld(String minimumVersion) => 'ninja $minimumVersion or later is required.';
  String pkgConfigVersion(String version) => 'pkg-config version $version';
  String get pkgConfigMissing => 'pkg-config is required for Linux development.\n'
      'It is likely available from your distribution (e.g.: apt install pkg-config), or '
      'can be downloaded from https://www.freedesktop.org/wiki/Software/pkg-config/';
  String pkgConfigTooOld(String minimumVersion) => 'pkg-config $minimumVersion or later is required.';
  String get gtkLibrariesMissing => 'GTK 3.0 development libraries are required for Linux development.\n'
      'They are likely available from your distribution (e.g.: apt install libgtk-3-dev)';

  // Messages used in FlutterCommand
  String flutterElapsedTime(String name, String elapsedTime) => '"flutter $name" took $elapsedTime.';
  String get flutterNoDevelopmentDevice =>
      "Unable to locate a development device; please run 'flutter doctor' "
      'for information about installing additional components.';
  String flutterNoMatchingDevice(String deviceId) => 'No supported devices found with name or id '
      "matching '$deviceId'.";
  String get flutterNoDevicesFound => 'No devices found.';
  String get flutterNoSupportedDevices => 'No supported devices connected.';
  String flutterMissPlatformProjects(List<String> unsupportedDevicesType) =>
      'If you would like your app to run on ${unsupportedDevicesType.join(' or ')}, consider running `flutter create .` to generate projects for these platforms.';
  String get flutterFoundButUnsupportedDevices => 'The following devices were found, but are not supported by this project:';
  String flutterFoundSpecifiedDevices(int count, String deviceId) =>
      'Found $count devices with name or id matching $deviceId:';
  String flutterChooseDevice(int option, String name, String deviceId) => '[$option]: $name ($deviceId)';
  String get flutterChooseOne => 'Please choose one (or "q" to quit)';
  String get flutterSpecifyDeviceWithAllOption =>
      'More than one device connected; please specify a device with '
      "the '-d <deviceId>' flag, or use '-d all' to act on all devices.";
  String get flutterSpecifyDevice =>
      'More than one device connected; please specify a device with '
      "the '-d <deviceId>' flag.";
  String get flutterNoConnectedDevices => 'No connected devices.';
  String get flutterNoPubspec =>
      'Error: No pubspec.yaml file found.\n'
      'This command should be run from the root of your Flutter project.';
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
      "Please ensure that $engineSourcePath is a Flutter engine 'src' directory and that "
      "you have compiled the engine in that directory, which should produce an 'out' directory";
  String get runnerLocalEngineOrWebSdkRequired =>
      'You must specify --local-engine or --local-web-sdk if you are using a locally built engine or web sdk.';
  String runnerNoEngineBuild(String engineBuildPath) =>
      'No Flutter engine build found at $engineBuildPath.';
  String runnerNoWebSdk(String webSdkPath) =>
      'No Flutter web sdk found at $webSdkPath.';
  String runnerWrongFlutterInstance(String flutterRoot, String currentDir) =>
      "Warning: the 'flutter' tool you are currently running is not the one from the current directory:\n"
      '  running Flutter  : $flutterRoot\n'
      '  current directory: $currentDir\n'
      'This can happen when you have multiple copies of flutter installed. Please check your system path to verify '
      "that you're running the expected version (run 'flutter --version' to see which flutter is on your path).\n";
  String runnerRemovedFlutterRepo(String flutterRoot, String flutterPath) =>
      'Warning! This package referenced a Flutter repository via the .packages file that is '
      "no longer available. The repository from which the 'flutter' tool is currently "
      'executing will be used instead.\n'
      '  running Flutter tool: $flutterRoot\n'
      '  previous reference  : $flutterPath\n'
      'This can happen if you deleted or moved your copy of the Flutter repository, or '
      'if it was on a volume that is no longer mounted or has been mounted at a '
      'different location. Please check your system path to verify that you are running '
      "the expected version (run 'flutter --version' to see which flutter is on your path).\n";
  String runnerChangedFlutterRepo(String flutterRoot, String flutterPath) =>
      "Warning! The 'flutter' tool you are currently running is from a different Flutter "
      'repository than the one last used by this package. The repository from which the '
      "'flutter' tool is currently executing will be used instead.\n"
      '  running Flutter tool: $flutterRoot\n'
      '  previous reference  : $flutterPath\n'
      'This can happen when you have multiple copies of flutter installed. Please check '
      'your system path to verify that you are running the expected version (run '
      "'flutter --version' to see which flutter is on your path).\n";
  String invalidVersionSettingHintMessage(String invalidVersion) =>
      'Invalid version $invalidVersion found, default value will be used.\n'
      'In pubspec.yaml, a valid version should look like: build-name+build-number.\n'
      'In Android, build-name is used as versionName while build-number used as versionCode.\n'
      'Read more about Android versioning at https://developer.android.com/studio/publish/versioning\n'
      'In iOS, build-name is used as CFBundleShortVersionString while build-number used as CFBundleVersion.\n'
      'Read more about iOS versioning at\n'
      'https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html\n';

  String _androidSdkInstallUrl(Platform platform) {
    const String baseUrl = 'https://flutter.dev/docs/get-started/install';
    const String fragment = '#android-setup';
    if (platform.isMacOS) {
      return '$baseUrl/macos$fragment';
    } else if (platform.isLinux) {
      return '$baseUrl/linux$fragment';
    } else if (platform.isWindows) {
      return '$baseUrl/windows$fragment';
    } else {
      return baseUrl;
    }
  }

