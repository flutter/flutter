// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'application_package.dart';
import 'artifacts.dart';
import 'base/common.dart';
import 'base/context.dart';
import 'base/dds.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/terminal.dart';
import 'base/user_messages.dart' hide userMessages;
import 'base/utils.dart';
import 'build_info.dart';
import 'devfs.dart';
import 'device_port_forwarder.dart';
import 'project.dart';
import 'vmservice.dart';

DeviceManager? get deviceManager => context.get<DeviceManager>();

/// A description of the kind of workflow the device supports.
class Category {
  const Category._(this.value);

  static const Category web = Category._('web');
  static const Category desktop = Category._('desktop');
  static const Category mobile = Category._('mobile');

  final String value;

  @override
  String toString() => value;

  static Category? fromString(String category) {
    return <String, Category>{
      'web': web,
      'desktop': desktop,
      'mobile': mobile,
    }[category];
  }
}

/// The platform sub-folder that a device type supports.
class PlatformType {
  const PlatformType._(this.value);

  static const PlatformType web = PlatformType._('web');
  static const PlatformType android = PlatformType._('android');
  static const PlatformType ios = PlatformType._('ios');
  static const PlatformType linux = PlatformType._('linux');
  static const PlatformType macos = PlatformType._('macos');
  static const PlatformType windows = PlatformType._('windows');
  static const PlatformType fuchsia = PlatformType._('fuchsia');
  static const PlatformType custom = PlatformType._('custom');

  final String value;

  @override
  String toString() => value;

  static PlatformType? fromString(String platformType) {
    return <String, PlatformType>{
      'web': web,
      'android': android,
      'ios': ios,
      'linux': linux,
      'macos': macos,
      'windows': windows,
      'fuchsia': fuchsia,
      'custom': custom,
    }[platformType];
  }
}

/// A discovery mechanism for flutter-supported development devices.
abstract class DeviceManager {
  DeviceManager({
    required Logger logger,
    required Terminal terminal,
    required UserMessages userMessages,
  }) : _logger = logger,
       _terminal = terminal,
       _userMessages = userMessages;

  final Logger _logger;
  final Terminal _terminal;
  final UserMessages _userMessages;

  /// Constructing DeviceManagers is cheap; they only do expensive work if some
  /// of their methods are called.
  List<DeviceDiscovery> get deviceDiscoverers;

  String? _specifiedDeviceId;

  /// A user-specified device ID.
  String? get specifiedDeviceId {
    if (_specifiedDeviceId == null || _specifiedDeviceId == 'all') {
      return null;
    }
    return _specifiedDeviceId;
  }

  set specifiedDeviceId(String? id) {
    _specifiedDeviceId = id;
  }

  /// True when the user has specified a single specific device.
  bool get hasSpecifiedDeviceId => specifiedDeviceId != null;

  /// True when the user has specified all devices by setting
  /// specifiedDeviceId = 'all'.
  bool get hasSpecifiedAllDevices => _specifiedDeviceId == 'all';

  Future<List<Device>> getDevicesById(String deviceId) async {
    final String lowerDeviceId = deviceId.toLowerCase();
    bool exactlyMatchesDeviceId(Device device) =>
        device.id.toLowerCase() == lowerDeviceId ||
        device.name.toLowerCase() == lowerDeviceId;
    bool startsWithDeviceId(Device device) =>
        device.id.toLowerCase().startsWith(lowerDeviceId) ||
        device.name.toLowerCase().startsWith(lowerDeviceId);

    // Some discoverers have hard-coded device IDs and return quickly, and others
    // shell out to other processes and can take longer.
    // If an ID was specified, first check if it was a "well-known" device id.
    final Set<String> wellKnownIds = _platformDiscoverers
      .expand((DeviceDiscovery discovery) => discovery.wellKnownIds)
      .toSet();
    final bool hasWellKnownId = hasSpecifiedDeviceId && wellKnownIds.contains(specifiedDeviceId);

    // Process discoverers as they can return results, so if an exact match is
    // found quickly, we don't wait for all the discoverers to complete.
    final List<Device> prefixMatches = <Device>[];
    final Completer<Device> exactMatchCompleter = Completer<Device>();
    final List<Future<List<Device>?>> futureDevices = <Future<List<Device>?>>[
      for (final DeviceDiscovery discoverer in _platformDiscoverers)
        if (!hasWellKnownId || discoverer.wellKnownIds.contains(specifiedDeviceId))
          discoverer
          .devices
          .then((List<Device> devices) {
            for (final Device device in devices) {
              if (exactlyMatchesDeviceId(device)) {
                exactMatchCompleter.complete(device);
                return null;
              }
              if (startsWithDeviceId(device)) {
                prefixMatches.add(device);
              }
            }
            return null;
          }, onError: (dynamic error, StackTrace stackTrace) {
            // Return matches from other discoverers even if one fails.
            _logger.printTrace('Ignored error discovering $deviceId: $error');
          })
    ];

    // Wait for an exact match, or for all discoverers to return results.
    await Future.any<Object>(<Future<Object>>[
      exactMatchCompleter.future,
      Future.wait<List<Device>?>(futureDevices),
    ]);

    if (exactMatchCompleter.isCompleted) {
      return <Device>[await exactMatchCompleter.future];
    }
    return prefixMatches;
  }

