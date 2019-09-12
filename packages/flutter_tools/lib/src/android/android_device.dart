// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../android/android_builder.dart';
import '../android/android_sdk.dart';
import '../android/android_workflow.dart';
import '../application_package.dart';
import '../base/common.dart' show throwToolExit;
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../convert.dart';
import '../device.dart';
import '../globals.dart';
import '../project.dart';
import '../protocol_discovery.dart';

import 'adb.dart';
import 'android.dart';
import 'android_console.dart';
import 'android_sdk.dart';

enum _HardwareType { emulator, physical }

/// Map to help our `isLocalEmulator` detection.
const Map<String, _HardwareType> _knownHardware = <String, _HardwareType>{
  'goldfish': _HardwareType.emulator,
  'qcom': _HardwareType.physical,
  'ranchu': _HardwareType.emulator,
  'samsungexynos7420': _HardwareType.physical,
  'samsungexynos7580': _HardwareType.physical,
  'samsungexynos7870': _HardwareType.physical,
  'samsungexynos8890': _HardwareType.physical,
  'samsungexynos8895': _HardwareType.physical,
  'samsungexynos9810': _HardwareType.physical,
};

bool allowHeapCorruptionOnWindows(int exitCode) {
  // In platform tools 29.0.0 adb.exe seems to be ending with this heap
  // corruption error code on seemingly successful termination.
  // So we ignore this error on Windows.
  return exitCode == -1073740940 && platform.isWindows;
}

class AndroidDevices extends PollingDeviceDiscovery {
  AndroidDevices() : super('Android devices');

  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => androidWorkflow.canListDevices;

  @override
  Future<List<Device>> pollingGetDevices() async => getAdbDevices();

  @override
  Future<List<String>> getDiagnostics() async => getAdbDeviceDiagnostics();
}

class AndroidDevice extends Device {
  AndroidDevice(
    String id, {
    this.productID,
    this.modelID,
    this.deviceCodeName,
  }) : super(
      id,
      category: Category.mobile,
      platformType: PlatformType.android,
      ephemeral: true,
  );

  final String productID;
  final String modelID;
  final String deviceCodeName;

  Map<String, String> _properties;
  bool _isLocalEmulator;
  TargetPlatform _platform;

  Future<String> _getProperty(String name) async {
    if (_properties == null) {
      _properties = <String, String>{};

      final List<String> propCommand = adbCommandForDevice(<String>['shell', 'getprop']);
      printTrace(propCommand.join(' '));

      try {
        // We pass an encoding of latin1 so that we don't try and interpret the
        // `adb shell getprop` result as UTF8.
        final ProcessResult result = await processManager.run(
          propCommand,
          stdoutEncoding: latin1,
          stderrEncoding: latin1,
        );
        if (result.exitCode == 0 || allowHeapCorruptionOnWindows(result.exitCode)) {
          _properties = parseAdbDeviceProperties(result.stdout);
        } else {
          printError('Error ${result.exitCode} retrieving device properties for $name:');
          printError(result.stderr);
        }
      } on ProcessException catch (error) {
        printError('Error retrieving device properties for $name: $error');
      }
    }

    return _properties[name];
  }

  @override
  Future<bool> get isLocalEmulator async {
    if (_isLocalEmulator == null) {
      final String hardware = await _getProperty('ro.hardware');
      printTrace('ro.hardware = $hardware');
      if (_knownHardware.containsKey(hardware)) {
        // Look for known hardware models.
        _isLocalEmulator = _knownHardware[hardware] == _HardwareType.emulator;
      } else {
        // Fall back to a best-effort heuristic-based approach.
        final String characteristics = await _getProperty('ro.build.characteristics');
        printTrace('ro.build.characteristics = $characteristics');
        _isLocalEmulator = characteristics != null && characteristics.contains('emulator');
      }
    }
    return _isLocalEmulator;
  }

