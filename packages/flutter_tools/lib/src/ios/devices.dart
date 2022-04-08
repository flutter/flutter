// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../convert.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../globals.dart' as globals;
import '../macos/xcdevice.dart';
import '../project.dart';
import '../protocol_discovery.dart';
import '../vmservice.dart';
import 'application_package.dart';
import 'ios_deploy.dart';
import 'ios_workflow.dart';
import 'iproxy.dart';
import 'mac.dart';

class IOSDevices extends PollingDeviceDiscovery {
  IOSDevices({
    required Platform platform,
    required XCDevice xcdevice,
    required IOSWorkflow iosWorkflow,
    required Logger logger,
  }) : _platform = platform,
       _xcdevice = xcdevice,
       _iosWorkflow = iosWorkflow,
       _logger = logger,
       super('iOS devices');

  final Platform _platform;
  final XCDevice _xcdevice;
  final IOSWorkflow _iosWorkflow;
  final Logger _logger;

  @override
  bool get supportsPlatform => _platform.isMacOS;

  @override
  bool get canListAnything => _iosWorkflow.canListDevices;

  StreamSubscription<Map<XCDeviceEvent, String>>? _observedDeviceEventsSubscription;

  @override
  Future<void> startPolling() async {
    if (!_platform.isMacOS) {
      throw UnsupportedError(
        'Control of iOS devices or simulators only supported on macOS.'
      );
    }
    if (!_xcdevice.isInstalled) {
      return;
    }

    deviceNotifier ??= ItemListNotifier<Device>();

    // Start by populating all currently attached devices.
    deviceNotifier!.updateWithNewList(await pollingGetDevices());

    // cancel any outstanding subscriptions.
    await _observedDeviceEventsSubscription?.cancel();
    _observedDeviceEventsSubscription = _xcdevice.observedDeviceEvents()?.listen(
      _onDeviceEvent,
      onError: (Object error, StackTrace stack) {
        _logger.printTrace('Process exception running xcdevice observe:\n$error\n$stack');
      }, onDone: () {
        // If xcdevice is killed or otherwise dies, polling will be stopped.
        // No retry is attempted and the polling client will have to restart polling
        // (restart the IDE). Avoid hammering on a process that is
        // continuously failing.
        _logger.printTrace('xcdevice observe stopped');
      },
      cancelOnError: true,
    );
  }

  Future<void> _onDeviceEvent(Map<XCDeviceEvent, String> event) async {
    final XCDeviceEvent eventType = event.containsKey(XCDeviceEvent.attach) ? XCDeviceEvent.attach : XCDeviceEvent.detach;
    final String? deviceIdentifier = event[eventType];
    final ItemListNotifier<Device>? notifier = deviceNotifier;
    if (notifier == null) {
      return;
    }
    Device? knownDevice;
    for (final Device device in notifier.items) {
      if (device.id == deviceIdentifier) {
        knownDevice = device;
      }
    }

    // Ignore already discovered devices (maybe populated at the beginning).
    if (eventType == XCDeviceEvent.attach && knownDevice == null) {
      // There's no way to get details for an individual attached device,
      // so repopulate them all.
      final List<Device> devices = await pollingGetDevices();
      notifier.updateWithNewList(devices);
    } else if (eventType == XCDeviceEvent.detach && knownDevice != null) {
      notifier.removeItem(knownDevice);
    }
  }

  @override
  Future<void> stopPolling() async {
    await _observedDeviceEventsSubscription?.cancel();
  }

  @override
  Future<List<Device>> pollingGetDevices({ Duration? timeout }) async {
    if (!_platform.isMacOS) {
      throw UnsupportedError(
        'Control of iOS devices or simulators only supported on macOS.'
      );
    }

    return _xcdevice.getAvailableIOSDevices(timeout: timeout);
  }

  @override
  Future<List<String>> getDiagnostics() async {
    if (!_platform.isMacOS) {
      return const <String>[
        'Control of iOS devices or simulators only supported on macOS.'
      ];
    }

    return _xcdevice.getDiagnostics();
  }

  @override
  List<String> get wellKnownIds => const <String>[];
}

