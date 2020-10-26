// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:vm_service/vm_service_io.dart' as vm_service_io;

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../ios/devices.dart';
import '../ios/ios_deploy.dart';
import '../ios/iproxy.dart';
import '../ios/mac.dart';
import '../ios/xcodeproj.dart';
import '../reporting/reporting.dart';

const int kXcodeRequiredVersionMajor = 11;
const int kXcodeRequiredVersionMinor = 0;
const int kXcodeRequiredVersionPatch = 0;

enum SdkType {
  iPhone,
  iPhoneSimulator,
  macOS,
}

/// SDK name passed to `xcrun --sdk`. Corresponds to undocumented Xcode
/// SUPPORTED_PLATFORMS values.
///
/// Usage: xcrun [options] <tool name> ... arguments ...
/// ...
/// --sdk <sdk name>            find the tool for the given SDK name.
String getNameForSdk(SdkType sdk) {
  switch (sdk) {
    case SdkType.iPhone:
      return 'iphoneos';
    case SdkType.iPhoneSimulator:
      return 'iphonesimulator';
    case SdkType.macOS:
      return 'macosx';
  }
  assert(false);
  return null;
}

/// A utility class for interacting with Xcode command line tools.
class Xcode {
  Xcode({
    @required Platform platform,
    @required ProcessManager processManager,
    @required Logger logger,
    @required FileSystem fileSystem,
    @required XcodeProjectInterpreter xcodeProjectInterpreter,
  })  : _platform = platform,
        _fileSystem = fileSystem,
        _xcodeProjectInterpreter = xcodeProjectInterpreter,
        _operatingSystemUtils = OperatingSystemUtils(
          fileSystem: fileSystem,
          logger: logger,
          platform: platform,
          processManager: processManager,
        ),
        _processUtils =
            ProcessUtils(logger: logger, processManager: processManager);

  final Platform _platform;
  final ProcessUtils _processUtils;
  final OperatingSystemUtils _operatingSystemUtils;
  final FileSystem _fileSystem;
  final XcodeProjectInterpreter _xcodeProjectInterpreter;

  bool get isInstalledAndMeetsVersionCheck => _platform.isMacOS && isInstalled && isVersionSatisfactory;

  String _xcodeSelectPath;
  String get xcodeSelectPath {
    if (_xcodeSelectPath == null) {
      try {
        _xcodeSelectPath = _processUtils.runSync(
          <String>['/usr/bin/xcode-select', '--print-path'],
        ).stdout.trim();
      } on ProcessException {
        // Ignored, return null below.
      } on ArgumentError {
        // Ignored, return null below.
      }
    }
    return _xcodeSelectPath;
  }

  bool get isInstalled {
    if (xcodeSelectPath == null || xcodeSelectPath.isEmpty) {
      return false;
    }
    return _xcodeProjectInterpreter.isInstalled;
  }

  int get majorVersion => _xcodeProjectInterpreter.majorVersion;
  int get minorVersion => _xcodeProjectInterpreter.minorVersion;
  int get patchVersion => _xcodeProjectInterpreter.patchVersion;

  String get versionText => _xcodeProjectInterpreter.versionText;

  bool _eulaSigned;
  /// Has the EULA been signed?
  bool get eulaSigned {
    if (_eulaSigned == null) {
      try {
        final RunResult result = _processUtils.runSync(
          <String>[...xcrunCommand(), 'clang'],
        );
        if (result.stdout != null && result.stdout.contains('license')) {
          _eulaSigned = false;
        } else if (result.stderr != null && result.stderr.contains('license')) {
          _eulaSigned = false;
        } else {
          _eulaSigned = true;
        }
      } on ProcessException {
        _eulaSigned = false;
      }
    }
    return _eulaSigned;
  }

  bool _isSimctlInstalled;

  /// Verifies that simctl is installed by trying to run it.
  bool get isSimctlInstalled {
    if (_isSimctlInstalled == null) {
      try {
        // This command will error if additional components need to be installed in
        // xcode 9.2 and above.
        final RunResult result = _processUtils.runSync(
          <String>[...xcrunCommand(), 'simctl', 'list'],
        );
        _isSimctlInstalled = result.stderr == null || result.stderr == '';
      } on ProcessException {
        _isSimctlInstalled = false;
      }
    }
    return _isSimctlInstalled;
  }