  /// The unique identifier for the emulator that corresponds to this device, or
  /// null if it is not an emulator.
  ///
  /// The ID returned matches that in the output of `flutter emulators`. Fetching
  /// this name may require connecting to the device and if an error occurs null
  /// will be returned.
  @override
  Future<String> get emulatorId async {
    if (!(await isLocalEmulator))
      return null;

    // Emulators always have IDs in the format emulator-(port) where port is the
    // Android Console port number.
    final RegExp emulatorPortRegex = RegExp(r'emulator-(\d+)');

    final Match portMatch = emulatorPortRegex.firstMatch(id);
    if (portMatch == null || portMatch.groupCount < 1) {
      return null;
    }

    const String host = 'localhost';
    final int port = int.parse(portMatch.group(1));
    printTrace('Fetching avd name for $name via Android console on $host:$port');

    try {
      final Socket socket = await androidConsoleSocketFactory(host, port);
      final AndroidConsole console = AndroidConsole(socket);

      try {
        await console
            .connect()
            .timeout(timeoutConfiguration.fastOperation,
                onTimeout: () => throw TimeoutException('Connection timed out'));

        return await console
            .getAvdName()
            .timeout(timeoutConfiguration.fastOperation,
                onTimeout: () => throw TimeoutException('"avd name" timed out'));
      } finally {
        console.destroy();
      }
    } catch (e) {
      printTrace('Failed to fetch avd name for emulator at $host:$port: $e');
      // If we fail to connect to the device, we should not fail so just return
      // an empty name. This data is best-effort.
      return null;
    }
  }

  @override
  Future<TargetPlatform> get targetPlatform async {
    if (_platform == null) {
      // http://developer.android.com/ndk/guides/abis.html (x86, armeabi-v7a, ...)
      switch (await _getProperty('ro.product.cpu.abi')) {
        case 'arm64-v8a':
          _platform = TargetPlatform.android_arm64;
          break;
        case 'x86_64':
          _platform = TargetPlatform.android_x64;
          break;
        case 'x86':
          _platform = TargetPlatform.android_x86;
          break;
        default:
          _platform = TargetPlatform.android_arm;
          break;
      }
    }

    return _platform;
  }

  @override
  Future<String> get sdkNameAndVersion async =>
      'Android ${await _sdkVersion} (API ${await _apiVersion})';

  Future<String> get _sdkVersion => _getProperty('ro.build.version.release');

  Future<String> get _apiVersion => _getProperty('ro.build.version.sdk');

  _AdbLogReader _logReader;
  _AndroidDevicePortForwarder _portForwarder;

  List<String> adbCommandForDevice(List<String> args) {
    return <String>[getAdbPath(androidSdk), '-s', id, ...args];
  }

  String runAdbCheckedSync(
      List<String> params, {
        String workingDirectory,
        bool allowReentrantFlutter = false,
        Map<String, String> environment}) {
    return processUtils.runSync(
      adbCommandForDevice(params),
      throwOnError: true,
      workingDirectory: workingDirectory,
      allowReentrantFlutter: allowReentrantFlutter,
      environment: environment,
      whiteListFailures: allowHeapCorruptionOnWindows,
    ).stdout.trim();
  }

  Future<RunResult> runAdbCheckedAsync(
      List<String> params, {
        String workingDirectory,
        bool allowReentrantFlutter = false,
      }) async {
    return processUtils.run(
      adbCommandForDevice(params),
      throwOnError: true,
      workingDirectory: workingDirectory,
      allowReentrantFlutter: allowReentrantFlutter,
      whiteListFailures: allowHeapCorruptionOnWindows,
    );
  }

  bool _isValidAdbVersion(String adbVersion) {
    // Sample output: 'Android Debug Bridge version 1.0.31'
    final Match versionFields = RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(adbVersion);
    if (versionFields != null) {
      final int majorVersion = int.parse(versionFields[1]);
      final int minorVersion = int.parse(versionFields[2]);
      final int patchVersion = int.parse(versionFields[3]);
      if (majorVersion > 1) {
        return true;
      }
      if (majorVersion == 1 && minorVersion > 0) {
        return true;
      }
      if (majorVersion == 1 && minorVersion == 0 && patchVersion >= 39) {
        return true;
      }
      return false;
    }
    printError(
        'Unrecognized adb version string $adbVersion. Skipping version check.');
    return true;
  }

  Future<bool> _checkForSupportedAdbVersion() async {
    if (androidSdk == null) {
      return false;
    }

    try {
      final RunResult adbVersion = await processUtils.run(
        <String>[getAdbPath(androidSdk), 'version'],
        throwOnError: true,
      );
      if (_isValidAdbVersion(adbVersion.stdout)) {
        return true;
      }
      printError('The ADB at "${getAdbPath(androidSdk)}" is too old; please install version 1.0.39 or later.');
    } catch (error, trace) {
      printError('Error running ADB: $error', stackTrace: trace);
    }

    return false;
  }