class IOSDevice extends Device {
  IOSDevice(super.id, {
    required FileSystem fileSystem,
    required this.name,
    required this.cpuArchitecture,
    required this.interfaceType,
    String? sdkVersion,
    required Platform platform,
    required IOSDeploy iosDeploy,
    required IMobileDevice iMobileDevice,
    required IProxy iProxy,
    required Logger logger,
  })
    : _sdkVersion = sdkVersion,
      _iosDeploy = iosDeploy,
      _iMobileDevice = iMobileDevice,
      _iproxy = iProxy,
      _fileSystem = fileSystem,
      _logger = logger,
      _platform = platform,
        super(
          category: Category.mobile,
          platformType: PlatformType.ios,
          ephemeral: true,
      ) {
    if (!_platform.isMacOS) {
      assert(false, 'Control of iOS devices or simulators only supported on Mac OS.');
      return;
    }
  }

  final String? _sdkVersion;
  final IOSDeploy _iosDeploy;
  final FileSystem _fileSystem;
  final Logger _logger;
  final Platform _platform;
  final IMobileDevice _iMobileDevice;
  final IProxy _iproxy;

  /// May be 0 if version cannot be parsed.
  int get majorSdkVersion {
    final String? majorVersionString = _sdkVersion?.split('.').first.trim();
    return majorVersionString != null ? int.tryParse(majorVersionString) ?? 0 : 0;
  }

  @override
  bool get supportsHotReload => interfaceType == IOSDeviceConnectionInterface.usb;

  @override
  bool get supportsHotRestart => interfaceType == IOSDeviceConnectionInterface.usb;

  @override
  bool get supportsFlutterExit => interfaceType == IOSDeviceConnectionInterface.usb;

  @override
  final String name;

  @override
  bool supportsRuntimeMode(BuildMode buildMode) => buildMode != BuildMode.jitRelease;

  final DarwinArch cpuArchitecture;

  final IOSDeviceConnectionInterface interfaceType;

  final Map<IOSApp?, DeviceLogReader> _logReaders = <IOSApp?, DeviceLogReader>{};

  DevicePortForwarder? _portForwarder;

  @visibleForTesting
  IOSDeployDebugger? iosDeployDebugger;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String?> get emulatorId async => null;

  @override
  bool get supportsStartPaused => false;

  @override
  Future<bool> isAppInstalled(
    IOSApp app, {
    String? userIdentifier,
  }) async {
    bool result;
    try {
      result = await _iosDeploy.isAppInstalled(
        bundleId: app.id,
        deviceId: id,
      );
    } on ProcessException catch (e) {
      _logger.printError(e.message);
      return false;
    }
    return result;
  }

  @override
  Future<bool> isLatestBuildInstalled(IOSApp app) async => false;

  @override
  Future<bool> installApp(
    IOSApp app, {
    String? userIdentifier,
  }) async {
    final Directory bundle = _fileSystem.directory(app.deviceBundlePath);
    if (!bundle.existsSync()) {
      _logger.printError('Could not find application bundle at ${bundle.path}; have you run "flutter build ios"?');
      return false;
    }

    int installationResult;
    try {
      installationResult = await _iosDeploy.installApp(
        deviceId: id,
        bundlePath: bundle.path,
        appDeltaDirectory: app.appDeltaDirectory,
        launchArguments: <String>[],
        interfaceType: interfaceType,
      );
    } on ProcessException catch (e) {
      _logger.printError(e.message);
      return false;
    }
    if (installationResult != 0) {
      _logger.printError('Could not install ${bundle.path} on $id.');
      _logger.printError('Try launching Xcode and selecting "Product > Run" to fix the problem:');
      _logger.printError('  open ios/Runner.xcworkspace');
      _logger.printError('');
      return false;
    }
    return true;
  }

  @override
  Future<bool> uninstallApp(
    IOSApp app, {
    String? userIdentifier,
  }) async {
    int uninstallationResult;
    try {
      uninstallationResult = await _iosDeploy.uninstallApp(
        deviceId: id,
        bundleId: app.id,
      );
    } on ProcessException catch (e) {
      _logger.printError(e.message);
      return false;
    }
    if (uninstallationResult != 0) {
      _logger.printError('Could not uninstall ${app.id} on $id.');
      return false;
    }
    return true;
  }

  @override
  bool isSupported() => true;

