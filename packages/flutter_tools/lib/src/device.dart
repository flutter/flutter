// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'application_package.dart';
import 'base/context.dart';
import 'base/dds.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'debugging_options.dart';
import 'devfs.dart';
import 'device_port_forwarder.dart';
import 'device_vm_service_discovery_for_attach.dart';
import 'project.dart';
import 'vmservice.dart';

DeviceManager? get deviceManager => context.get<DeviceManager>();

/// A description of the kind of workflow the device supports.
enum Category {
  web._('web'),
  desktop._('desktop'),
  mobile._('mobile');

  const Category._(this.value);

  final String value;

  @override
  String toString() => value;

  static Category? fromString(String category) {
    return const <String, Category>{'web': web, 'desktop': desktop, 'mobile': mobile}[category];
  }
}

/// The platform sub-folder that a device type supports.
enum PlatformType {
  web,
  android,
  ios,
  linux,
  macos,
  windows,
  fuchsia,
  custom;

  @override
  String toString() => name;

  static PlatformType? fromString(String platformType) => values.asNameMap()[platformType];
}

/// A discovery mechanism for flutter-supported development devices.
abstract class DeviceManager {
  DeviceManager({required Logger logger}) : _logger = logger;

  final Logger _logger;

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

  /// A minimum duration to use when discovering wireless iOS devices.
  static const Duration minimumWirelessDeviceDiscoveryTimeout = Duration(seconds: 5);

  /// True when the user has specified a single specific device.
  bool get hasSpecifiedDeviceId => specifiedDeviceId != null;

  /// True when the user has specified all devices by setting
  /// specifiedDeviceId = 'all'.
  bool get hasSpecifiedAllDevices => _specifiedDeviceId == 'all';