  /// Returns the list of connected devices, filtered by any user-specified device id.
  Future<List<Device>> getDevices() {
    final String? id = specifiedDeviceId;
    if (id == null) {
      return getAllConnectedDevices();
    }
    return getDevicesById(id);
  }

  Iterable<DeviceDiscovery> get _platformDiscoverers {
    return deviceDiscoverers.where((DeviceDiscovery discoverer) => discoverer.supportsPlatform);
  }

  /// Returns the list of all connected devices.
  Future<List<Device>> getAllConnectedDevices() async {
    final List<List<Device>> devices = await Future.wait<List<Device>>(<Future<List<Device>>>[
      for (final DeviceDiscovery discoverer in _platformDiscoverers)
        discoverer.devices,
    ]);

    return devices.expand<Device>((List<Device> deviceList) => deviceList).toList();
  }

  /// Returns the list of all connected devices. Discards existing cache of devices.
  Future<List<Device>> refreshAllConnectedDevices({ Duration? timeout }) async {
    final List<List<Device>> devices = await Future.wait<List<Device>>(<Future<List<Device>>>[
      for (final DeviceDiscovery discoverer in _platformDiscoverers)
        discoverer.discoverDevices(timeout: timeout),
    ]);

    return devices.expand<Device>((List<Device> deviceList) => deviceList).toList();
  }

  /// Whether we're capable of listing any devices given the current environment configuration.
  bool get canListAnything {
    return _platformDiscoverers.any((DeviceDiscovery discoverer) => discoverer.canListAnything);
  }

  /// Get diagnostics about issues with any connected devices.
  Future<List<String>> getDeviceDiagnostics() async {
    return <String>[
      for (final DeviceDiscovery discoverer in _platformDiscoverers)
        ...await discoverer.getDiagnostics(),
    ];
  }

  /// Find and return a list of devices based on the current project and environment.
  ///
  /// Returns a list of devices specified by the user.
  ///
  /// * If the user specified '-d all', then return all connected devices which
  /// support the current project, except for fuchsia and web.
  ///
  /// * If the user specified a device id, then do nothing as the list is already
  /// filtered by [getDevices].
  ///
  /// * If the user did not specify a device id and there is more than one
  /// device connected, then filter out unsupported devices and prioritize
  /// ephemeral devices.
  ///
  /// * If [flutterProject] is null, then assume the project supports all
  /// device types.
  Future<List<Device>> findTargetDevices(FlutterProject? flutterProject, { Duration? timeout }) async {
    if (timeout != null) {
      // Reset the cache with the specified timeout.
      await refreshAllConnectedDevices(timeout: timeout);
    }

    List<Device> devices = (await getDevices())
        .where((Device device) => device.isSupported()).toList();

    // Always remove web and fuchsia devices from `--all`. This setting
    // currently requires devices to share a frontend_server and resident
    // runner instance. Both web and fuchsia require differently configured
    // compilers, and web requires an entirely different resident runner.
    if (hasSpecifiedAllDevices) {
      devices = <Device>[
        for (final Device device in devices)
          if (await device.targetPlatform != TargetPlatform.fuchsia_arm64 &&
              await device.targetPlatform != TargetPlatform.fuchsia_x64 &&
              await device.targetPlatform != TargetPlatform.web_javascript)
            device,
      ];
    }

    // If there is no specified device, the remove all devices which are not
    // supported by the current application. For example, if there was no
    // 'android' folder then don't attempt to launch with an Android device.
    if (devices.length > 1 && !hasSpecifiedDeviceId) {
      devices = <Device>[
        for (final Device device in devices)
          if (isDeviceSupportedForProject(device, flutterProject))
            device,
      ];
    } else if (devices.length == 1 &&
             !hasSpecifiedDeviceId &&
             !isDeviceSupportedForProject(devices.single, flutterProject)) {
      // If there is only a single device but it is not supported, then return
      // early.
      return <Device>[];
    }

    // If there are still multiple devices and the user did not specify to run
    // all, then attempt to prioritize ephemeral devices. For example, if the
    // user only typed 'flutter run' and both an Android device and desktop
    // device are available, choose the Android device.
    if (devices.length > 1 && !hasSpecifiedAllDevices) {
      // Note: ephemeral is nullable for device types where this is not well
      // defined.
      if (devices.any((Device device) => device.ephemeral == true)) {
        // if there is only one ephemeral device, get it
        final List<Device> ephemeralDevices = devices
            .where((Device device) => device.ephemeral == true)
            .toList();

            if (ephemeralDevices.length == 1) {
              devices = ephemeralDevices;
            }
      }
      // If it was not able to prioritize a device. For example, if the user
      // has two active Android devices running, then we request the user to
      // choose one. If the user has two nonEphemeral devices running, we also
      // request input to choose one.
      if (devices.length > 1 && _terminal.stdinHasTerminal) {
        _logger.printStatus(_userMessages.flutterMultipleDevicesFound);
        await Device.printDevices(devices, _logger);
        final Device chosenDevice = await _chooseOneOfAvailableDevices(devices);
        specifiedDeviceId = chosenDevice.id;
        devices = <Device>[chosenDevice];
      }
    }
    return devices;
  }