  Future<bool> _checkForSupportedAndroidVersion() async {
    try {
      // If the server is automatically restarted, then we get irrelevant
      // output lines like this, which we want to ignore:
      //   adb server is out of date.  killing..
      //   * daemon started successfully *
      await processUtils.run(
        <String>[getAdbPath(androidSdk), 'start-server'],
        throwOnError: true,
      );

      // Sample output: '22'
      final String sdkVersion = await _getProperty('ro.build.version.sdk');


      final int sdkVersionParsed = int.tryParse(sdkVersion);
      if (sdkVersionParsed == null) {
        printError('Unexpected response from getprop: "$sdkVersion"');
        return false;
      }

      if (sdkVersionParsed < minApiLevel) {
        printError(
          'The Android version ($sdkVersion) on the target device is too old. Please '
          'use a $minVersionName (version $minApiLevel / $minVersionText) device or later.');
        return false;
      }

      return true;
    } catch (e) {
      printError('Unexpected failure from adb: $e');
      return false;
    }
  }

  String _getDeviceSha1Path(ApplicationPackage app) {
    return '/data/local/tmp/sky.${app.id}.sha1';
  }

  Future<String> _getDeviceApkSha1(ApplicationPackage app) async {
    final RunResult result = await processUtils.run(
      adbCommandForDevice(<String>['shell', 'cat', _getDeviceSha1Path(app)]));
    return result.stdout;
  }

  String _getSourceSha1(ApplicationPackage app) {
    final AndroidApk apk = app;
    final File shaFile = fs.file('${apk.file.path}.sha1');
    return shaFile.existsSync() ? shaFile.readAsStringSync() : '';
  }

  @override
  String get name => modelID;

  @override
  Future<bool> isAppInstalled(ApplicationPackage app) async {
    // This call takes 400ms - 600ms.
    try {
      final RunResult listOut = await runAdbCheckedAsync(<String>['shell', 'pm', 'list', 'packages', app.id]);
      return LineSplitter.split(listOut.stdout).contains('package:${app.id}');
    } catch (error) {
      printTrace('$error');
      return false;
    }
  }

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async {
    final String installedSha1 = await _getDeviceApkSha1(app);
    return installedSha1.isNotEmpty && installedSha1 == _getSourceSha1(app);
  }

  @override
  Future<bool> installApp(ApplicationPackage app) async {
    final AndroidApk apk = app;
    if (!apk.file.existsSync()) {
      printError('"${fs.path.relative(apk.file.path)}" does not exist.');
      return false;
    }

    if (!await _checkForSupportedAdbVersion() || !await _checkForSupportedAndroidVersion())
      return false;

    final Status status = logger.startProgress('Installing ${fs.path.relative(apk.file.path)}...', timeout: timeoutConfiguration.slowOperation);
    final RunResult installResult = await processUtils.run(
      adbCommandForDevice(<String>['install', '-t', '-r', apk.file.path]));
    status.stop();
    // Some versions of adb exit with exit code 0 even on failure :(
    // Parsing the output to check for failures.
    final RegExp failureExp = RegExp(r'^Failure.*$', multiLine: true);
    final String failure = failureExp.stringMatch(installResult.stdout);
    if (failure != null) {
      printError('Package install error: $failure');
      return false;
    }
    if (installResult.exitCode != 0) {
      printError('Error: ADB exited with exit code ${installResult.exitCode}');
      printError('$installResult');
      return false;
    }
    try {
      await runAdbCheckedAsync(<String>[
        'shell', 'echo', '-n', _getSourceSha1(app), '>', _getDeviceSha1Path(app),
      ]);
    } on ProcessException catch (error) {
      printError('adb shell failed to write the SHA hash: $error.');
      return false;
    }
    return true;
  }

  @override
  Future<bool> uninstallApp(ApplicationPackage app) async {
    if (!await _checkForSupportedAdbVersion() || !await _checkForSupportedAndroidVersion())
      return false;

    String uninstallOut;
    try {
      final RunResult uninstallResult = await processUtils.run(
        adbCommandForDevice(<String>['uninstall', app.id]),
        throwOnError: true,
      );
      uninstallOut = uninstallResult.stdout;
    } catch (error) {
      printError('adb uninstall failed: $error');
      return false;
    }
    final RegExp failureExp = RegExp(r'^Failure.*$', multiLine: true);
    final String failure = failureExp.stringMatch(uninstallOut);
    if (failure != null) {
      printError('Package uninstall error: $failure');
      return false;
    }

    return true;
  }