  bool get isVersionSatisfactory {
    if (!_xcodeProjectInterpreter.isInstalled) {
      return false;
    }
    if (majorVersion > kXcodeRequiredVersionMajor) {
      return true;
    }
    if (majorVersion == kXcodeRequiredVersionMajor) {
      if (minorVersion == kXcodeRequiredVersionMinor) {
        return patchVersion >= kXcodeRequiredVersionPatch;
      }
      return minorVersion >= kXcodeRequiredVersionMinor;
    }
    return false;
  }

  /// The `xcrun` Xcode command to run or locate development
  /// tools and properties.
  ///
  /// Returns `xcrun` on x86 macOS.
  /// Returns `/usr/bin/arch -arm64e xcrun` on ARM macOS to force Xcode commands
  /// to run outside the x86 Rosetta translation, which may cause crashes.
  List<String> xcrunCommand() {
    final List<String> xcrunCommand = <String>[];
    if (_operatingSystemUtils.hostPlatform == HostPlatform.darwin_arm) {
      // Force Xcode commands to run outside Rosetta.
      xcrunCommand.addAll(<String>[
        '/usr/bin/arch',
        '-arm64e',
      ]);
    }
    xcrunCommand.add('xcrun');
    return xcrunCommand;
  }

  Future<RunResult> cc(List<String> args) {
    return _processUtils.run(
      <String>[...xcrunCommand(), 'cc', ...args],
      throwOnError: true,
    );
  }

  Future<RunResult> clang(List<String> args) {
    return _processUtils.run(
      <String>[...xcrunCommand(), 'clang', ...args],
      throwOnError: true,
    );
  }

  Future<String> sdkLocation(SdkType sdk) async {
    assert(sdk != null);
    final RunResult runResult = await _processUtils.run(
      <String>[...xcrunCommand(), '--sdk', getNameForSdk(sdk), '--show-sdk-path'],
    );
    if (runResult.exitCode != 0) {
      throwToolExit('Could not find SDK location: ${runResult.stderr}');
    }
    return runResult.stdout.trim();
  }

  String getSimulatorPath() {
    if (xcodeSelectPath == null) {
      return null;
    }
    final List<String> searchPaths = <String>[
      _fileSystem.path.join(xcodeSelectPath, 'Applications', 'Simulator.app'),
    ];
    return searchPaths.where((String p) => p != null).firstWhere(
      (String p) => _fileSystem.directory(p).existsSync(),
      orElse: () => null,
    );
  }
}

enum XCDeviceEvent {
  attach,
  detach,
}

/// A utility class for interacting with Xcode xcdevice command line tools.
class XCDevice {
  XCDevice({
    @required Artifacts artifacts,
    @required Cache cache,
    @required ProcessManager processManager,
    @required Logger logger,
    @required Xcode xcode,
    @required Platform platform,
    @required IProxy iproxy,
  }) : _processUtils = ProcessUtils(logger: logger, processManager: processManager),
      _logger = logger,
      _iMobileDevice = IMobileDevice(
        artifacts: artifacts,
        cache: cache,
        logger: logger,
        processManager: processManager,
      ),
      _iosDeploy = IOSDeploy(
        artifacts: artifacts,
        cache: cache,
        logger: logger,
        platform: platform,
        processManager: processManager,
      ),
      _iProxy = iproxy,
      _xcode = xcode {

    _setupDeviceIdentifierByEventStream();
  }

  void dispose() {
    _deviceObservationProcess?.kill();
  }

  final ProcessUtils _processUtils;
  final Logger _logger;
  final IMobileDevice _iMobileDevice;
  final IOSDeploy _iosDeploy;
  final Xcode _xcode;
  final IProxy _iProxy;

  List<dynamic> _cachedListResults;
  Process _deviceObservationProcess;
  StreamController<Map<XCDeviceEvent, String>> _deviceIdentifierByEvent;