  Future<Device> _chooseOneOfAvailableDevices(List<Device> devices) async {
    _displayDeviceOptions(devices);
    final String userInput =  await _readUserInput(devices.length);
    if (userInput.toLowerCase() == 'q') {
      throwToolExit('');
    }
    return devices[int.parse(userInput) - 1];
  }

  void _displayDeviceOptions(List<Device> devices) {
    int count = 1;
    for (final Device device in devices) {
      _logger.printStatus(_userMessages.flutterChooseDevice(count, device.name, device.id));
      count++;
    }
  }

  Future<String> _readUserInput(int deviceCount) async {
    _terminal.usesTerminalUi = true;
    final String result = await _terminal.promptForCharInput(
      <String>[ for (int i = 0; i < deviceCount; i++) '${i + 1}', 'q', 'Q'],
      displayAcceptedCharacters: false,
      logger: _logger,
      prompt: _userMessages.flutterChooseOne,
    );
    return result;
  }

  /// Returns whether the device is supported for the project.
  ///
  /// This exists to allow the check to be overridden for google3 clients. If
  /// [flutterProject] is null then return true.
  bool isDeviceSupportedForProject(Device device, FlutterProject? flutterProject) {
    if (flutterProject == null) {
      return true;
    }
    return device.isSupportedForProject(flutterProject);
  }
}


/// An abstract class to discover and enumerate a specific type of devices.
abstract class DeviceDiscovery {
  bool get supportsPlatform;

  /// Whether this device discovery is capable of listing any devices given the
  /// current environment configuration.
  bool get canListAnything;

  /// Return all connected devices, cached on subsequent calls.
  Future<List<Device>> get devices;

  /// Return all connected devices. Discards existing cache of devices.
  Future<List<Device>> discoverDevices({ Duration? timeout });

  /// Gets a list of diagnostic messages pertaining to issues with any connected
  /// devices (will be an empty list if there are no issues).
  Future<List<String>> getDiagnostics() => Future<List<String>>.value(<String>[]);

  /// Hard-coded device IDs that the discoverer can produce.
  ///
  /// These values are used by the device discovery to determine if it can
  /// short-circuit the other detectors if a specific ID is provided. If a
  /// discoverer has no valid fixed IDs, these should be left empty.
  ///
  /// For example, 'windows' or 'linux'.
  List<String> get wellKnownIds;
}

/// A [DeviceDiscovery] implementation that uses polling to discover device adds
/// and removals.
abstract class PollingDeviceDiscovery extends DeviceDiscovery {
  PollingDeviceDiscovery(this.name);

  static const Duration _pollingInterval = Duration(seconds: 4);
  static const Duration _pollingTimeout = Duration(seconds: 30);

  final String name;

  @protected
  @visibleForTesting
  ItemListNotifier<Device>? deviceNotifier;

  Timer? _timer;

  Future<List<Device>> pollingGetDevices({ Duration? timeout });

  void startPolling() {
    if (_timer == null) {
      deviceNotifier ??= ItemListNotifier<Device>();
      // Make initial population the default, fast polling timeout.
      _timer = _initTimer(null);
    }
  }