  Future<bool> _installLatestApp(ApplicationPackage package) async {
    final bool wasInstalled = await isAppInstalled(package);
    if (wasInstalled) {
      if (await isLatestBuildInstalled(package)) {
        printTrace('Latest build already installed.');
        return true;
      }
    }
    printTrace('Installing APK.');
    if (!await installApp(package)) {
      printTrace('Warning: Failed to install APK.');
      if (wasInstalled) {
        printStatus('Uninstalling old version...');
        if (!await uninstallApp(package)) {
          printError('Error: Uninstalling old version failed.');
          return false;
        }
        if (!await installApp(package)) {
          printError('Error: Failed to install APK again.');
          return false;
        }
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
  }) async {
    if (!await _checkForSupportedAdbVersion() || !await _checkForSupportedAndroidVersion())
      return LaunchResult.failed();

    final TargetPlatform devicePlatform = await targetPlatform;
    if (!(devicePlatform == TargetPlatform.android_arm ||
          devicePlatform == TargetPlatform.android_arm64) &&
        !debuggingOptions.buildInfo.isDebug) {
      printError('Profile and release builds are only supported on ARM targets.');
      return LaunchResult.failed();
    }

    AndroidArch androidArch;
    switch (devicePlatform) {
      case TargetPlatform.android_arm:
        androidArch = AndroidArch.armeabi_v7a;
        break;
      case TargetPlatform.android_arm64:
        androidArch = AndroidArch.arm64_v8a;
        break;
      case TargetPlatform.android_x64:
        androidArch = AndroidArch.x86_64;
        break;
      case TargetPlatform.android_x86:
        androidArch = AndroidArch.x86;
        break;
      default:
        printError('Android platforms are only supported.');
        return LaunchResult.failed();
    }

    if (!prebuiltApplication || androidSdk.licensesAvailable && androidSdk.latestVersion == null) {
      printTrace('Building APK');
      final FlutterProject project = FlutterProject.current();
      await androidBuilder.buildApk(
          project: project,
          target: mainPath,
          androidBuildInfo: AndroidBuildInfo(debuggingOptions.buildInfo,
            targetArchs: <AndroidArch>[androidArch]
          ),
      );
      // Package has been built, so we can get the updated application ID and
      // activity name from the .apk.
      package = await AndroidApk.fromAndroidProject(project.android);
    }
    // There was a failure parsing the android project information.
    if (package == null) {
      throwToolExit('Problem building Android application: see above error(s).');
    }

    printTrace("Stopping app '${package.name}' on $name.");
    await stopApp(package);

    if (!await _installLatestApp(package))
      return LaunchResult.failed();

    final bool traceStartup = platformArgs['trace-startup'] ?? false;
    final AndroidApk apk = package;
    printTrace('$this startApp');

    ProtocolDiscovery observatoryDiscovery;

    if (debuggingOptions.debuggingEnabled) {
      // TODO(devoncarew): Remember the forwarding information (so we can later remove the
      // port forwarding or set it up again when adb fails on us).
      observatoryDiscovery = ProtocolDiscovery.observatory(
        getLogReader(),
        portForwarder: portForwarder,
        hostPort: debuggingOptions.observatoryPort,
        ipv6: ipv6,
      );
    }

    List<String> cmd;

    cmd = <String>[
      'shell', 'am', 'start',
      '-a', 'android.intent.action.RUN',
      '-f', '0x20000000', // FLAG_ACTIVITY_SINGLE_TOP
      '--ez', 'enable-background-compilation', 'true',
      '--ez', 'enable-dart-profiling', 'true',
      if (traceStartup)
        ...<String>['--ez', 'trace-startup', 'true'],
      if (route != null)
        ...<String>['--es', 'route', route],
      if (debuggingOptions.enableSoftwareRendering)
        ...<String>['--ez', 'enable-software-rendering', 'true'],
      if (debuggingOptions.skiaDeterministicRendering)
        ...<String>['--ez', 'skia-deterministic-rendering', 'true'],
      if (debuggingOptions.traceSkia)
        ...<String>['--ez', 'trace-skia', 'true'],
      if (debuggingOptions.traceSystrace)
        ...<String>['--ez', 'trace-systrace', 'true'],
      if (debuggingOptions.dumpSkpOnShaderCompilation)
        ...<String>['--ez', 'dump-skp-on-shader-compilation', 'true'],
      if (debuggingOptions.debuggingEnabled)
        ...<String>[
          if (debuggingOptions.buildInfo.isDebug)
            ...<String>[
              ...<String>['--ez', 'enable-checked-mode', 'true'],
              ...<String>['--ez', 'verify-entry-points', 'true'],
            ],
          if (debuggingOptions.startPaused)
            ...<String>['--ez', 'start-paused', 'true'],
          if (debuggingOptions.disableServiceAuthCodes)
            ...<String>['--ez', 'disable-service-auth-codes', 'true'],
          if (debuggingOptions.dartFlags.isNotEmpty)
            ...<String>['--es', 'dart-flags', debuggingOptions.dartFlags],
          if (debuggingOptions.useTestFonts)
            ...<String>['--ez', 'use-test-fonts', 'true'],
          if (debuggingOptions.verboseSystemLogs)
            ...<String>['--ez', 'verbose-logging', 'true'],
        ],
      apk.launchActivity,
    ];
    final String result = (await runAdbCheckedAsync(cmd)).stdout;
    // This invocation returns 0 even when it fails.
    if (result.contains('Error: ')) {
      printError(result.trim(), wrap: false);
      return LaunchResult.failed();
    }

    if (!debuggingOptions.debuggingEnabled)
      return LaunchResult.succeeded();

    // Wait for the service protocol port here. This will complete once the
    // device has printed "Observatory is listening on...".
    printTrace('Waiting for observatory port to be available...');

    // TODO(danrubel): Waiting for observatory services can be made common across all devices.
    try {
      Uri observatoryUri;

      if (debuggingOptions.buildInfo.isDebug || debuggingOptions.buildInfo.isProfile) {
        observatoryUri = await observatoryDiscovery.uri;
      }

      return LaunchResult.succeeded(observatoryUri: observatoryUri);
    } catch (error) {
      printError('Error waiting for a debug connection: $error');
      return LaunchResult.failed();
    } finally {
      await observatoryDiscovery.cancel();
    }
  }

  @override
  bool get supportsHotReload => true;

  @override
  bool get supportsHotRestart => true;

  @override
  Future<bool> stopApp(ApplicationPackage app) {
    final List<String> command = adbCommandForDevice(<String>['shell', 'am', 'force-stop', app.id]);
    return processUtils.stream(command).then<bool>(
        (int exitCode) => exitCode == 0 || allowHeapCorruptionOnWindows(exitCode));
  }

  @override
  void clearLogs() {
    processUtils.runSync(adbCommandForDevice(<String>['logcat', '-c']));
  }

  @override
  DeviceLogReader getLogReader({ ApplicationPackage app }) {
    // The Android log reader isn't app-specific.
    _logReader ??= _AdbLogReader(this);
    return _logReader;
  }

  @override
  DevicePortForwarder get portForwarder => _portForwarder ??= _AndroidDevicePortForwarder(this);

  static final RegExp _timeRegExp = RegExp(r'^\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}', multiLine: true);

  /// Return the most recent timestamp in the Android log or [null] if there is
  /// no available timestamp. The format can be passed to logcat's -T option.
  String get lastLogcatTimestamp {
    String output;
    try {
      output = runAdbCheckedSync(<String>[
        'shell', '-x', 'logcat', '-v', 'time', '-t', '1',
      ]);
    } catch (error) {
      printError('Failed to extract the most recent timestamp from the Android log: $error.');
      return null;
    }
    final Match timeMatch = _timeRegExp.firstMatch(output);
    return timeMatch?.group(0);
  }

  @override
  bool isSupported() => true;

  @override
  bool get supportsScreenshot => true;

  @override
  Future<void> takeScreenshot(File outputFile) async {
    const String remotePath = '/data/local/tmp/flutter_screenshot.png';
    await runAdbCheckedAsync(<String>['shell', 'screencap', '-p', remotePath]);
    await processUtils.run(
      adbCommandForDevice(<String>['pull', remotePath, outputFile.path]),
      throwOnError: true,
    );
    await runAdbCheckedAsync(<String>['shell', 'rm', remotePath]);
  }

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.android.existsSync();
  }
}