  void _setupDeviceIdentifierByEventStream() {
    // _deviceIdentifierByEvent Should always be available for listeners
    // in case polling needs to be stopped and restarted.
    _deviceIdentifierByEvent = StreamController<Map<XCDeviceEvent, String>>.broadcast(
      onListen: _startObservingTetheredIOSDevices,
      onCancel: _stopObservingTetheredIOSDevices,
    );
  }

  bool get isInstalled => _xcode.isInstalledAndMeetsVersionCheck;

  Future<List<dynamic>> _getAllDevices({
    bool useCache = false,
    @required Duration timeout
  }) async {
    if (!isInstalled) {
      _logger.printTrace("Xcode not found. Run 'flutter doctor' for more information.");
      return null;
    }
    if (useCache && _cachedListResults != null) {
      return _cachedListResults;
    }
    try {
      // USB-tethered devices should be found quickly. 1 second timeout is faster than the default.
      final RunResult result = await _processUtils.run(
        <String>[
          ..._xcode.xcrunCommand(),
          'xcdevice',
          'list',
          '--timeout',
          timeout.inSeconds.toString(),
        ],
        throwOnError: true,
      );
      if (result.exitCode == 0) {
        final List<dynamic> listResults = json.decode(result.stdout) as List<dynamic>;
        _cachedListResults = listResults;
        return listResults;
      }
      _logger.printTrace('xcdevice returned an error:\n${result.stderr}');
    } on ProcessException catch (exception) {
      _logger.printTrace('Process exception running xcdevice list:\n$exception');
    } on ArgumentError catch (exception) {
      _logger.printTrace('Argument exception running xcdevice list:\n$exception');
    }

    return null;
  }

  /// Observe identifiers (UDIDs) of devices as they attach and detach.
  ///
  /// Each attach and detach event is a tuple of one event type
  /// and identifier.
  Stream<Map<XCDeviceEvent, String>> observedDeviceEvents() {
    if (!isInstalled) {
      _logger.printTrace("Xcode not found. Run 'flutter doctor' for more information.");
      return null;
    }
    return _deviceIdentifierByEvent.stream;
  }

  // Attach: d83d5bc53967baa0ee18626ba87b6254b2ab5418
  // Attach: 00008027-00192736010F802E
  // Detach: d83d5bc53967baa0ee18626ba87b6254b2ab5418
  final RegExp _observationIdentifierPattern = RegExp(r'^(\w*): ([\w-]*)$');