  @override
  Future<LaunchResult> startApp(
    IOSApp package, {
    String? mainPath,
    String? route,
    required DebuggingOptions debuggingOptions,
    Map<String, Object?> platformArgs = const <String, Object?>{},
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String? userIdentifier,
    @visibleForTesting Duration? discoveryTimeout,
  }) async {
    String? packageId;

    if (!prebuiltApplication) {
      _logger.printTrace('Building ${package.name} for $id');

      // Step 1: Build the precompiled/DBC application if necessary.
      final XcodeBuildResult buildResult = await buildXcodeProject(
          app: package as BuildableIOSApp,
          buildInfo: debuggingOptions.buildInfo,
          targetOverride: mainPath,
          activeArch: cpuArchitecture,
          deviceID: id,
      );
      if (!buildResult.success) {
        _logger.printError('Could not build the precompiled application for the device.');
        await diagnoseXcodeBuildFailure(buildResult, globals.flutterUsage, _logger);
        _logger.printError('');
        return LaunchResult.failed();
      }
      packageId = buildResult.xcodeBuildExecution?.buildSettings['PRODUCT_BUNDLE_IDENTIFIER'];
    }

    packageId ??= package.id;

    // Step 2: Check that the application exists at the specified path.
    final Directory bundle = _fileSystem.directory(package.deviceBundlePath);
    if (!bundle.existsSync()) {
      _logger.printError('Could not find the built application bundle at ${bundle.path}.');
      return LaunchResult.failed();
    }

    // Step 3: Attempt to install the application on the device.
    final String dartVmFlags = computeDartVmFlags(debuggingOptions);
    final List<String> launchArguments = <String>[
      '--enable-dart-profiling',
      '--disable-service-auth-codes',
      if (debuggingOptions.disablePortPublication) '--disable-observatory-publication',
      if (debuggingOptions.startPaused) '--start-paused',
      if (dartVmFlags.isNotEmpty) '--dart-flags="$dartVmFlags"',
      if (debuggingOptions.useTestFonts) '--use-test-fonts',
      if (debuggingOptions.debuggingEnabled) ...<String>[
        '--enable-checked-mode',
        '--verify-entry-points',
      ],
      if (debuggingOptions.enableSoftwareRendering) '--enable-software-rendering',
      if (debuggingOptions.skiaDeterministicRendering) '--skia-deterministic-rendering',
      if (debuggingOptions.traceSkia) '--trace-skia',
      if (debuggingOptions.traceAllowlist != null) '--trace-allowlist="${debuggingOptions.traceAllowlist}"',
      if (debuggingOptions.traceSkiaAllowlist != null) '--trace-skia-allowlist="${debuggingOptions.traceSkiaAllowlist}"',
      if (debuggingOptions.endlessTraceBuffer) '--endless-trace-buffer',
      if (debuggingOptions.dumpSkpOnShaderCompilation) '--dump-skp-on-shader-compilation',
      if (debuggingOptions.verboseSystemLogs) '--verbose-logging',
      if (debuggingOptions.cacheSkSL) '--cache-sksl',
      if (debuggingOptions.purgePersistentCache) '--purge-persistent-cache',
      if (route != null) '--route=$route',
      if (platformArgs['trace-startup'] as bool? ?? false) '--trace-startup',
      if (debuggingOptions.enableImpeller) '--enable-impeller',
    ];

    final Status installStatus = _logger.startProgress(
      'Installing and launching...',
    );
    try {
      ProtocolDiscovery? observatoryDiscovery;
      int installationResult = 1;
      if (debuggingOptions.debuggingEnabled) {
        _logger.printTrace('Debugging is enabled, connecting to observatory');
        final DeviceLogReader deviceLogReader = getLogReader(app: package);

        // If the device supports syslog reading, prefer launching the app without
        // attaching the debugger to avoid the overhead of the unnecessary extra running process.
        if (majorSdkVersion >= IOSDeviceLogReader.minimumUniversalLoggingSdkVersion) {
          iosDeployDebugger = _iosDeploy.prepareDebuggerForLaunch(
            deviceId: id,
            bundlePath: bundle.path,
            appDeltaDirectory: package.appDeltaDirectory,
            launchArguments: launchArguments,
            interfaceType: interfaceType,
          );
          if (deviceLogReader is IOSDeviceLogReader) {
            deviceLogReader.debuggerStream = iosDeployDebugger;
          }
        }
        observatoryDiscovery = ProtocolDiscovery.observatory(
          deviceLogReader,
          portForwarder: portForwarder,
          hostPort: debuggingOptions.hostVmServicePort,
          devicePort: debuggingOptions.deviceVmServicePort,
          ipv6: ipv6,
          logger: _logger,
        );
      }
      if (iosDeployDebugger == null) {
        installationResult = await _iosDeploy.launchApp(
          deviceId: id,
          bundlePath: bundle.path,
          appDeltaDirectory: package.appDeltaDirectory,
          launchArguments: launchArguments,
          interfaceType: interfaceType,
        );
      } else {
        installationResult = await iosDeployDebugger!.launchAndAttach() ? 0 : 1;
      }
      if (installationResult != 0) {
        _logger.printError('Could not run ${bundle.path} on $id.');
        _logger.printError('Try launching Xcode and selecting "Product > Run" to fix the problem:');
        _logger.printError('  open ios/Runner.xcworkspace');
        _logger.printError('');
        return LaunchResult.failed();
      }

      if (!debuggingOptions.debuggingEnabled) {
        return LaunchResult.succeeded();
      }

      _logger.printTrace('Application launched on the device. Waiting for observatory url.');
      final Timer timer = Timer(discoveryTimeout ?? const Duration(seconds: 30), () {
        _logger.printError('iOS Observatory not discovered after 30 seconds. This is taking much longer than expected...');
      });
      final Uri? localUri = await observatoryDiscovery?.uri;
      timer.cancel();
      if (localUri == null) {
        await iosDeployDebugger?.stopAndDumpBacktrace();
        return LaunchResult.failed();
      }
      return LaunchResult.succeeded(observatoryUri: localUri);
    } on ProcessException catch (e) {
      await iosDeployDebugger?.stopAndDumpBacktrace();
      _logger.printError(e.message);
      return LaunchResult.failed();
    } finally {
      installStatus.stop();
    }
  }