Map<String, String> parseAdbDeviceProperties(String str) {
  final Map<String, String> properties = <String, String>{};
  final RegExp propertyExp = RegExp(r'\[(.*?)\]: \[(.*?)\]');
  for (Match match in propertyExp.allMatches(str))
    properties[match.group(1)] = match.group(2);
  return properties;
}

/// Return the list of connected ADB devices.
List<AndroidDevice> getAdbDevices() {
  final String adbPath = getAdbPath(androidSdk);
  if (adbPath == null)
    return <AndroidDevice>[];
  String text;
  try {
    text = processUtils.runSync(
      <String>[adbPath, 'devices', '-l'],
      throwOnError: true,
    ).stdout.trim();
  } on ArgumentError catch (exception) {
    throwToolExit('Unable to find "adb", check your Android SDK installation and '
      'ANDROID_HOME environment variable: ${exception.message}');
  } on ProcessException catch (exception) {
    throwToolExit('Unable to run "adb", check your Android SDK installation and '
      'ANDROID_HOME environment variable: ${exception.executable}');
  }
  final List<AndroidDevice> devices = <AndroidDevice>[];
  parseADBDeviceOutput(text, devices: devices);
  return devices;
}

/// Get diagnostics about issues with any connected devices.
Future<List<String>> getAdbDeviceDiagnostics() async {
  final String adbPath = getAdbPath(androidSdk);
  if (adbPath == null)
    return <String>[];

  final RunResult result = await processUtils.run(<String>[adbPath, 'devices', '-l']);
  if (result.exitCode != 0) {
    return <String>[];
  } else {
    final String text = result.stdout;
    final List<String> diagnostics = <String>[];
    parseADBDeviceOutput(text, diagnostics: diagnostics);
    return diagnostics;
  }
}