  Timer _initTimer(Duration? pollingTimeout) {
    return Timer(_pollingInterval, () async {
      try {
        final List<Device> devices = await pollingGetDevices(timeout: pollingTimeout);
        deviceNotifier!.updateWithNewList(devices);
      } on TimeoutException {
        // Do nothing on a timeout.
      }
      // Subsequent timeouts after initial population should wait longer.
      _timer = _initTimer(_pollingTimeout);
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<List<Device>> get devices {
    return _populateDevices();
  }

  @override
  Future<List<Device>> discoverDevices({ Duration? timeout }) {
    deviceNotifier = null;
    return _populateDevices(timeout: timeout);
  }

  Future<List<Device>> _populateDevices({ Duration? timeout }) async {
    deviceNotifier ??= ItemListNotifier<Device>.from(await pollingGetDevices(timeout: timeout));
    return deviceNotifier!.items;
  }

  Stream<Device> get onAdded {
    deviceNotifier ??= ItemListNotifier<Device>();
    return deviceNotifier!.onAdded;
  }

  Stream<Device> get onRemoved {
    deviceNotifier ??= ItemListNotifier<Device>();
    return deviceNotifier!.onRemoved;
  }

  void dispose() => stopPolling();

  @override
  String toString() => '$name device discovery';
}

/// A device is a physical hardware that can run a Flutter application.
///
/// This may correspond to a connected iOS or Android device, or represent
/// the host operating system in the case of Flutter Desktop.
abstract class Device {
  Device(this.id, {
    required this.category,
    required this.platformType,
    required this.ephemeral,
  });

  final String id;

  /// The [Category] for this device type.
  final Category? category;

  /// The [PlatformType] for this device.
  final PlatformType? platformType;

  /// Whether this is an ephemeral device.
  final bool ephemeral;

  String get name;

  bool get supportsStartPaused => true;

  /// Whether it is an emulated device running on localhost.
  ///
  /// This may return `true` for certain physical Android devices, and is
  /// generally only a best effort guess.
  Future<bool> get isLocalEmulator;

  /// The unique identifier for the emulator that corresponds to this device, or
  /// null if it is not an emulator.
  ///
  /// The ID returned matches that in the output of `flutter emulators`. Fetching
  /// this name may require connecting to the device and if an error occurs null
  /// will be returned.
  Future<String?> get emulatorId;

  /// Whether this device can run the provided [buildMode].
  ///
  /// For example, some emulator architectures cannot run profile or
  /// release builds.
  FutureOr<bool> supportsRuntimeMode(BuildMode buildMode) => true;

  /// Whether the device is a simulator on a platform which supports hardware rendering.
  // This is soft-deprecated since the logic is not correct expect for iOS simulators.
  Future<bool> get supportsHardwareRendering async {
    return true;
  }

  /// Whether the device is supported for the current project directory.
  bool isSupportedForProject(FlutterProject flutterProject);

  /// Check if a version of the given app is already installed.
  ///
  /// Specify [userIdentifier] to check if installed for a particular user (Android only).
  Future<bool> isAppInstalled(
    covariant ApplicationPackage app, {
    String? userIdentifier,
  });

  /// Check if the latest build of the [app] is already installed.
  Future<bool> isLatestBuildInstalled(covariant ApplicationPackage app);

  /// Install an app package on the current device.
  ///
  /// Specify [userIdentifier] to install for a particular user (Android only).
  Future<bool> installApp(
    covariant ApplicationPackage app, {
    String? userIdentifier,
  });

  /// Uninstall an app package from the current device.
  ///
  /// Specify [userIdentifier] to uninstall for a particular user,
  /// defaults to all users (Android only).
  Future<bool> uninstallApp(
    covariant ApplicationPackage app, {
    String? userIdentifier,
  });

  /// Check if the device is supported by Flutter.
  bool isSupported();

  // String meant to be displayed to the user indicating if the device is
  // supported by Flutter, and, if not, why.
  String supportMessage() => isSupported() ? 'Supported' : 'Unsupported';

  /// The device's platform.
  Future<TargetPlatform> get targetPlatform;

  /// Platform name for display only.
  Future<String> get targetPlatformDisplayName async =>
      getNameForTargetPlatform(await targetPlatform);

  Future<String> get sdkNameAndVersion;

  /// Create a platform-specific [DevFSWriter] for the given [app], or
  /// null if the device does not support them.
  ///
  /// For example, the desktop device classes can use a writer which
  /// copies the files across the local file system.
  DevFSWriter? createDevFSWriter(
    covariant ApplicationPackage app,
    String userIdentifier,
  ) {
    return null;
  }

  /// Get a log reader for this device.
  ///
  /// If `app` is specified, this will return a log reader specific to that
  /// application. Otherwise, a global log reader will be returned.
  ///
  /// If `includePastLogs` is true and the device type supports it, the log
  /// reader will also include log messages from before the invocation time.
  /// Defaults to false.
  FutureOr<DeviceLogReader> getLogReader({
    covariant ApplicationPackage? app,
    bool includePastLogs = false,
  });

  /// Get the port forwarder for this device.
  DevicePortForwarder? get portForwarder;

  /// Get the DDS instance for this device.
  final DartDevelopmentService dds = DartDevelopmentService();

  /// Clear the device's logs.
  void clearLogs();

  /// Optional device-specific artifact overrides.
  OverrideArtifacts? get artifactOverrides => null;

  /// Start an app package on the current device.
  ///
  /// [platformArgs] allows callers to pass platform-specific arguments to the
  /// start call. The build mode is not used by all platforms.
  Future<LaunchResult> startApp(
    covariant ApplicationPackage package, {
    String? mainPath,
    String? route,
    required DebuggingOptions debuggingOptions,
    Map<String, Object?> platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String? userIdentifier,
  });

  /// Whether this device implements support for hot reload.
  bool get supportsHotReload => true;

  /// Whether this device implements support for hot restart.
  bool get supportsHotRestart => true;

  /// Whether Flutter applications running on this device can be terminated
  /// from the VM Service.
  bool get supportsFlutterExit => true;

  /// Whether the device supports taking screenshots of a running flutter
  /// application.
  bool get supportsScreenshot => false;

  /// Whether the device supports the '--fast-start' development mode.
  bool get supportsFastStart => false;

  /// Stop an app package on the current device.
  ///
  /// Specify [userIdentifier] to stop app installed to a profile (Android only).
  Future<bool> stopApp(
    covariant ApplicationPackage app, {
    String? userIdentifier,
  });

  /// Query the current application memory usage..
  ///
  /// If the device does not support this callback, an empty map
  /// is returned.
  Future<MemoryInfo> queryMemoryInfo() {
    return Future<MemoryInfo>.value(const MemoryInfo.empty());
  }

  Future<void> takeScreenshot(File outputFile) => Future<void>.error('unimplemented');

  @nonVirtual
  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => id.hashCode;

  @nonVirtual
  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Device
        && other.id == id;
  }

  @override
  String toString() => name;

  static Future<List<String>> descriptions(List<Device> devices) async {
    if (devices.isEmpty) {
      return const <String>[];
    }

    // Extract device information
    final List<List<String>> table = <List<String>>[];
    for (final Device device in devices) {
      String supportIndicator = device.isSupported() ? '' : ' (unsupported)';
      final TargetPlatform targetPlatform = await device.targetPlatform;
      if (await device.isLocalEmulator) {
        final String type = targetPlatform == TargetPlatform.ios ? 'simulator' : 'emulator';
        supportIndicator += ' ($type)';
      }
      table.add(<String>[
        '${device.name} (${device.category})',
        device.id,
        await device.targetPlatformDisplayName,
        '${await device.sdkNameAndVersion}$supportIndicator',
      ]);
    }

    // Calculate column widths
    final List<int> indices = List<int>.generate(table[0].length - 1, (int i) => i);
    List<int> widths = indices.map<int>((int i) => 0).toList();
    for (final List<String> row in table) {
      widths = indices.map<int>((int i) => math.max(widths[i], row[i].length)).toList();
    }

    // Join columns into lines of text
    return <String>[
      for (final List<String> row in table)
        indices.map<String>((int i) => row[i].padRight(widths[i])).followedBy(<String>[row.last]).join(' • '),
    ];
  }

  static Future<void> printDevices(List<Device> devices, Logger logger) async {
    (await descriptions(devices)).forEach(logger.printStatus);
  }

  static List<String> devicesPlatformTypes(List<Device> devices) {
    return devices
        .map(
          (Device d) => d.platformType.toString(),
        ).toSet().toList()..sort();
  }

  /// Convert the Device object to a JSON representation suitable for serialization.
  Future<Map<String, Object>> toJson() async {
    final bool isLocalEmu = await isLocalEmulator;
    return <String, Object>{
      'name': name,
      'id': id,
      'isSupported': isSupported(),
      'targetPlatform': getNameForTargetPlatform(await targetPlatform),
      'emulator': isLocalEmu,
      'sdk': await sdkNameAndVersion,
      'capabilities': <String, Object>{
        'hotReload': supportsHotReload,
        'hotRestart': supportsHotRestart,
        'screenshot': supportsScreenshot,
        'fastStart': supportsFastStart,
        'flutterExit': supportsFlutterExit,
        'hardwareRendering': isLocalEmu && await supportsHardwareRendering,
        'startPaused': supportsStartPaused,
      }
    };
  }

  /// Clean up resources allocated by device.
  ///
  /// For example log readers or port forwarders.
  Future<void> dispose();
}

/// Information about an application's memory usage.
abstract class MemoryInfo {
  /// Const constructor to allow subclasses to be const.
  const MemoryInfo();

  /// Create a [MemoryInfo] object with no information.
  const factory MemoryInfo.empty() = _NoMemoryInfo;

  /// Convert the object to a JSON representation suitable for serialization.
  Map<String, Object> toJson();
}

class _NoMemoryInfo implements MemoryInfo {
  const _NoMemoryInfo();

  @override
  Map<String, Object> toJson() => <String, Object>{};
}

class DebuggingOptions {
  DebuggingOptions.enabled(
    this.buildInfo, {
    this.startPaused = false,
    this.disableServiceAuthCodes = false,
    this.enableDds = true,
    this.cacheStartupProfile = false,
    this.dartEntrypointArgs = const <String>[],
    this.dartFlags = '',
    this.enableSoftwareRendering = false,
    this.skiaDeterministicRendering = false,
    this.traceSkia = false,
    this.traceAllowlist,
    this.traceSkiaAllowlist,
    this.traceSystrace = false,
    this.endlessTraceBuffer = false,
    this.dumpSkpOnShaderCompilation = false,
    this.cacheSkSL = false,
    this.purgePersistentCache = false,
    this.useTestFonts = false,
    this.verboseSystemLogs = false,
    this.hostVmServicePort,
    this.disablePortPublication = false,
    this.deviceVmServicePort,
    this.ddsPort,
    this.devToolsServerAddress,
    this.hostname,
    this.port,
    this.webEnableExposeUrl,
    this.webUseSseForDebugProxy = true,
    this.webUseSseForDebugBackend = true,
    this.webUseSseForInjectedClient = true,
    this.webRunHeadless = false,
    this.webBrowserDebugPort,
    this.webEnableExpressionEvaluation = false,
    this.webLaunchUrl,
    this.vmserviceOutFile,
    this.fastStart = false,
    this.nullAssertions = false,
    this.nativeNullAssertions = false,
    this.enableImpeller = false,
   }) : debuggingEnabled = true;

  DebuggingOptions.disabled(this.buildInfo, {
      this.dartEntrypointArgs = const <String>[],
      this.port,
      this.hostname,
      this.webEnableExposeUrl,
      this.webUseSseForDebugProxy = true,
      this.webUseSseForDebugBackend = true,
      this.webUseSseForInjectedClient = true,
      this.webRunHeadless = false,
      this.webBrowserDebugPort,
      this.webLaunchUrl,
      this.cacheSkSL = false,
      this.traceAllowlist,
      this.enableImpeller = false,
    }) : debuggingEnabled = false,
      useTestFonts = false,
      startPaused = false,
      dartFlags = '',
      disableServiceAuthCodes = false,
      enableDds = true,
      cacheStartupProfile = false,
      enableSoftwareRendering = false,
      skiaDeterministicRendering = false,
      traceSkia = false,
      traceSkiaAllowlist = null,
      traceSystrace = false,
      endlessTraceBuffer = false,
      dumpSkpOnShaderCompilation = false,
      purgePersistentCache = false,
      verboseSystemLogs = false,
      hostVmServicePort = null,
      disablePortPublication = false,
      deviceVmServicePort = null,
      ddsPort = null,
      devToolsServerAddress = null,
      vmserviceOutFile = null,
      fastStart = false,
      webEnableExpressionEvaluation = false,
      nullAssertions = false,
      nativeNullAssertions = false;

  DebuggingOptions._({
    required this.buildInfo,
    required this.debuggingEnabled,
    required this.startPaused,
    required this.dartFlags,
    required this.dartEntrypointArgs,
    required this.disableServiceAuthCodes,
    required this.enableDds,
    required this.cacheStartupProfile,
    required this.enableSoftwareRendering,
    required this.skiaDeterministicRendering,
    required this.traceSkia,
    required this.traceAllowlist,
    required this.traceSkiaAllowlist,
    required this.traceSystrace,
    required this.endlessTraceBuffer,
    required this.dumpSkpOnShaderCompilation,
    required this.cacheSkSL,
    required this.purgePersistentCache,
    required this.useTestFonts,
    required this.verboseSystemLogs,
    required this.hostVmServicePort,
    required this.deviceVmServicePort,
    required this.disablePortPublication,
    required this.ddsPort,
    required this.devToolsServerAddress,
    required this.port,
    required this.hostname,
    required this.webEnableExposeUrl,
    required this.webUseSseForDebugProxy,
    required this.webUseSseForDebugBackend,
    required this.webUseSseForInjectedClient,
    required this.webRunHeadless,
    required this.webBrowserDebugPort,
    required this.webEnableExpressionEvaluation,
    required this.webLaunchUrl,
    required this.vmserviceOutFile,
    required this.fastStart,
    required this.nullAssertions,
    required this.nativeNullAssertions,
    required this.enableImpeller,
  });

  final bool debuggingEnabled;

  final BuildInfo buildInfo;
  final bool startPaused;
  final String dartFlags;
  final List<String> dartEntrypointArgs;
  final bool disableServiceAuthCodes;
  final bool enableDds;
  final bool cacheStartupProfile;
  final bool enableSoftwareRendering;
  final bool skiaDeterministicRendering;
  final bool traceSkia;
  final String? traceAllowlist;
  final String? traceSkiaAllowlist;
  final bool traceSystrace;
  final bool endlessTraceBuffer;
  final bool dumpSkpOnShaderCompilation;
  final bool cacheSkSL;
  final bool purgePersistentCache;
  final bool useTestFonts;
  final bool verboseSystemLogs;
  final int? hostVmServicePort;
  final int? deviceVmServicePort;
  final bool disablePortPublication;
  final int? ddsPort;
  final Uri? devToolsServerAddress;
  final String? port;
  final String? hostname;
  final bool? webEnableExposeUrl;
  final bool webUseSseForDebugProxy;
  final bool webUseSseForDebugBackend;
  final bool webUseSseForInjectedClient;
  final bool enableImpeller;

  /// Whether to run the browser in headless mode.
  ///
  /// Some CI environments do not provide a display and fail to launch the
  /// browser with full graphics stack. Some browsers provide a special
  /// "headless" mode that runs the browser with no graphics.
  final bool webRunHeadless;

  /// The port the browser should use for its debugging protocol.
  final int? webBrowserDebugPort;

  /// Enable expression evaluation for web target.
  final bool webEnableExpressionEvaluation;

  /// Allow developers to customize the browser's launch URL
  final String? webLaunchUrl;

  /// A file where the VM Service URL should be written after the application is started.
  final String? vmserviceOutFile;
  final bool fastStart;

  final bool nullAssertions;

  /// Additional null runtime checks inserted for web applications.
  ///
  /// See also:
  ///   * https://github.com/dart-lang/sdk/blob/main/sdk/lib/html/doc/NATIVE_NULL_ASSERTIONS.md
  final bool nativeNullAssertions;

  bool get hasObservatoryPort => hostVmServicePort != null;

  Map<String, Object?> toJson() => <String, Object?>{
    'debuggingEnabled': debuggingEnabled,
    'startPaused': startPaused,
    'dartFlags': dartFlags,
    'dartEntrypointArgs': dartEntrypointArgs,
    'disableServiceAuthCodes': disableServiceAuthCodes,
    'enableDds': enableDds,
    'cacheStartupProfile': cacheStartupProfile,
    'enableSoftwareRendering': enableSoftwareRendering,
    'skiaDeterministicRendering': skiaDeterministicRendering,
    'traceSkia': traceSkia,
    'traceAllowlist': traceAllowlist,
    'traceSkiaAllowlist': traceSkiaAllowlist,
    'traceSystrace': traceSystrace,
    'endlessTraceBuffer': endlessTraceBuffer,
    'dumpSkpOnShaderCompilation': dumpSkpOnShaderCompilation,
    'cacheSkSL': cacheSkSL,
    'purgePersistentCache': purgePersistentCache,
    'useTestFonts': useTestFonts,
    'verboseSystemLogs': verboseSystemLogs,
    'hostVmServicePort': hostVmServicePort,
    'deviceVmServicePort': deviceVmServicePort,
    'disablePortPublication': disablePortPublication,
    'ddsPort': ddsPort,
    'devToolsServerAddress': devToolsServerAddress.toString(),
    'port': port,
    'hostname': hostname,
    'webEnableExposeUrl': webEnableExposeUrl,
    'webUseSseForDebugProxy': webUseSseForDebugProxy,
    'webUseSseForDebugBackend': webUseSseForDebugBackend,
    'webUseSseForInjectedClient': webUseSseForInjectedClient,
    'webRunHeadless': webRunHeadless,
    'webBrowserDebugPort': webBrowserDebugPort,
    'webEnableExpressionEvaluation': webEnableExpressionEvaluation,
    'webLaunchUrl': webLaunchUrl,
    'vmserviceOutFile': vmserviceOutFile,
    'fastStart': fastStart,
    'nullAssertions': nullAssertions,
    'nativeNullAssertions': nativeNullAssertions,
    'enableImpeller': enableImpeller,
  };

  static DebuggingOptions fromJson(Map<String, Object?> json, BuildInfo buildInfo) =>
    DebuggingOptions._(
      buildInfo: buildInfo,
      debuggingEnabled: (json['debuggingEnabled'] as bool?)!,
      startPaused: (json['startPaused'] as bool?)!,
      dartFlags: (json['dartFlags'] as String?)!,
      dartEntrypointArgs: ((json['dartEntrypointArgs'] as List<dynamic>?)?.cast<String>())!,
      disableServiceAuthCodes: (json['disableServiceAuthCodes'] as bool?)!,
      enableDds: (json['enableDds'] as bool?)!,
      cacheStartupProfile: (json['cacheStartupProfile'] as bool?)!,
      enableSoftwareRendering: (json['enableSoftwareRendering'] as bool?)!,
      skiaDeterministicRendering: (json['skiaDeterministicRendering'] as bool?)!,
      traceSkia: (json['traceSkia'] as bool?)!,
      traceAllowlist: json['traceAllowlist'] as String?,
      traceSkiaAllowlist: json['traceSkiaAllowlist'] as String?,
      traceSystrace: (json['traceSystrace'] as bool?)!,
      endlessTraceBuffer: (json['endlessTraceBuffer'] as bool?)!,
      dumpSkpOnShaderCompilation: (json['dumpSkpOnShaderCompilation'] as bool?)!,
      cacheSkSL: (json['cacheSkSL'] as bool?)!,
      purgePersistentCache: (json['purgePersistentCache'] as bool?)!,
      useTestFonts: (json['useTestFonts'] as bool?)!,
      verboseSystemLogs: (json['verboseSystemLogs'] as bool?)!,
      hostVmServicePort: json['hostVmServicePort'] as int? ,
      deviceVmServicePort: json['deviceVmServicePort'] as int?,
      disablePortPublication: (json['disablePortPublication'] as bool?)!,
      ddsPort: json['ddsPort'] as int?,
      devToolsServerAddress: json['devToolsServerAddress'] != null ? Uri.parse(json['devToolsServerAddress']! as String) : null,
      port: json['port'] as String?,
      hostname: json['hostname'] as String?,
      webEnableExposeUrl: json['webEnableExposeUrl'] as bool?,
      webUseSseForDebugProxy: (json['webUseSseForDebugProxy'] as bool?)!,
      webUseSseForDebugBackend: (json['webUseSseForDebugBackend'] as bool?)!,
      webUseSseForInjectedClient: (json['webUseSseForInjectedClient'] as bool?)!,
      webRunHeadless: (json['webRunHeadless'] as bool?)!,
      webBrowserDebugPort: json['webBrowserDebugPort'] as int?,
      webEnableExpressionEvaluation: (json['webEnableExpressionEvaluation'] as bool?)!,
      webLaunchUrl: json['webLaunchUrl'] as String?,
      vmserviceOutFile: json['vmserviceOutFile'] as String?,
      fastStart: (json['fastStart'] as bool?)!,
      nullAssertions: (json['nullAssertions'] as bool?)!,
      nativeNullAssertions: (json['nativeNullAssertions'] as bool?)!,
      enableImpeller: (json['enableImpeller'] as bool?) ?? false,
    );
}

class LaunchResult {
  LaunchResult.succeeded({ this.observatoryUri }) : started = true;
  LaunchResult.failed()
    : started = false,
      observatoryUri = null;

  bool get hasObservatory => observatoryUri != null;

  final bool started;
  final Uri? observatoryUri;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer('started=$started');
    if (observatoryUri != null) {
      buf.write(', observatory=$observatoryUri');
    }
    return buf.toString();
  }
}

/// Read the log for a particular device.
abstract class DeviceLogReader {
  String get name;