  @override
  Future<bool> stopApp(
    IOSApp app, {
    String? userIdentifier,
  }) async {
    // If the debugger is not attached, killing the ios-deploy process won't stop the app.
    final IOSDeployDebugger? deployDebugger = iosDeployDebugger;
    if (deployDebugger != null && deployDebugger.debuggerAttached) {
      return deployDebugger.exit() == true;
    }
    return false;
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  Future<String> get sdkNameAndVersion async => 'iOS ${_sdkVersion ?? 'unknown version'}';

  @override
  DeviceLogReader getLogReader({
    IOSApp? app,
    bool includePastLogs = false,
  }) {
    assert(!includePastLogs, 'Past log reading not supported on iOS devices.');
    return _logReaders.putIfAbsent(app, () => IOSDeviceLogReader.create(
      device: this,
      app: app,
      iMobileDevice: _iMobileDevice,
    ));
  }

  @visibleForTesting
  void setLogReader(IOSApp app, DeviceLogReader logReader) {
    _logReaders[app] = logReader;
  }

  @override
  DevicePortForwarder get portForwarder => _portForwarder ??= IOSDevicePortForwarder(
    logger: _logger,
    iproxy: _iproxy,
    id: id,
    operatingSystemUtils: globals.os,
  );

  @visibleForTesting
  set portForwarder(DevicePortForwarder forwarder) {
    _portForwarder = forwarder;
  }

  @override
  void clearLogs() { }

  @override
  bool get supportsScreenshot => _iMobileDevice.isInstalled;

  @override
  Future<void> takeScreenshot(File outputFile) async {
    await _iMobileDevice.takeScreenshot(outputFile, id, interfaceType);
  }

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.ios.existsSync();
  }

  @override
  Future<void> dispose() async {
    for (final DeviceLogReader logReader in _logReaders.values) {
      logReader.dispose();
    }
    _logReaders.clear();
    await _portForwarder?.dispose();
  }
}