// 015d172c98400a03       device usb:340787200X product:nakasi model:Nexus_7 device:grouper
final RegExp _kDeviceRegex = RegExp(r'^(\S+)\s+(\S+)(.*)');

/// Parse the given `adb devices` output in [text], and fill out the given list
/// of devices and possible device issue diagnostics. Either argument can be null,
/// in which case information for that parameter won't be populated.
@visibleForTesting
void parseADBDeviceOutput(
  String text, {
  List<AndroidDevice> devices,
  List<String> diagnostics,
}) {
  // Check for error messages from adb
  if (!text.contains('List of devices')) {
    diagnostics?.add(text);
    return;
  }

  for (String line in text.trim().split('\n')) {
    // Skip lines like: * daemon started successfully *
    if (line.startsWith('* daemon '))
      continue;

    // Skip lines about adb server and client version not matching
    if (line.startsWith(RegExp(r'adb server (version|is out of date)'))) {
      diagnostics?.add(line);
      continue;
    }

    if (line.startsWith('List of devices'))
      continue;

    if (_kDeviceRegex.hasMatch(line)) {
      final Match match = _kDeviceRegex.firstMatch(line);

      final String deviceID = match[1];
      final String deviceState = match[2];
      String rest = match[3];

      final Map<String, String> info = <String, String>{};
      if (rest != null && rest.isNotEmpty) {
        rest = rest.trim();
        for (String data in rest.split(' ')) {
          if (data.contains(':')) {
            final List<String> fields = data.split(':');
            info[fields[0]] = fields[1];
          }
        }
      }

      if (info['model'] != null)
        info['model'] = cleanAdbDeviceName(info['model']);

      if (deviceState == 'unauthorized') {
        diagnostics?.add(
          'Device $deviceID is not authorized.\n'
          'You might need to check your device for an authorization dialog.'
        );
      } else if (deviceState == 'offline') {
        diagnostics?.add('Device $deviceID is offline.');
      } else {
        devices?.add(AndroidDevice(
          deviceID,
          productID: info['product'],
          modelID: info['model'] ?? deviceID,
          deviceCodeName: info['device'],
        ));
      }
    } else {
      diagnostics?.add(
        'Unexpected failure parsing device information from adb output:\n'
        '$line\n'
        'Please report a bug at https://github.com/flutter/flutter/issues/new/choose');
    }
  }
}