  /// Get devices filtered by [filter] that match the given device id/name.
  ///
  /// If [filter] is not provided, a default filter that requires devices to be
  /// connected will be used.
  ///
  /// If an exact match is found, return it immediately. Otherwise wait for all
  /// discoverers to complete and return any partial matches.
  Future<List<Device>> getDevicesById(String deviceId, {DeviceDiscoveryFilter? filter}) async {
    filter ??= DeviceDiscoveryFilter();

    final String lowerDeviceId = deviceId.toLowerCase();
    bool exactlyMatchesDeviceId(Device device) =>
        device.id.toLowerCase() == lowerDeviceId || device.name.toLowerCase() == lowerDeviceId;
    bool startsWithDeviceId(Device device) =>
        device.id.toLowerCase().startsWith(lowerDeviceId) ||
        device.name.toLowerCase().startsWith(lowerDeviceId);

    // Some discoverers have hard-coded device IDs and return quickly, and others
    // shell out to other processes and can take longer.
    // If an ID was specified, first check if it was a "well-known" device id.
    final Set<String> wellKnownIds =
        _platformDiscoverers.expand((DeviceDiscovery discovery) => discovery.wellKnownIds).toSet();
    final bool hasWellKnownId = hasSpecifiedDeviceId && wellKnownIds.contains(specifiedDeviceId);

    // Process discoverers as they can return results, so if an exact match is
    // found quickly, we don't wait for all the discoverers to complete.
    final List<Device> prefixMatches = <Device>[];
    final Completer<Device> exactMatchCompleter = Completer<Device>();
    final List<Future<List<Device>?>> futureDevices = <Future<List<Device>?>>[
      for (final DeviceDiscovery discoverer in _platformDiscoverers)
        if (!hasWellKnownId || discoverer.wellKnownIds.contains(specifiedDeviceId))
          discoverer
              .devices(filter: filter)
              .then(
                (List<Device> devices) {
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
                },
                onError: (dynamic error, StackTrace stackTrace) {
                  // Return matches from other discoverers even if one fails.
                  _logger.printTrace('Ignored error discovering $deviceId: $error');
                },
              ),
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

  /// Returns a list of devices filtered by the user-specified device
  /// id/name (if applicable) and [filter].
  ///
  /// If [filter] is not provided, a default filter that requires devices to be
  /// connected will be used.
  Future<List<Device>> getDevices({DeviceDiscoveryFilter? filter}) {
    filter ??= DeviceDiscoveryFilter();
    final String? id = specifiedDeviceId;
    if (id == null) {
      return getAllDevices(filter: filter);
    }
    return getDevicesById(id, filter: filter);
  }

  Iterable<DeviceDiscovery> get _platformDiscoverers {
    return deviceDiscoverers.where((DeviceDiscovery discoverer) => discoverer.supportsPlatform);
  }

  /// Returns a list of devices filtered by [filter].
  ///
  /// If [filter] is not provided, a default filter that requires devices to be
  /// connected will be used.
  Future<List<Device>> getAllDevices({DeviceDiscoveryFilter? filter}) async {
    filter ??= DeviceDiscoveryFilter();
    final List<List<Device>> devices = await Future.wait<List<Device>>(<Future<List<Device>>>[
      for (final DeviceDiscovery discoverer in _platformDiscoverers)
        discoverer.devices(filter: filter),
    ]);

    return devices.expand<Device>((List<Device> deviceList) => deviceList).toList();
  }

  /// Returns a list of devices filtered by [filter]. Discards existing cache of devices.
  ///
  /// If [filter] is not provided, a default filter that requires devices to be
  /// connected will be used.
  ///
  /// Search for devices to populate the cache for no longer than [timeout].
  Future<List<Device>> refreshAllDevices({Duration? timeout, DeviceDiscoveryFilter? filter}) async {
    filter ??= DeviceDiscoveryFilter();
    final List<List<Device>> devices = await Future.wait<List<Device>>(<Future<List<Device>>>[
      for (final DeviceDiscovery discoverer in _platformDiscoverers)
        discoverer.discoverDevices(filter: filter, timeout: timeout),
    ]);

    return devices.expand<Device>((List<Device> deviceList) => deviceList).toList();
  }

  /// Discard existing cache of discoverers that are known to take longer to
  /// discover wireless devices.
  ///
  /// Then, search for devices for those discoverers to populate the cache for
  /// no longer than [timeout].
  Future<void> refreshExtendedWirelessDeviceDiscoverers({
    Duration? timeout,
    DeviceDiscoveryFilter? filter,
  }) async {
    await Future.wait<List<Device>>(<Future<List<Device>>>[
      for (final DeviceDiscovery discoverer in _platformDiscoverers)
        if (discoverer.requiresExtendedWirelessDeviceDiscovery)
          discoverer.discoverDevices(timeout: timeout),
    ]);
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

  /// Determines how to filter devices.
  ///
  /// By default, filters to only include devices that are supported by Flutter.
  ///
  /// If the user has not specified a device, filters to only include devices
  /// that are supported by Flutter and supported by the project.
  ///
  /// If the user has specified `--device all`, filters to only include devices
  /// that are supported by Flutter, supported by the project, and supported for `all`.
  ///
  /// If [includeDevicesUnsupportedByProject] is true, all devices will be
  /// considered supported by the project, regardless of user specifications.
  ///
  /// This also exists to allow the check to be overridden for google3 clients.
  DeviceDiscoverySupportFilter deviceSupportFilter({
    bool includeDevicesUnsupportedByProject = false,
  }) {
    FlutterProject? flutterProject;
    if (!includeDevicesUnsupportedByProject) {
      flutterProject = FlutterProject.current();
    }
    if (hasSpecifiedAllDevices) {
      return DeviceDiscoverySupportFilter.excludeDevicesUnsupportedByFlutterOrProjectOrAll(
        flutterProject: flutterProject,
      );
    } else if (!hasSpecifiedDeviceId) {
      return DeviceDiscoverySupportFilter.excludeDevicesUnsupportedByFlutterOrProject(
        flutterProject: flutterProject,
      );
    } else {
      return DeviceDiscoverySupportFilter.excludeDevicesUnsupportedByFlutter();
    }
  }

  /// If the user did not specify to run all or a specific device, then attempt
  /// to prioritize ephemeral devices.
  ///
  /// If there is not exactly one ephemeral device return null.
  ///
  /// For example, if the user only typed 'flutter run' and both an Android
  /// device and desktop device are available, choose the Android device.
  ///
  /// Note: ephemeral is nullable for device types where this is not well
  /// defined.
  Device? getSingleEphemeralDevice(List<Device> devices) {
    if (!hasSpecifiedDeviceId) {
      try {
        return devices.singleWhere((Device device) => device.ephemeral);
      } on StateError {
        return null;
      }
    }
    return null;
  }
}

/// A class for determining how to filter devices based on if they are supported.
class DeviceDiscoverySupportFilter {
  /// Filter devices to only include those supported by Flutter.
  DeviceDiscoverySupportFilter.excludeDevicesUnsupportedByFlutter()
    : _excludeDevicesNotSupportedByProject = false,
      _excludeDevicesNotSupportedByAll = false,
      _flutterProject = null;

  /// Filter devices to only include those supported by Flutter and the
  /// provided [flutterProject].
  ///
  /// If [flutterProject] is null, all devices will be considered supported by
  /// the project.
  DeviceDiscoverySupportFilter.excludeDevicesUnsupportedByFlutterOrProject({
    required FlutterProject? flutterProject,
  }) : _flutterProject = flutterProject,
       _excludeDevicesNotSupportedByProject = true,
       _excludeDevicesNotSupportedByAll = false;

  /// Filter devices to only include those supported by Flutter, the provided
  /// [flutterProject], and `--device all`.
  ///
  /// If [flutterProject] is null, all devices will be considered supported by
  /// the project.
  DeviceDiscoverySupportFilter.excludeDevicesUnsupportedByFlutterOrProjectOrAll({
    required FlutterProject? flutterProject,
  }) : _flutterProject = flutterProject,
       _excludeDevicesNotSupportedByProject = true,
       _excludeDevicesNotSupportedByAll = true;

  final FlutterProject? _flutterProject;
  final bool _excludeDevicesNotSupportedByProject;
  final bool _excludeDevicesNotSupportedByAll;

  Future<bool> matchesRequirements(Device device) async {
    final bool meetsSupportByFlutterRequirement = device.isSupported();
    final bool meetsSupportForProjectRequirement =
        !_excludeDevicesNotSupportedByProject || isDeviceSupportedForProject(device);
    final bool meetsSupportForAllRequirement =
        !_excludeDevicesNotSupportedByAll || await isDeviceSupportedForAll(device);

    return meetsSupportByFlutterRequirement &&
        meetsSupportForProjectRequirement &&
        meetsSupportForAllRequirement;
  }

  /// User has specified `--device all`.
  ///
  /// Always remove web and fuchsia devices from `all`. This setting
  /// currently requires devices to share a frontend_server and resident
  /// runner instance. Both web and fuchsia require differently configured
  /// compilers, and web requires an entirely different resident runner.
  Future<bool> isDeviceSupportedForAll(Device device) async {
    final TargetPlatform devicePlatform = await device.targetPlatform;
    return device.isSupported() &&
        devicePlatform != TargetPlatform.fuchsia_arm64 &&
        devicePlatform != TargetPlatform.fuchsia_x64 &&
        devicePlatform != TargetPlatform.web_javascript &&
        isDeviceSupportedForProject(device);
  }

  /// Returns whether the device is supported for the project.
  ///
  /// A device can be supported by Flutter but not supported for the project
  /// (e.g. when the user has removed the iOS directory from their project).
  ///
  /// This also exists to allow the check to be overridden for google3 clients. If
  /// [_flutterProject] is null then return true.
  bool isDeviceSupportedForProject(Device device) {
    if (!device.isSupported()) {
      return false;
    }
    if (_flutterProject == null) {
      return true;
    }
    return device.isSupportedForProject(_flutterProject);
  }
}

/// A class for filtering devices.
///
/// If [excludeDisconnected] is true, only devices detected as connected will be included.
///
/// If [supportFilter] is provided, only devices matching the requirements will be included.
///
/// If [deviceConnectionInterface] is provided, only devices matching the DeviceConnectionInterface will be included.
class DeviceDiscoveryFilter {
  DeviceDiscoveryFilter({
    this.excludeDisconnected = true,
    this.supportFilter,
    this.deviceConnectionInterface,
  });

  final bool excludeDisconnected;
  final DeviceDiscoverySupportFilter? supportFilter;
  final DeviceConnectionInterface? deviceConnectionInterface;

  Future<bool> matchesRequirements(Device device) async {
    final DeviceDiscoverySupportFilter? localSupportFilter = supportFilter;

    final bool meetsConnectionRequirement = !excludeDisconnected || device.isConnected;
    final bool meetsSupportRequirements =
        localSupportFilter == null || (await localSupportFilter.matchesRequirements(device));
    final bool meetsConnectionInterfaceRequirement = matchesDeviceConnectionInterface(
      device,
      deviceConnectionInterface,
    );

    return meetsConnectionRequirement &&
        meetsSupportRequirements &&
        meetsConnectionInterfaceRequirement;
  }

  Future<List<Device>> filterDevices(List<Device> devices) async {
    devices = <Device>[
      for (final Device device in devices)
        if (await matchesRequirements(device)) device,
    ];
    return devices;
  }

  bool matchesDeviceConnectionInterface(
    Device device,
    DeviceConnectionInterface? deviceConnectionInterface,
  ) {
    if (deviceConnectionInterface == null) {
      return true;
    }
    return device.connectionInterface == deviceConnectionInterface;
  }
}

/// An abstract class to discover and enumerate a specific type of devices.
abstract class DeviceDiscovery {
  bool get supportsPlatform;

  /// Whether this device discovery is capable of listing any devices given the
  /// current environment configuration.
  bool get canListAnything;

  /// Whether this device discovery is known to take longer to discover
  /// wireless devices.
  bool get requiresExtendedWirelessDeviceDiscovery => false;

  /// Return all connected devices, cached on subsequent calls.
  Future<List<Device>> devices({DeviceDiscoveryFilter? filter});

  /// Return all connected devices. Discards existing cache of devices.
  Future<List<Device>> discoverDevices({Duration? timeout, DeviceDiscoveryFilter? filter});

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
  final ItemListNotifier<Device> deviceNotifier = ItemListNotifier<Device>();

  Timer? _timer;

  Future<List<Device>> pollingGetDevices({Duration? timeout});

  void startPolling() {
    // Make initial population the default, fast polling timeout.
    _timer ??= _initTimer(null, initialCall: true);
  }

  Timer _initTimer(Duration? pollingTimeout, {bool initialCall = false}) {
    // Poll for devices immediately on the initial call for faster initial population.
    return Timer(initialCall ? Duration.zero : _pollingInterval, () async {
      try {
        final List<Device> devices = await pollingGetDevices(timeout: pollingTimeout);
        deviceNotifier.updateWithNewList(devices);
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

  /// Get devices from cache filtered by [filter].
  ///
  /// If the cache is empty, populate the cache.
  ///
  /// If [filter] is null, it may return devices that are not connected.
  @override
  Future<List<Device>> devices({DeviceDiscoveryFilter? filter}) {
    return _populateDevices(filter: filter);
  }

  /// Empty the cache and repopulate it before getting devices from cache filtered by [filter].
  ///
  /// Search for devices to populate the cache for no longer than [timeout].
  ///
  /// If [filter] is null, it may return devices that are not connected.
  @override
  Future<List<Device>> discoverDevices({Duration? timeout, DeviceDiscoveryFilter? filter}) {
    return _populateDevices(timeout: timeout, filter: filter, resetCache: true);
  }

  /// Get devices from cache filtered by [filter].
  ///
  /// If the cache is empty or [resetCache] is true, populate the cache.
  ///
  /// Search for devices to populate the cache for no longer than [timeout].
  Future<List<Device>> _populateDevices({
    Duration? timeout,
    DeviceDiscoveryFilter? filter,
    bool resetCache = false,
  }) async {
    if (!deviceNotifier.isPopulated || resetCache) {
      final List<Device> devices = await pollingGetDevices(timeout: timeout);
      // If the cache was populated while the polling was ongoing, do not
      // overwrite the cache unless it's explicitly refreshing the cache.
      if (!deviceNotifier.isPopulated || resetCache) {
        deviceNotifier.updateWithNewList(devices);
      }
    }

    // If a filter is provided, filter cache to only return devices matching.
    if (filter != null) {
      return filter.filterDevices(deviceNotifier.items);
    }
    return deviceNotifier.items;
  }

  Stream<Device> get onAdded {
    return deviceNotifier.onAdded;
  }

  Stream<Device> get onRemoved {
    return deviceNotifier.onRemoved;
  }

  void dispose() => stopPolling();

  @override
  String toString() => '$name device discovery';
}

/// Returns the `DeviceConnectionInterface` enum based on its string name.
DeviceConnectionInterface getDeviceConnectionInterfaceForName(String name) {
  return switch (name) {
    'attached' => DeviceConnectionInterface.attached,
    'wireless' => DeviceConnectionInterface.wireless,
    _ => throw Exception('Unsupported DeviceConnectionInterface name "$name"'),
  };
}

/// Returns a `DeviceConnectionInterface`'s string name.
String getNameForDeviceConnectionInterface(DeviceConnectionInterface connectionInterface) {
  return switch (connectionInterface) {
    DeviceConnectionInterface.attached => 'attached',
    DeviceConnectionInterface.wireless => 'wireless',
  };
}

/// A device is a physical hardware that can run a Flutter application.
///
/// This may correspond to a connected iOS or Android device, or represent
/// the host operating system in the case of Flutter Desktop.
abstract class Device {
  Device(
    this.id, {
    required Logger logger,
    required this.category,
    required this.platformType,
    required this.ephemeral,
  }) : dds = DartDevelopmentService(logger: logger);

  final String id;

  /// The [Category] for this device type.
  final Category? category;

  /// The [PlatformType] for this device.
  final PlatformType? platformType;

  /// Whether this is an ephemeral device.
  final bool ephemeral;

  bool get isConnected => true;

  DeviceConnectionInterface get connectionInterface => DeviceConnectionInterface.attached;

  bool get isWirelesslyConnected => connectionInterface == DeviceConnectionInterface.wireless;

  String get name;

  String get displayName {
    String result = name;
    if (isWirelesslyConnected) {
      result += ' (wireless)';
    }
    return result;
  }

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
  Future<bool> isAppInstalled(ApplicationPackage app, {String? userIdentifier});

  /// Check if the latest build of the [app] is already installed.
  Future<bool> isLatestBuildInstalled(ApplicationPackage app);

  /// Install an app package on the current device.
  ///
  /// Specify [userIdentifier] to install for a particular user (Android only).
  Future<bool> installApp(ApplicationPackage app, {String? userIdentifier});

  /// Uninstall an app package from the current device.
  ///
  /// Specify [userIdentifier] to uninstall for a particular user,
  /// defaults to all users (Android only).
  Future<bool> uninstallApp(ApplicationPackage app, {String? userIdentifier});

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
  DevFSWriter? createDevFSWriter(ApplicationPackage? app, String? userIdentifier) {
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
  FutureOr<DeviceLogReader> getLogReader({ApplicationPackage? app, bool includePastLogs = false});

  /// Get the port forwarder for this device.
  DevicePortForwarder? get portForwarder;

  /// Get the DDS instance for this device.
  final DartDevelopmentService dds;

  /// Clear the device's logs.
  void clearLogs();

  /// Get the [VMServiceDiscoveryForAttach] instance for this device, which
  /// discovers, and forwards any necessary ports to the vm service uri of a
  /// running app on the device.
  ///
  /// If `appId` is specified, on supported platforms, the service discovery
  /// will only return the VM service URI from the given app.
  ///
  /// If `fuchsiaModule` is specified, this will only return the VM service uri
  /// from the specified Fuchsia module.
  ///
  /// If `filterDevicePort` is specified, this will only return the VM service
  /// uri that matches the given port on the device.
  VMServiceDiscoveryForAttach getVMServiceDiscoveryForAttach({
    String? appId,
    String? fuchsiaModule,
    int? filterDevicePort,
    int? expectedHostPort,
    required bool ipv6,
    required Logger logger,
  }) => LogScanningVMServiceDiscoveryForAttach(
    Future<DeviceLogReader>.value(getLogReader()),
    portForwarder: portForwarder,
    devicePort: filterDevicePort,
    hostPort: expectedHostPort,
    ipv6: ipv6,
    logger: logger,
  );

  /// Start an app package on the current device.
  ///
  /// [platformArgs] allows callers to pass platform-specific arguments to the
  /// start call. The build mode is not used by all platforms.
  Future<LaunchResult> startApp(
    covariant ApplicationPackage? package, {
    String? mainPath,
    String? route,
    required DebuggingOptions debuggingOptions,
    Map<String, Object?> platformArgs,
    bool prebuiltApplication = false,
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

  /// Whether the Flavors feature ('--flavor') is supported for this device.
  bool get supportsFlavors => false;

  /// Stop an app package on the current device.
  ///
  /// Specify [userIdentifier] to stop app installed to a profile (Android only).
  Future<bool> stopApp(ApplicationPackage? app, {String? userIdentifier});

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
    return other is Device && other.id == id;
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
        '${device.displayName} (${device.category})',
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
        indices
            .map<String>((int i) => row[i].padRight(widths[i]))
            .followedBy(<String>[row.last])
            .join(' • '),
    ];
  }

  static Future<void> printDevices(
    List<Device> devices,
    Logger logger, {
    String prefix = '',
  }) async {
    for (final String line in await descriptions(devices)) {
      logger.printStatus('$prefix$line');
    }
  }

  static List<String> devicesPlatformTypes(List<Device> devices) {
    return devices.map((Device d) => d.platformType.toString()).toSet().toList()..sort();
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
      },
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

class LaunchResult {
  LaunchResult.succeeded({this.vmServiceUri}) : started = true;

  LaunchResult.failed() : started = false, vmServiceUri = null;

  bool get hasVmService => vmServiceUri != null;

  final bool started;
  final Uri? vmServiceUri;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer('started=$started');
    if (vmServiceUri != null) {
      buf.write(', vmService=$vmServiceUri');
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
  Future<void> provideVmService(FlutterVmService connectedVmService);

  @override
  String toString() => name;

  // Clean up resources allocated by log reader e.g. subprocesses
  void dispose();
}

/// Describes an app running on the device.
class DiscoveredApp {
  DiscoveredApp(this.id, this.vmServicePort);
  final String id;
  final int vmServicePort;
}

// An empty device log reader
class NoOpDeviceLogReader implements DeviceLogReader {
  NoOpDeviceLogReader(String? nameOrNull) : name = nameOrNull ?? '';

  @override
  final String name;

  @override
  Stream<String> get logLines => const Stream<String>.empty();

  @override
  void dispose() {}

  @override
  Future<void> provideVmService(FlutterVmService connectedVmService) async {}
}