/// Decodes a vis-encoded syslog string to a UTF-8 representation.
///
/// Apple's syslog logs are encoded in 7-bit form. Input bytes are encoded as follows:
/// 1. 0x00 to 0x19: non-printing range. Some ignored, some encoded as <...>.
/// 2. 0x20 to 0x7f: as-is, with the exception of 0x5c (backslash).
/// 3. 0x5c (backslash): octal representation \134.
/// 4. 0x80 to 0x9f: \M^x (using control-character notation for range 0x00 to 0x40).
/// 5. 0xa0: octal representation \240.
/// 6. 0xa1 to 0xf7: \M-x (where x is the input byte stripped of its high-order bit).
/// 7. 0xf8 to 0xff: unused in 4-byte UTF-8.
///
/// See: [vis(3) manpage](https://www.freebsd.org/cgi/man.cgi?query=vis&sektion=3)
String decodeSyslog(String line) {
  // UTF-8 values for \, M, -, ^.
  const int kBackslash = 0x5c;
  const int kM = 0x4d;
  const int kDash = 0x2d;
  const int kCaret = 0x5e;

  // Mask for the UTF-8 digit range.
  const int kNum = 0x30;

  // Returns true when `byte` is within the UTF-8 7-bit digit range (0x30 to 0x39).
  bool isDigit(int byte) => (byte & 0xf0) == kNum;

  // Converts a three-digit ASCII (UTF-8) representation of an octal number `xyz` to an integer.
  int decodeOctal(int x, int y, int z) => (x & 0x3) << 6 | (y & 0x7) << 3 | z & 0x7;

  try {
    final List<int> bytes = utf8.encode(line);
    final List<int> out = <int>[];
    for (int i = 0; i < bytes.length;) {
      if (bytes[i] != kBackslash || i > bytes.length - 4) {
        // Unmapped byte: copy as-is.
        out.add(bytes[i++]);
      } else {
        // Mapped byte: decode next 4 bytes.
        if (bytes[i + 1] == kM && bytes[i + 2] == kCaret) {
          // \M^x form: bytes in range 0x80 to 0x9f.
          out.add((bytes[i + 3] & 0x7f) + 0x40);
        } else if (bytes[i + 1] == kM && bytes[i + 2] == kDash) {
          // \M-x form: bytes in range 0xa0 to 0xf7.
          out.add(bytes[i + 3] | 0x80);
        } else if (bytes.getRange(i + 1, i + 3).every(isDigit)) {
          // \ddd form: octal representation (only used for \134 and \240).
          out.add(decodeOctal(bytes[i + 1], bytes[i + 2], bytes[i + 3]));
        } else {
          // Unknown form: copy as-is.
          out.addAll(bytes.getRange(0, 4));
        }
        i += 4;
      }
    }
    return utf8.decode(out);
  } on Exception {
    // Unable to decode line: return as-is.
    return line;
  }
}

@visibleForTesting
class IOSDeviceLogReader extends DeviceLogReader {
  IOSDeviceLogReader._(
    this._iMobileDevice,
    this._majorSdkVersion,
    this._deviceId,
    this.name,
    String appName,
  ) : // Match for lines for the runner in syslog.
      //
      // iOS 9 format:  Runner[297] <Notice>:
      // iOS 10 format: Runner(Flutter)[297] <Notice>:
      _runnerLineRegex = RegExp(appName + r'(\(Flutter\))?\[[\d]+\] <[A-Za-z]+>: ');

  /// Create a new [IOSDeviceLogReader].
  factory IOSDeviceLogReader.create({
    required IOSDevice device,
    IOSApp? app,
    required IMobileDevice iMobileDevice,
  }) {
    final String appName = app?.name?.replaceAll('.app', '') ?? '';
    return IOSDeviceLogReader._(
      iMobileDevice,
      device.majorSdkVersion,
      device.id,
      device.name,
      appName,
    );
  }

  /// Create an [IOSDeviceLogReader] for testing.
  factory IOSDeviceLogReader.test({
    required IMobileDevice iMobileDevice,
    bool useSyslog = true,
  }) {
    return IOSDeviceLogReader._(
      iMobileDevice, useSyslog ? 12 : 13, '1234', 'test', 'Runner');
  }

  @override
  final String name;
  final int _majorSdkVersion;
  final String _deviceId;
  final IMobileDevice _iMobileDevice;

  // Matches a syslog line from the runner.
  RegExp _runnerLineRegex;

  // Similar to above, but allows ~arbitrary components instead of "Runner"
  // and "Flutter". The regex tries to strike a balance between not producing
  // false positives and not producing false negatives.
  final RegExp _anyLineRegex = RegExp(r'\w+(\([^)]*\))?\[\d+\] <[A-Za-z]+>: ');

  // Logging from native code/Flutter engine is prefixed by timestamp and process metadata:
  // 2020-09-15 19:15:10.931434-0700 Runner[541:226276] Did finish launching.
  // 2020-09-15 19:15:10.931434-0700 Runner[541:226276] [Category] Did finish launching.
  //
  // Logging from the dart code has no prefixing metadata.
  final RegExp _debuggerLoggingRegex = RegExp(r'^\S* \S* \S*\[[0-9:]*] (.*)');