  /// A broadcast stream where each element in the string is a line of log output.
  Stream<String> get logLines;

  /// Some logs can be obtained from a VM service stream.
  /// Set this after the VM services are connected.
  FlutterVmService? connectedVMService;

  @override
  String toString() => name;

  /// Process ID of the app on the device.
  int? appPid;

  // Clean up resources allocated by log reader e.g. subprocesses
  void dispose();
}

/// Describes an app running on the device.
class DiscoveredApp {
  DiscoveredApp(this.id, this.observatoryPort);
  final String id;
  final int observatoryPort;
}

// An empty device log reader
class NoOpDeviceLogReader implements DeviceLogReader {
  NoOpDeviceLogReader(String? nameOrNull) : name = nameOrNull ?? '';

  @override
  final String name;

  @override
  int? appPid;

  @override
  FlutterVmService? connectedVMService;

  @override
  Stream<String> get logLines => const Stream<String>.empty();

  @override
  void dispose() { }
}

/// Append --null_assertions to any existing Dart VM flags if
/// [debuggingOptions.nullAssertions] is true.
String computeDartVmFlags(DebuggingOptions debuggingOptions) {
  return <String>[
    if (debuggingOptions.dartFlags.isNotEmpty)
      debuggingOptions.dartFlags,
    if (debuggingOptions.nullAssertions)
      '--null_assertions',
  ].join(',');
}