/// A log reader that logs from `adb logcat`.
class _AdbLogReader extends DeviceLogReader {
  _AdbLogReader(this.device) {
    _linesController = StreamController<String>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final AndroidDevice device;

  StreamController<String> _linesController;
  Process _process;

  @override
  Stream<String> get logLines => _linesController.stream;

  @override
  String get name => device.name;

  DateTime _timeOrigin;

  DateTime _adbTimestampToDateTime(String adbTimestamp) {
    // The adb timestamp format is: mm-dd hours:minutes:seconds.milliseconds
    // Dart's DateTime parse function accepts this format so long as we provide
    // the year, resulting in:
    // yyyy-mm-dd hours:minutes:seconds.milliseconds.
    return DateTime.parse('${DateTime.now().year}-$adbTimestamp');
  }

  void _start() {
    // Start the adb logcat process.
    final List<String> args = <String>['shell', '-x', 'logcat', '-v', 'time'];
    final String lastTimestamp = device.lastLogcatTimestamp;
    if (lastTimestamp != null) {
      _timeOrigin = _adbTimestampToDateTime(lastTimestamp);
    } else {
      _timeOrigin = null;
    }
    processUtils.start(device.adbCommandForDevice(args)).then<void>((Process process) {
      _process = process;
      // We expect logcat streams to occasionally contain invalid utf-8,
      // see: https://github.com/flutter/flutter/pull/8864.
      const Utf8Decoder decoder = Utf8Decoder(reportErrors: false);
      _process.stdout.transform<String>(decoder).transform<String>(const LineSplitter()).listen(_onLine);
      _process.stderr.transform<String>(decoder).transform<String>(const LineSplitter()).listen(_onLine);
      _process.exitCode.whenComplete(() {
        if (_linesController.hasListener)
          _linesController.close();
      });
    });
  }

  // 'W/ActivityManager(pid): '
  static final RegExp _logFormat = RegExp(r'^[VDIWEF]\/.*?\(\s*(\d+)\):\s');

  static final List<RegExp> _whitelistedTags = <RegExp>[
    RegExp(r'^[VDIWEF]\/flutter[^:]*:\s+', caseSensitive: false),
    RegExp(r'^[IE]\/DartVM[^:]*:\s+'),
    RegExp(r'^[WEF]\/AndroidRuntime:\s+'),
    RegExp(r'^[WEF]\/ActivityManager:\s+.*(\bflutter\b|\bdomokit\b|\bsky\b)'),
    RegExp(r'^[WEF]\/System\.err:\s+'),
    RegExp(r'^[F]\/[\S^:]+:\s+'),
  ];

  // 'F/libc(pid): Fatal signal 11'
  static final RegExp _fatalLog = RegExp(r'^F\/libc\s*\(\s*\d+\):\sFatal signal (\d+)');

  // 'I/DEBUG(pid): ...'
  static final RegExp _tombstoneLine = RegExp(r'^[IF]\/DEBUG\s*\(\s*\d+\):\s(.+)$');

  // 'I/DEBUG(pid): Tombstone written to: '
  static final RegExp _tombstoneTerminator = RegExp(r'^Tombstone written to:\s');

  // we default to true in case none of the log lines match
  bool _acceptedLastLine = true;

  // Whether a fatal crash is happening or not.
  // During a fatal crash only lines from the crash are accepted, the rest are
  // dropped.
  bool _fatalCrash = false;

  // The format of the line is controlled by the '-v' parameter passed to
  // adb logcat. We are currently passing 'time', which has the format:
  // mm-dd hh:mm:ss.milliseconds Priority/Tag( PID): ....
  void _onLine(String line) {
    final Match timeMatch = AndroidDevice._timeRegExp.firstMatch(line);
    if (timeMatch == null) {
      return;
    }
    if (_timeOrigin != null) {
      final String timestamp = timeMatch.group(0);
      final DateTime time = _adbTimestampToDateTime(timestamp);
      if (!time.isAfter(_timeOrigin)) {
        // Ignore log messages before the origin.
        return;
      }
    }
    if (line.length == timeMatch.end) {
      return;
    }
    // Chop off the time.
    line = line.substring(timeMatch.end + 1);
    final Match logMatch = _logFormat.firstMatch(line);
    if (logMatch != null) {
      bool acceptLine = false;

      if (_fatalCrash) {
        // While a fatal crash is going on, only accept lines from the crash
        // Otherwise the crash log in the console may get interrupted

        final Match fatalMatch = _tombstoneLine.firstMatch(line);

        if (fatalMatch != null) {
          acceptLine = true;

          line = fatalMatch[1];

          if (_tombstoneTerminator.hasMatch(fatalMatch[1])) {
            // Hit crash terminator, stop logging the crash info
            _fatalCrash = false;
          }
        }
      } else if (appPid != null && int.parse(logMatch.group(1)) == appPid) {
        acceptLine = true;

        if (_fatalLog.hasMatch(line)) {
          // Hit fatal signal, app is now crashing
          _fatalCrash = true;
        }
      } else {
        // Filter on approved names and levels.
        acceptLine = _whitelistedTags.any((RegExp re) => re.hasMatch(line));
      }

      if (acceptLine) {
        _acceptedLastLine = true;
        _linesController.add(line);
        return;
      }
      _acceptedLastLine = false;
    } else if (line == '--------- beginning of system' ||
               line == '--------- beginning of main') {
      // hide the ugly adb logcat log boundaries at the start
      _acceptedLastLine = false;
    } else {
      // If it doesn't match the log pattern at all, then pass it through if we
      // passed the last matching line through. It might be a multiline message.
      if (_acceptedLastLine) {
        _linesController.add(line);
        return;
      }
    }
  }

  void _stop() {
    // TODO(devoncarew): We should remove adb port forwarding here.

    _process?.kill();
  }
}

class _AndroidDevicePortForwarder extends DevicePortForwarder {
  _AndroidDevicePortForwarder(this.device);