  @visibleForTesting
  late final StreamController<String> linesController = StreamController<String>.broadcast(
    onListen: _listenToSysLog,
    onCancel: dispose,
  );

  // Sometimes (race condition?) we try to send a log after the controller has
  // been closed. See https://github.com/flutter/flutter/issues/99021 for more
  // context.
  void _addToLinesController(String message) {
    if (!linesController.isClosed) {
      linesController.add(message);
    }
  }

  final List<StreamSubscription<void>> _loggingSubscriptions = <StreamSubscription<void>>[];

  @override
  Stream<String> get logLines => linesController.stream;

  @override
  FlutterVmService? get connectedVMService => _connectedVMService;
  FlutterVmService? _connectedVMService;

  @override
  set connectedVMService(FlutterVmService? connectedVmService) {
    if (connectedVmService != null) {
      _listenToUnifiedLoggingEvents(connectedVmService);
    }
    _connectedVMService = connectedVmService;
  }

  static const int minimumUniversalLoggingSdkVersion = 13;

  Future<void> _listenToUnifiedLoggingEvents(FlutterVmService connectedVmService) async {
    if (_majorSdkVersion < minimumUniversalLoggingSdkVersion) {
      return;
    }
    try {
      // The VM service will not publish logging events unless the debug stream is being listened to.
      // Listen to this stream as a side effect.
      unawaited(connectedVmService.service.streamListen('Debug'));

      await Future.wait(<Future<void>>[
        connectedVmService.service.streamListen(vm_service.EventStreams.kStdout),
        connectedVmService.service.streamListen(vm_service.EventStreams.kStderr),
      ]);
    } on vm_service.RPCError {
      // Do nothing, since the tool is already subscribed.
    }

    void logMessage(vm_service.Event event) {
      if (_iosDeployDebugger != null && _iosDeployDebugger!.debuggerAttached) {
        // Prefer the more complete logs from the  attached debugger.
        return;
      }
      final String message = processVmServiceMessage(event);
      if (message.isNotEmpty) {
        _addToLinesController(message);
      }
    }

    _loggingSubscriptions.addAll(<StreamSubscription<void>>[
      connectedVmService.service.onStdoutEvent.listen(logMessage),
      connectedVmService.service.onStderrEvent.listen(logMessage),
    ]);
  }

  /// Log reader will listen to [debugger.logLines] and will detach debugger on dispose.
  IOSDeployDebugger? get debuggerStream => _iosDeployDebugger;
  set debuggerStream(IOSDeployDebugger? debugger) {
    // Logging is gathered from syslog on iOS 13 and earlier.
    if (_majorSdkVersion < minimumUniversalLoggingSdkVersion) {
      return;
    }
    _iosDeployDebugger = debugger;
    if (debugger == null) {
      return;
    }
    // Add the debugger logs to the controller created on initialization.
    _loggingSubscriptions.add(debugger.logLines.listen(
      (String line) => _addToLinesController(_debuggerLineHandler(line)),
      onError: linesController.addError,
      onDone: linesController.close,
      cancelOnError: true,
    ));
  }
  IOSDeployDebugger? _iosDeployDebugger;

  // Strip off the logging metadata (leave the category), or just echo the line.
  String _debuggerLineHandler(String line) => _debuggerLoggingRegex.firstMatch(line)?.group(1) ?? line;

  void _listenToSysLog() {
    // syslog is not written on iOS 13+.
    if (_majorSdkVersion >= minimumUniversalLoggingSdkVersion) {
      return;
    }
    _iMobileDevice.startLogger(_deviceId).then<void>((Process process) {
      process.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen(_newSyslogLineHandler());
      process.stderr.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen(_newSyslogLineHandler());
      process.exitCode.whenComplete(() {
        if (linesController.hasListener) {
          linesController.close();
        }
      });
      assert(idevicesyslogProcess == null);
      idevicesyslogProcess = process;
    });
  }

  @visibleForTesting
  Process? idevicesyslogProcess;