  Future<void> _startObservingTetheredIOSDevices() async {
    try {
      if (_deviceObservationProcess != null) {
        throw Exception('xcdevice observe restart failed');
      }

      // Run in interactive mode (via script) to convince
      // xcdevice it has a terminal attached in order to redirect stdout.
      _deviceObservationProcess = await _processUtils.start(
        <String>[
          'script',
          '-t',
          '0',
          '/dev/null',
          ..._xcode.xcrunCommand(),
          'xcdevice',
          'observe',
          '--both',
        ],
      );

      final StreamSubscription<String> stdoutSubscription = _deviceObservationProcess.stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {

        // xcdevice observe example output of UDIDs:
        //
        // Listening for all devices, on both interfaces.
        // Attach: d83d5bc53967baa0ee18626ba87b6254b2ab5418
        // Attach: 00008027-00192736010F802E
        // Detach: d83d5bc53967baa0ee18626ba87b6254b2ab5418
        // Attach: d83d5bc53967baa0ee18626ba87b6254b2ab5418
        final RegExpMatch match = _observationIdentifierPattern.firstMatch(line);
        if (match != null && match.groupCount == 2) {
          final String verb = match.group(1).toLowerCase();
          final String identifier = match.group(2);
          if (verb.startsWith('attach')) {
            _deviceIdentifierByEvent.add(<XCDeviceEvent, String>{
              XCDeviceEvent.attach: identifier
            });
          } else if (verb.startsWith('detach')) {
            _deviceIdentifierByEvent.add(<XCDeviceEvent, String>{
              XCDeviceEvent.detach: identifier
            });
          }
        }
      });
      final StreamSubscription<String> stderrSubscription = _deviceObservationProcess.stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) {
        _logger.printTrace('xcdevice observe error: $line');
      });
      unawaited(_deviceObservationProcess.exitCode.then((int status) {
        _logger.printTrace('xcdevice exited with code $exitCode');
        unawaited(stdoutSubscription.cancel());
        unawaited(stderrSubscription.cancel());
      }).whenComplete(() async {
        if (_deviceIdentifierByEvent.hasListener) {
          // Tell listeners the process died.
          await _deviceIdentifierByEvent.close();
        }
        _deviceObservationProcess = null;

        // Reopen it so new listeners can resume polling.
        _setupDeviceIdentifierByEventStream();
      }));
    } on ProcessException catch (exception, stackTrace) {
      _deviceIdentifierByEvent.addError(exception, stackTrace);
    } on ArgumentError catch (exception, stackTrace) {
      _deviceIdentifierByEvent.addError(exception, stackTrace);
    }
  }

  void _stopObservingTetheredIOSDevices() {
    _deviceObservationProcess?.kill();
  }

  /// [timeout] defaults to 2 seconds.
  Future<List<IOSDevice>> getAvailableIOSDevices({ Duration timeout }) async {
    final List<dynamic> allAvailableDevices = await _getAllDevices(timeout: timeout ?? const Duration(seconds: 2));

    if (allAvailableDevices == null) {
      return const <IOSDevice>[];
    }

    // [
    //  {
    //    "simulator" : true,
    //    "operatingSystemVersion" : "13.3 (17K446)",
    //    "available" : true,
    //    "platform" : "com.apple.platform.appletvsimulator",
    //    "modelCode" : "AppleTV5,3",
    //    "identifier" : "CBB5E1ED-2172-446E-B4E7-F2B5823DBBA6",
    //    "architecture" : "x86_64",
    //    "modelName" : "Apple TV",
    //    "name" : "Apple TV"
    //  },
    //  {
    //    "simulator" : false,
    //    "operatingSystemVersion" : "13.3 (17C54)",
    //    "interface" : "usb",
    //    "available" : true,
    //    "platform" : "com.apple.platform.iphoneos",
    //    "modelCode" : "iPhone8,1",
    //    "identifier" : "d83d5bc53967baa0ee18626ba87b6254b2ab5418",
    //    "architecture" : "arm64",
    //    "modelName" : "iPhone 6s",
    //    "name" : "iPhone"
    //  },
    //  {
    //    "simulator" : true,
    //    "operatingSystemVersion" : "6.1.1 (17S445)",
    //    "available" : true,
    //    "platform" : "com.apple.platform.watchsimulator",
    //    "modelCode" : "Watch5,4",
    //    "identifier" : "2D74FB11-88A0-44D0-B81E-C0C142B1C94A",
    //    "architecture" : "i386",
    //    "modelName" : "Apple Watch Series 5 - 44mm",
    //    "name" : "Apple Watch Series 5 - 44mm"
    //  },
    // ...

    final List<IOSDevice> devices = <IOSDevice>[];
    for (final dynamic device in allAvailableDevices) {
      if (device is! Map) {
        continue;
      }
      final Map<String, dynamic> deviceProperties = device as Map<String, dynamic>;

      // Only include iPhone, iPad, iPod, or other iOS devices.
      if (!_isIPhoneOSDevice(deviceProperties)) {
        continue;
      }

      final Map<String, dynamic> errorProperties = _errorProperties(deviceProperties);
      if (errorProperties != null) {
        final String errorMessage = _parseErrorMessage(errorProperties);
        if (errorMessage.contains('not paired')) {
          UsageEvent('device', 'ios-trust-failure', flutterUsage: globals.flutterUsage).send();
        }
        _logger.printTrace(errorMessage);

        final int code = _errorCode(errorProperties);

        // Temporary error -10: iPhone is busy: Preparing debugger support for iPhone.
        // Sometimes the app launch will fail on these devices until Xcode is done setting up the device.
        // Other times this is a false positive and the app will successfully launch despite the error.
        if (code != -10) {
          continue;
        }
      }

      final IOSDeviceInterface interface = _interfaceType(deviceProperties);

      // Only support USB devices, skip "network" interface (Xcode > Window > Devices and Simulators > Connect via network).
      // TODO(jmagman): Remove this check once wirelessly detected devices can be observed and attached, https://github.com/flutter/flutter/issues/15072.
      if (interface != IOSDeviceInterface.usb) {
        continue;
      }

      devices.add(IOSDevice(
        device['identifier'] as String,
        name: device['name'] as String,
        cpuArchitecture: _cpuArchitecture(deviceProperties),
        interfaceType: interface,
        sdkVersion: _sdkVersion(deviceProperties),
        iProxy: _iProxy,
        fileSystem: globals.fs,
        logger: _logger,
        iosDeploy: _iosDeploy,
        iMobileDevice: _iMobileDevice,
        platform: globals.platform,
        vmServiceConnectUri: vm_service_io.vmServiceConnectUri,
      ));
    }
    return devices;
  }

  /// Despite the name, com.apple.platform.iphoneos includes iPhone, iPads, and all iOS devices.
  /// Excludes simulators.
  static bool _isIPhoneOSDevice(Map<String, dynamic> deviceProperties) {
    if (deviceProperties.containsKey('platform')) {
      final String platform = deviceProperties['platform'] as String;
      return platform == 'com.apple.platform.iphoneos';
    }
    return false;
  }

  static Map<String, dynamic> _errorProperties(Map<String, dynamic> deviceProperties) {
    if (deviceProperties.containsKey('error')) {
      return deviceProperties['error'] as Map<String, dynamic>;
    }
    return null;
  }

  static int _errorCode(Map<String, dynamic> errorProperties) {
    if (errorProperties.containsKey('code') && errorProperties['code'] is int) {
      return errorProperties['code'] as int;
    }
    return null;
  }

  static IOSDeviceInterface _interfaceType(Map<String, dynamic> deviceProperties) {
    // Interface can be "usb", "network", or "none" for simulators
    // and unknown future interfaces.
    if (deviceProperties.containsKey('interface')) {
      if ((deviceProperties['interface'] as String).toLowerCase() == 'network') {
        return IOSDeviceInterface.network;
      } else {
        return IOSDeviceInterface.usb;
      }
    }

    return IOSDeviceInterface.none;
  }

  static String _sdkVersion(Map<String, dynamic> deviceProperties) {
    if (deviceProperties.containsKey('operatingSystemVersion')) {
      // Parse out the OS version, ignore the build number in parentheses.
      // "13.3 (17C54)"
      final RegExp operatingSystemRegex = RegExp(r'(.*) \(.*\)$');
      final String operatingSystemVersion = deviceProperties['operatingSystemVersion'] as String;
      return operatingSystemRegex.firstMatch(operatingSystemVersion.trim())?.group(1);
    }
    return null;
  }

  DarwinArch _cpuArchitecture(Map<String, dynamic> deviceProperties) {
    DarwinArch cpuArchitecture;
    if (deviceProperties.containsKey('architecture')) {
      final String architecture = deviceProperties['architecture'] as String;
      try {
        cpuArchitecture = getIOSArchForName(architecture);
      } on Exception {
        // Fallback to default iOS architecture. Future-proof against a
        // theoretical version of Xcode that changes this string to something
        // slightly different like "ARM64", or armv7 variations like
        // armv7s and armv7f.
        if (architecture.startsWith('armv7')) {
          cpuArchitecture = DarwinArch.armv7;
        } else {
          cpuArchitecture = defaultIOSArchs.first;
        }
        _logger.printError(
          'Unknown architecture $architecture, defaulting to '
          '${getNameForDarwinArch(cpuArchitecture)}',
        );
      }
    }
    return cpuArchitecture;
  }

  /// Error message parsed from xcdevice. null if no error.
  static String _parseErrorMessage(Map<String, dynamic> errorProperties) {
    //  {
    //    "simulator" : false,
    //    "operatingSystemVersion" : "13.3 (17C54)",
    //    "interface" : "usb",
    //    "available" : false,
    //    "platform" : "com.apple.platform.iphoneos",
    //    "modelCode" : "iPhone8,1",
    //    "identifier" : "98206e7a4afd4aedaff06e687594e089dede3c44",
    //    "architecture" : "arm64",
    //    "modelName" : "iPhone 6s",
    //    "name" : "iPhone",
    //    "error" : {
    //      "code" : -9,
    //      "failureReason" : "",
    //      "underlyingErrors" : [
    //        {
    //          "code" : 5,
    //          "failureReason" : "allowsSecureServices: 1. isConnected: 0. Platform: <DVTPlatform:0x7f804ce32880:'com.apple.platform.iphoneos':<DVTFilePath:0x7f804ce32800:'\/Users\/magder\/Applications\/Xcode_11-3-1.app\/Contents\/Developer\/Platforms\/iPhoneOS.platform'>>. DTDKDeviceIdentifierIsIDID: 0",
    //          "description" : "📱<DVTiOSDevice (0x7f801f190450), iPhone, iPhone, 13.3 (17C54), d83d5bc53967baa0ee18626ba87b6254b2ab5418> -- Failed _shouldMakeReadyForDevelopment check even though device is not locked by passcode.",
    //          "recoverySuggestion" : "",
    //          "domain" : "com.apple.platform.iphoneos"
    //        }
    //      ],
    //      "description" : "iPhone is not paired with your computer.",
    //      "recoverySuggestion" : "To use iPhone with Xcode, unlock it and choose to trust this computer when prompted.",
    //      "domain" : "com.apple.platform.iphoneos"
    //    }
    //  },
    //  {
    //    "simulator" : false,
    //    "operatingSystemVersion" : "13.3 (17C54)",
    //    "interface" : "usb",
    //    "available" : false,
    //    "platform" : "com.apple.platform.iphoneos",
    //    "modelCode" : "iPhone8,1",
    //    "identifier" : "d83d5bc53967baa0ee18626ba87b6254b2ab5418",
    //    "architecture" : "arm64",
    //    "modelName" : "iPhone 6s",
    //    "name" : "iPhone",
    //    "error" : {
    //      "code" : -9,
    //      "failureReason" : "",
    //      "description" : "iPhone is not paired with your computer.",
    //      "domain" : "com.apple.platform.iphoneos"
    //    }
    //  }
    // ...

    if (errorProperties == null) {
      return null;
    }

    final StringBuffer errorMessage = StringBuffer('Error: ');

    if (errorProperties.containsKey('description')) {
      final String description = errorProperties['description'] as String;
      errorMessage.write(description);
      if (!description.endsWith('.')) {
        errorMessage.write('.');
      }
    } else {
      errorMessage.write('Xcode pairing error.');
    }

    if (errorProperties.containsKey('recoverySuggestion')) {
      final String recoverySuggestion = errorProperties['recoverySuggestion'] as String;
      errorMessage.write(' $recoverySuggestion');
    }

    final int code = _errorCode(errorProperties);
    if (code != null) {
      errorMessage.write(' (code $code)');
    }

    return errorMessage.toString();
  }

  /// List of all devices reporting errors.
  Future<List<String>> getDiagnostics() async {
    final List<dynamic> allAvailableDevices = await _getAllDevices(
      useCache: true,
      timeout: const Duration(seconds: 2)
    );

    if (allAvailableDevices == null) {
      return const <String>[];
    }

    final List<String> diagnostics = <String>[];
    for (final dynamic device in allAvailableDevices) {
      if (device is! Map) {
        continue;
      }
      final Map<String, dynamic> deviceProperties = device as Map<String, dynamic>;
      final Map<String, dynamic> errorProperties = _errorProperties(deviceProperties);
      final String errorMessage = _parseErrorMessage(errorProperties);
      if (errorMessage != null) {
        diagnostics.add(errorMessage);
      }
    }
    return diagnostics;
  }
}