  final AndroidDevice device;

  static int _extractPort(String portString) {

    return int.tryParse(portString.trim());
  }

  @override
  List<ForwardedPort> get forwardedPorts {
    final List<ForwardedPort> ports = <ForwardedPort>[];

    String stdout;
    try {
      stdout = processUtils.runSync(
        device.adbCommandForDevice(<String>['forward', '--list']),
        throwOnError: true,
      ).stdout.trim();
    } on ProcessException catch (error) {
      printError('Failed to list forwarded ports: $error.');
      return ports;
    }

    final List<String> lines = LineSplitter.split(stdout).toList();
    for (String line in lines) {
      if (!line.startsWith(device.id)) {
        continue;
      }
      final List<String> splitLine = line.split('tcp:');

      // Sanity check splitLine.
      if (splitLine.length != 3) {
        continue;
      }

      // Attempt to extract ports.
      final int hostPort = _extractPort(splitLine[1]);
      final int devicePort = _extractPort(splitLine[2]);

      // Failed, skip.
      if (hostPort == null || devicePort == null) {
        continue;
      }

      ports.add(ForwardedPort(hostPort, devicePort));
    }

    return ports;
  }

  @override
  Future<int> forward(int devicePort, { int hostPort }) async {
    hostPort ??= 0;
    final List<String> forwardCommand = <String>[
      'forward',
      'tcp:$hostPort',
      'tcp:$devicePort',
    ];
    final RunResult process = await processUtils.run(
      device.adbCommandForDevice(forwardCommand),
      throwOnError: true,
    );

    if (process.stderr.isNotEmpty) {
      process.throwException('adb returned error:\n${process.stderr}');
    }

    if (process.exitCode != 0) {
      if (process.stdout.isNotEmpty) {
        process.throwException('adb returned error:\n${process.stdout}');
      }
      process.throwException('adb failed without a message');
    }

    if (hostPort == 0) {
      if (process.stdout.isEmpty) {
        process.throwException('adb did not report forwarded port');
      }
      hostPort = int.tryParse(process.stdout);
      if (hostPort == null) {
        process.throwException('adb returned invalid port number:\n${process.stdout}');
      }
    } else {
      // stdout may be empty or the port we asked it to forward, though it's
      // not documented (or obvious) what triggers each case.
      //
      // Observations are:
      //   - On MacOS it's always empty when Flutter spawns the process, but
      //   - On MacOS it prints the port number when run from the terminal, unless
      //     the port is already forwarded, when it also prints nothing.
      //   - On ChromeOS, the port appears to be printed even when Flutter spawns
      //     the process
      //
      // To cover all cases, we accept the output being either empty or exactly
      // the port number, but treat any other output as probably being an error
      // message.
      if (process.stdout.isNotEmpty && process.stdout.trim() != '$hostPort') {
        process.throwException('adb returned error:\n${process.stdout}');
      }
    }

    return hostPort;
  }

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async {
    final List<String> unforwardCommand = <String>[
      'forward',
      '--remove',
      'tcp:${forwardedPort.hostPort}',
    ];
    await processUtils.run(
      device.adbCommandForDevice(unforwardCommand),
      throwOnError: true,
    );
  }
}
