// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../android/android_builder.dart';
import '../android/android_sdk.dart';
import '../android/android_workflow.dart';
import '../application_package.dart';
import '../base/common.dart' show throwToolExit, unawaited;
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../convert.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../protocol_discovery.dart';

import 'adb.dart';
import 'android.dart';
import 'android_console.dart';
import 'android_sdk.dart';

enum _HardwareType { emulator, physical }

/// Map to help our `isLocalEmulator` detection.
const Map<String, _HardwareType> _kKnownHardware = <String, _HardwareType>{
  'goldfish': _HardwareType.emulator,
  'qcom': _HardwareType.physical,
  'ranchu': _HardwareType.emulator,
  'samsungexynos7420': _HardwareType.physical,
  'samsungexynos7580': _HardwareType.physical,
  'samsungexynos7870': _HardwareType.physical,
  'samsungexynos7880': _HardwareType.physical,
  'samsungexynos8890': _HardwareType.physical,
  'samsungexynos8895': _HardwareType.physical,
  'samsungexynos9810': _HardwareType.physical,
  'samsungexynos7570': _HardwareType.physical,
};

bool allowHeapCorruptionOnWindows(int exitCode) {
  // In platform tools 29.0.0 adb.exe seems to be ending with this heap
  // corruption error code on seemingly successful termination.
  // So we ignore this error on Windows.
  return exitCode == -1073740940 && globals.platform.isWindows;
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
      globals.printTrace(propCommand.join(' '));

      try {
        // We pass an encoding of latin1 so that we don't try and interpret the
        // `adb shell getprop` result as UTF8.
        final ProcessResult result = await globals.processManager.run(
          propCommand,
          stdoutEncoding: latin1,
          stderrEncoding: latin1,
        );
        if (result.exitCode == 0 || allowHeapCorruptionOnWindows(result.exitCode)) {
          _properties = parseAdbDeviceProperties(result.stdout as String);
        } else {
          globals.printError('Error ${result.exitCode} retrieving device properties for $name:');
          globals.printError(result.stderr as String);
        }
      } on ProcessException catch (error) {
        globals.printError('Error retrieving device properties for $name: $error');
      }
    }

    return _properties[name];
  }

  @override
  Future<bool> get isLocalEmulator async {
    if (_isLocalEmulator == null) {
      final String hardware = await _getProperty('ro.hardware');
      globals.printTrace('ro.hardware = $hardware');
      if (_kKnownHardware.containsKey(hardware)) {
        // Look for known hardware models.
        _isLocalEmulator = _kKnownHardware[hardware] == _HardwareType.emulator;
      } else {
        // Fall back to a best-effort heuristic-based approach.
        final String characteristics = await _getProperty('ro.build.characteristics');
        globals.printTrace('ro.build.characteristics = $characteristics');
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
    if (!(await isLocalEmulator)) {
      return null;
    }

    // Emulators always have IDs in the format emulator-(port) where port is the
    // Android Console port number.
    final RegExp emulatorPortRegex = RegExp(r'emulator-(\d+)');

    final Match portMatch = emulatorPortRegex.firstMatch(id);
    if (portMatch == null || portMatch.groupCount < 1) {
      return null;
    }

    const String host = 'localhost';
    final int port = int.parse(portMatch.group(1));
    globals.printTrace('Fetching avd name for $name via Android console on $host:$port');

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
      globals.printTrace('Failed to fetch avd name for emulator at $host:$port: $e');
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
          // Perform additional verification for 64 bit ABI. Some devices,
          // like the Kindle Fire 8, misreport the abilist. We might not
          // be able to retrieve this property, in which case we fall back
          // to assuming 64 bit.
          final String abilist = await _getProperty('ro.product.cpu.abilist');
          if (abilist == null || abilist.contains('arm64-v8a')) {
            _platform = TargetPlatform.android_arm64;
          } else {
            _platform = TargetPlatform.android_arm;
          }
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
    Map<String, String> environment,
  }) {
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
    globals.printError(
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
      globals.printError('The ADB at "${getAdbPath(androidSdk)}" is too old; please install version 1.0.39 or later.');
    } catch (error, trace) {
      globals.printError('Error running ADB: $error', stackTrace: trace);
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
        globals.printError('Unexpected response from getprop: "$sdkVersion"');
        return false;
      }

      if (sdkVersionParsed < minApiLevel) {
        globals.printError(
          'The Android version ($sdkVersion) on the target device is too old. Please '
          'use a $minVersionName (version $minApiLevel / $minVersionText) device or later.');
        return false;
      }

      return true;
    } catch (e, stacktrace) {
      globals.printError('Unexpected failure from adb: $e');
      globals.printError('Stacktrace: $stacktrace');
      return false;
    }
  }

  String _getDeviceSha1Path(AndroidApk apk) {
    return '/data/local/tmp/sky.${apk.id}.sha1';
  }

  Future<String> _getDeviceApkSha1(AndroidApk apk) async {
    final RunResult result = await processUtils.run(
      adbCommandForDevice(<String>['shell', 'cat', _getDeviceSha1Path(apk)]));
    return result.stdout;
  }

  String _getSourceSha1(AndroidApk apk) {
    final File shaFile = globals.fs.file('${apk.file.path}.sha1');
    return shaFile.existsSync() ? shaFile.readAsStringSync() : '';
  }

  @override
  String get name => modelID;

  @override
  Future<bool> isAppInstalled(AndroidApk app) async {
    // This call takes 400ms - 600ms.
    try {
      final RunResult listOut = await runAdbCheckedAsync(<String>['shell', 'pm', 'list', 'packages', app.id]);
      return LineSplitter.split(listOut.stdout).contains('package:${app.id}');
    } catch (error) {
      globals.printTrace('$error');
      return false;
    }
  }

  @override
  Future<bool> isLatestBuildInstalled(AndroidApk app) async {
    final String installedSha1 = await _getDeviceApkSha1(app);
    return installedSha1.isNotEmpty && installedSha1 == _getSourceSha1(app);
  }

  @override
  Future<bool> installApp(AndroidApk app) async {
    if (!app.file.existsSync()) {
      globals.printError('"${globals.fs.path.relative(app.file.path)}" does not exist.');
      return false;
    }

    if (!await _checkForSupportedAdbVersion() ||
        !await _checkForSupportedAndroidVersion()) {
      return false;
    }

    final Status status = globals.logger.startProgress('Installing ${globals.fs.path.relative(app.file.path)}...', timeout: timeoutConfiguration.slowOperation);
    final RunResult installResult = await processUtils.run(
      adbCommandForDevice(<String>['install', '-t', '-r', app.file.path]));
    status.stop();
    // Some versions of adb exit with exit code 0 even on failure :(
    // Parsing the output to check for failures.
    final RegExp failureExp = RegExp(r'^Failure.*$', multiLine: true);
    final String failure = failureExp.stringMatch(installResult.stdout);
    if (failure != null) {
      globals.printError('Package install error: $failure');
      return false;
    }
    if (installResult.exitCode != 0) {
      globals.printError('Error: ADB exited with exit code ${installResult.exitCode}');
      globals.printError('$installResult');
      return false;
    }
    try {
      await runAdbCheckedAsync(<String>[
        'shell', 'echo', '-n', _getSourceSha1(app), '>', _getDeviceSha1Path(app),
      ]);
    } on ProcessException catch (error) {
      globals.printError('adb shell failed to write the SHA hash: $error.');
      return false;
    }
    return true;
  }

  @override
  Future<bool> uninstallApp(AndroidApk app) async {
    if (!await _checkForSupportedAdbVersion() ||
        !await _checkForSupportedAndroidVersion()) {
      return false;
    }

    String uninstallOut;
    try {
      final RunResult uninstallResult = await processUtils.run(
        adbCommandForDevice(<String>['uninstall', app.id]),
        throwOnError: true,
      );
      uninstallOut = uninstallResult.stdout;
    } catch (error) {
      globals.printError('adb uninstall failed: $error');
      return false;
    }
    final RegExp failureExp = RegExp(r'^Failure.*$', multiLine: true);
    final String failure = failureExp.stringMatch(uninstallOut);
    if (failure != null) {
      globals.printError('Package uninstall error: $failure');
      return false;
    }

    return true;
  }

  Future<bool> _installLatestApp(AndroidApk package) async {
    final bool wasInstalled = await isAppInstalled(package);
    if (wasInstalled) {
      if (await isLatestBuildInstalled(package)) {
        globals.printTrace('Latest build already installed.');
        return true;
      }
    }
    globals.printTrace('Installing APK.');
    if (!await installApp(package)) {
      globals.printTrace('Warning: Failed to install APK.');
      if (wasInstalled) {
        globals.printStatus('Uninstalling old version...');
        if (!await uninstallApp(package)) {
          globals.printError('Error: Uninstalling old version failed.');
          return false;
        }
        if (!await installApp(package)) {
          globals.printError('Error: Failed to install APK again.');
          return false;
        }
        return true;
      }
      return false;
    }
    return true;
  }

  AndroidApk _package;

  @override
  Future<LaunchResult> startApp(
    AndroidApk package, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
  }) async {
    if (!await _checkForSupportedAdbVersion() ||
        !await _checkForSupportedAndroidVersion()) {
      return LaunchResult.failed();
    }

    final TargetPlatform devicePlatform = await targetPlatform;
    if (devicePlatform == TargetPlatform.android_x86 &&
       !debuggingOptions.buildInfo.isDebug) {
      globals.printError('Profile and release builds are only supported on ARM/x64 targets.');
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
        globals.printError('Android platforms are only supported.');
        return LaunchResult.failed();
    }

    if (!prebuiltApplication || androidSdk.licensesAvailable && androidSdk.latestVersion == null) {
      globals.printTrace('Building APK');
      final FlutterProject project = FlutterProject.current();
      await androidBuilder.buildApk(
          project: project,
          target: mainPath,
          androidBuildInfo: AndroidBuildInfo(
            debuggingOptions.buildInfo,
            targetArchs: <AndroidArch>[androidArch],
            fastStart: debuggingOptions.fastStart
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

    globals.printTrace("Stopping app '${package.name}' on $name.");
    await stopApp(package);

    if (!await _installLatestApp(package)) {
      return LaunchResult.failed();
    }

    final bool traceStartup = platformArgs['trace-startup'] as bool ?? false;
    globals.printTrace('$this startApp');

    ProtocolDiscovery observatoryDiscovery;

    if (debuggingOptions.debuggingEnabled) {
      // TODO(devoncarew): Remember the forwarding information (so we can later remove the
      // port forwarding or set it up again when adb fails on us).
      observatoryDiscovery = ProtocolDiscovery.observatory(
        getLogReader(),
        portForwarder: portForwarder,
        hostPort: debuggingOptions.hostVmServicePort,
        devicePort: debuggingOptions.deviceVmServicePort,
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
      if (debuggingOptions.cacheSkSL)
      ...<String>['--ez', 'cache-sksl', 'true'],
      if (debuggingOptions.debuggingEnabled) ...<String>[
        if (debuggingOptions.buildInfo.isDebug) ...<String>[
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
      package.launchActivity,
    ];
    final String result = (await runAdbCheckedAsync(cmd)).stdout;
    // This invocation returns 0 even when it fails.
    if (result.contains('Error: ')) {
      globals.printError(result.trim(), wrap: false);
      return LaunchResult.failed();
    }

    _package = package;
    if (!debuggingOptions.debuggingEnabled) {
      return LaunchResult.succeeded();
    }

    // Wait for the service protocol port here. This will complete once the
    // device has printed "Observatory is listening on...".
    globals.printTrace('Waiting for observatory port to be available...');

    // TODO(danrubel): Waiting for observatory services can be made common across all devices.
    try {
      Uri observatoryUri;

      if (debuggingOptions.buildInfo.isDebug || debuggingOptions.buildInfo.isProfile) {
        observatoryUri = await observatoryDiscovery.uri;
      }

      return LaunchResult.succeeded(observatoryUri: observatoryUri);
    } catch (error) {
      globals.printError('Error waiting for a debug connection: $error');
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
  bool get supportsFastStart => true;

  @override
  Future<bool> stopApp(AndroidApk app) {
    final List<String> command = adbCommandForDevice(<String>['shell', 'am', 'force-stop', app.id]);
    return processUtils.stream(command).then<bool>(
        (int exitCode) => exitCode == 0 || allowHeapCorruptionOnWindows(exitCode));
  }

  @override
  Future<MemoryInfo> queryMemoryInfo() async {
    final RunResult runResult = await processUtils.run(adbCommandForDevice(<String>[
      'shell',
      'dumpsys',
      'meminfo',
      _package.id,
      '-d',
    ]));

    if (runResult.exitCode != 0) {
      return const MemoryInfo.empty();
    }
    return parseMeminfoDump(runResult.stdout);
  }

  @override
  void clearLogs() {
    processUtils.runSync(adbCommandForDevice(<String>['logcat', '-c']));
  }

  @override
  DeviceLogReader getLogReader({ AndroidApk app }) {
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
        'shell', '-x', 'logcat', '-v', 'time', '-t', '1'
      ]);
    } catch (error) {
      globals.printError('Failed to extract the most recent timestamp from the Android log: $error.');
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

  @override
  Future<void> dispose() async {
    _logReader?._stop();
    await _portForwarder?.dispose();
  }
}

Map<String, String> parseAdbDeviceProperties(String str) {
  final Map<String, String> properties = <String, String>{};
  final RegExp propertyExp = RegExp(r'\[(.*?)\]: \[(.*?)\]');
  for (final Match match in propertyExp.allMatches(str)) {
    properties[match.group(1)] = match.group(2);
  }
  return properties;
}

/// Process the dumpsys info formatted in a table-like structure.
///
/// Currently this only pulls information from the  "App Summary" subsection.
///
/// Example output:
///
/// Applications Memory Usage (in Kilobytes):
/// Uptime: 441088659 Realtime: 521464097
///
/// ** MEMINFO in pid 16141 [io.flutter.demo.gallery] **
///                    Pss  Private  Private  SwapPss     Heap     Heap     Heap
///                  Total    Dirty    Clean    Dirty     Size    Alloc     Free
///                 ------   ------   ------   ------   ------   ------   ------
///   Native Heap     8648     8620        0       16    20480    12403     8076
///   Dalvik Heap      547      424       40       18     2628     1092     1536
///  Dalvik Other      464      464        0        0
///         Stack      496      496        0        0
///        Ashmem        2        0        0        0
///       Gfx dev      212      204        0        0
///     Other dev       48        0       48        0
///      .so mmap    10770      708     9372       25
///     .apk mmap      240        0        0        0
///     .ttf mmap       35        0       32        0
///     .dex mmap     2205        4     1172        0
///     .oat mmap       64        0        0        0
///     .art mmap     4228     3848       24        2
///    Other mmap    20713        4    20704        0
///     GL mtrack     2380     2380        0        0
///       Unknown    43971    43968        0        1
///         TOTAL    95085    61120    31392       62    23108    13495     9612
///
///  App Summary
///                        Pss(KB)
///                         ------
///            Java Heap:     4296
///          Native Heap:     8620
///                 Code:    11288
///                Stack:      496
///             Graphics:     2584
///        Private Other:    65228
///               System:     2573
///
///                TOTAL:    95085       TOTAL SWAP PSS:       62
///
///  Objects
///                Views:        9         ViewRootImpl:        1
///          AppContexts:        3           Activities:        1
///              Assets:        4        AssetManagers:        3
///        Local Binders:       10        Proxy Binders:       18
///        Parcel memory:        6         Parcel count:       24
///     Death Recipients:        0      OpenSSL Sockets:        0
///             WebViews:        0
///
///  SQL
///          MEMORY_USED:        0
///   PAGECACHE_OVERFLOW:        0          MALLOC_SIZE:        0
/// ...
///
/// For more information, see https://developer.android.com/studio/command-line/dumpsys.
@visibleForTesting
AndroidMemoryInfo parseMeminfoDump(String input) {
  final AndroidMemoryInfo androidMemoryInfo = AndroidMemoryInfo();

  final List<String> lines = input.split('\n');

  final String timelineData = lines.firstWhere((String line) =>
    line.startsWith('${AndroidMemoryInfo._kUpTimeKey}: '));
  final List<String> times = timelineData.trim().split('${AndroidMemoryInfo._kRealTimeKey}:');
  androidMemoryInfo.realTime = int.tryParse(times.last.trim()) ?? 0;

  lines
    .skipWhile((String line) => !line.contains('App Summary'))
    .takeWhile((String line) => !line.contains('TOTAL'))
    .where((String line) => line.contains(':'))
    .forEach((String line) {
      final List<String> sections = line.trim().split(':');
      final String key = sections.first.trim();
      final int value = int.tryParse(sections.last.trim()) ?? 0;
      switch (key) {
        case AndroidMemoryInfo._kJavaHeapKey:
          androidMemoryInfo.javaHeap = value;
          break;
        case AndroidMemoryInfo._kNativeHeapKey:
          androidMemoryInfo.nativeHeap = value;
          break;
        case AndroidMemoryInfo._kCodeKey:
          androidMemoryInfo.code = value;
          break;
        case AndroidMemoryInfo._kStackKey:
          androidMemoryInfo.stack = value;
          break;
        case AndroidMemoryInfo._kGraphicsKey:
          androidMemoryInfo.graphics = value;
          break;
        case AndroidMemoryInfo._kPrivateOtherKey:
          androidMemoryInfo.privateOther = value;
          break;
        case AndroidMemoryInfo._kSystemKey:
          androidMemoryInfo.system = value;
          break;
      }
  });
  return androidMemoryInfo;
}

/// Return the list of connected ADB devices.
List<AndroidDevice> getAdbDevices() {
  final String adbPath = getAdbPath(androidSdk);
  if (adbPath == null) {
    return <AndroidDevice>[];
  }
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

/// Android specific implementation of memory info.
class AndroidMemoryInfo extends MemoryInfo {
  static const String _kUpTimeKey = 'Uptime';
  static const String _kRealTimeKey = 'Realtime';
  static const String _kJavaHeapKey = 'Java Heap';
  static const String _kNativeHeapKey = 'Native Heap';
  static const String _kCodeKey = 'Code';
  static const String _kStackKey = 'Stack';
  static const String _kGraphicsKey = 'Graphics';
  static const String _kPrivateOtherKey = 'Private Other';
  static const String _kSystemKey = 'System';
  static const String _kTotalKey = 'Total';

  // Realtime is time since the system was booted includes deep sleep. Clock
  // is monotonic, and ticks even when the CPU is in power saving modes.
  int realTime = 0;

  // Each measurement has KB as a unit.
  int javaHeap = 0;
  int nativeHeap = 0;
  int code = 0;
  int stack = 0;
  int graphics = 0;
  int privateOther = 0;
  int system = 0;

  @override
  Map<String, Object> toJson() {
    return <String, Object>{
      'platform': 'Android',
      _kRealTimeKey: realTime,
      _kJavaHeapKey: javaHeap,
      _kNativeHeapKey: nativeHeap,
      _kCodeKey: code,
      _kStackKey: stack,
      _kGraphicsKey: graphics,
      _kPrivateOtherKey: privateOther,
      _kSystemKey: system,
      _kTotalKey: javaHeap + nativeHeap + code + stack + graphics + privateOther + system,
    };
  }
}

/// Get diagnostics about issues with any connected devices.
Future<List<String>> getAdbDeviceDiagnostics() async {
  final String adbPath = getAdbPath(androidSdk);
  if (adbPath == null) {
    return <String>[];
  }

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

  for (final String line in text.trim().split('\n')) {
    // Skip lines like: * daemon started successfully *
    if (line.startsWith('* daemon ')) {
      continue;
    }

    // Skip lines about adb server and client version not matching
    if (line.startsWith(RegExp(r'adb server (version|is out of date)'))) {
      diagnostics?.add(line);
      continue;
    }

    if (line.startsWith('List of devices')) {
      continue;
    }

    if (_kDeviceRegex.hasMatch(line)) {
      final Match match = _kDeviceRegex.firstMatch(line);

      final String deviceID = match[1];
      final String deviceState = match[2];
      String rest = match[3];

      final Map<String, String> info = <String, String>{};
      if (rest != null && rest.isNotEmpty) {
        rest = rest.trim();
        for (final String data in rest.split(' ')) {
          if (data.contains(':')) {
            final List<String> fields = data.split(':');
            info[fields[0]] = fields[1];
          }
        }
      }

      if (info['model'] != null) {
        info['model'] = cleanAdbDeviceName(info['model']);
      }

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

  Future<void> _start() async {
    final String lastTimestamp = device.lastLogcatTimestamp;
    // Start the adb logcat process and filter the most recent logs since `lastTimestamp`.
    final List<String> args = <String>[
      'logcat',
      '-v',
      'time',
    ];
    // logcat -T is not supported on Android releases before Lollipop.
    const int kLollipopVersionCode = 21;
    final int apiVersion = (String v) {
      // If the API version string isn't found, conservatively assume that the
      // version is less recent than the one we're looking for.
      return v == null ? kLollipopVersionCode - 1 : int.tryParse(v);
    }(await device._apiVersion);
    if (apiVersion != null && apiVersion >= kLollipopVersionCode) {
      args.addAll(<String>[
        '-T',
        lastTimestamp ?? '', // Empty `-T` means the timestamp of the logcat command invocation.
      ]);
    }

    _process = await processUtils.start(device.adbCommandForDevice(args));

    // We expect logcat streams to occasionally contain invalid utf-8,
    // see: https://github.com/flutter/flutter/pull/8864.
    const Utf8Decoder decoder = Utf8Decoder(reportErrors: false);
    _process.stdout.transform<String>(decoder).transform<String>(const LineSplitter()).listen(_onLine);
    _process.stderr.transform<String>(decoder).transform<String>(const LineSplitter()).listen(_onLine);
    unawaited(_process.exitCode.whenComplete(() {
      if (_linesController.hasListener) {
        _linesController.close();
      }
    }));
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
    if (timeMatch == null || line.length == timeMatch.end) {
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
    _process?.kill();
  }

  @override
  void dispose() {
    _stop();
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
      globals.printError('Failed to list forwarded ports: $error.');
      return ports;
    }

    final List<String> lines = LineSplitter.split(stdout).toList();
    for (final String line in lines) {
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

  @override
  Future<void> dispose() async {
    for (final ForwardedPort port in forwardedPorts) {
      await unforward(port);
    }
  }
}