  // Returns a stateful line handler to properly capture multiline output.
  //
  // For multiline log messages, any line after the first is logged without
  // any specific prefix. To properly capture those, we enter "printing" mode
  // after matching a log line from the runner. When in printing mode, we print
  // all lines until we find the start of another log message (from any app).
  void Function(String line) _newSyslogLineHandler() {
    bool printing = false;

    return (String line) {
      if (printing) {
        if (!_anyLineRegex.hasMatch(line)) {
          _addToLinesController(decodeSyslog(line));
          return;
        }

        printing = false;
      }

      final Match? match = _runnerLineRegex.firstMatch(line);

      if (match != null) {
        final String logLine = line.substring(match.end);
        // Only display the log line after the initial device and executable information.
        _addToLinesController(decodeSyslog(logLine));

        printing = true;
      }
    };
  }

  @override
  void dispose() {
    for (final StreamSubscription<void> loggingSubscription in _loggingSubscriptions) {
      loggingSubscription.cancel();
    }
    idevicesyslogProcess?.kill();
    _iosDeployDebugger?.detach();
  }
}

/// A [DevicePortForwarder] specialized for iOS usage with iproxy.
class IOSDevicePortForwarder extends DevicePortForwarder {

  /// Create a new [IOSDevicePortForwarder].
  IOSDevicePortForwarder({
    required Logger logger,
    required String id,
    required IProxy iproxy,
    required OperatingSystemUtils operatingSystemUtils,
  }) : _logger = logger,
       _id = id,
       _iproxy = iproxy,
       _operatingSystemUtils = operatingSystemUtils;

  /// Create a [IOSDevicePortForwarder] for testing.
  ///
  /// This specifies the path to iproxy as 'iproxy` and the dyLdLibEntry as
  /// 'DYLD_LIBRARY_PATH: /path/to/libs'.
  ///
  /// The device id may be provided, but otherwise defaults to '1234'.
  factory IOSDevicePortForwarder.test({
    required ProcessManager processManager,
    required Logger logger,
    String? id,
    required OperatingSystemUtils operatingSystemUtils,
  }) {
    return IOSDevicePortForwarder(
      logger: logger,
      iproxy: IProxy.test(
        logger: logger,
        processManager: processManager,
      ),
      id: id ?? '1234',
      operatingSystemUtils: operatingSystemUtils,
    );
  }

  final Logger _logger;
  final String _id;
  final IProxy _iproxy;
  final OperatingSystemUtils _operatingSystemUtils;

  @override
  List<ForwardedPort> forwardedPorts = <ForwardedPort>[];

  @visibleForTesting
  void addForwardedPorts(List<ForwardedPort> ports) {
    ports.forEach(forwardedPorts.add);
  }

  static const Duration _kiProxyPortForwardTimeout = Duration(seconds: 1);

  @override
  Future<int> forward(int devicePort, { int? hostPort }) async {
    final bool autoselect = hostPort == null || hostPort == 0;
    if (autoselect) {
      final int freePort = await _operatingSystemUtils.findFreePort();
      // Dynamic port range 49152 - 65535.
      hostPort = freePort == 0 ? 49152 : freePort;
    }

    Process? process;

    bool connected = false;
    while (!connected) {
      _logger.printTrace('Attempting to forward device port $devicePort to host port $hostPort');
      process = await _iproxy.forward(devicePort, hostPort!, _id);
      // TODO(ianh): This is a flaky race condition, https://github.com/libimobiledevice/libimobiledevice/issues/674
      connected = !await process.stdout.isEmpty.timeout(_kiProxyPortForwardTimeout, onTimeout: () => false);
      if (!connected) {
        process.kill();
        if (autoselect) {
          hostPort += 1;
          if (hostPort > 65535) {
            throw Exception('Could not find open port on host.');
          }
        } else {
          throw Exception('Port $hostPort is not available.');
        }
      }
    }
    assert(connected);
    assert(process != null);

    final ForwardedPort forwardedPort = ForwardedPort.withContext(
      hostPort!, devicePort, process,
    );
    _logger.printTrace('Forwarded port $forwardedPort');
    forwardedPorts.add(forwardedPort);
    return hostPort;
  }

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async {
    if (!forwardedPorts.remove(forwardedPort)) {
      // Not in list. Nothing to remove.
      return;
    }

    _logger.printTrace('Un-forwarding port $forwardedPort');
    forwardedPort.dispose();
  }

  @override
  Future<void> dispose() async {
    for (final ForwardedPort forwardedPort in forwardedPorts) {
      forwardedPort.dispose();
    }
  }
}
