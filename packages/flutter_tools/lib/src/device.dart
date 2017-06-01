// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'android/android_device.dart';
import 'application_package.dart';
import 'base/common.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/port_scanner.dart';
import 'base/utils.dart';
import 'build_info.dart';
import 'globals.dart';
import 'ios/devices.dart';
import 'ios/simulators.dart';

DeviceManager get deviceManager => context[DeviceManager];

/// A class to get all available devices.
class DeviceManager {
  /// Constructing DeviceManagers is cheap; they only do expensive work if some
  /// of their methods are called.
  DeviceManager() {
    // Register the known discoverers.
    _deviceDiscoverers.add(new AndroidDevices());
    _deviceDiscoverers.add(new IOSDevices());
    _deviceDiscoverers.add(new IOSSimulators());
  }

  final List<DeviceDiscovery> _deviceDiscoverers = <DeviceDiscovery>[];

  String _specifiedDeviceId;

  /// A user-specified device ID.
  String get specifiedDeviceId {
    if (_specifiedDeviceId == null || _specifiedDeviceId == 'all')
      return null;
    return _specifiedDeviceId;
  }

  set specifiedDeviceId(String id) {
    _specifiedDeviceId = id;
  }

  /// True when the user has specified a single specific device.
  bool get hasSpecifiedDeviceId => specifiedDeviceId != null;

  /// True when the user has specified all devices by setting
  /// specifiedDeviceId = 'all'.
  bool get hasSpecifiedAllDevices => _specifiedDeviceId == 'all';

  Stream<Device> getDevicesById(String deviceId) async* {
    final List<Device> devices = await getAllConnectedDevices().toList();
    deviceId = deviceId.toLowerCase();
    bool exactlyMatchesDeviceId(Device device) =>
        device.id.toLowerCase() == deviceId ||
        device.name.toLowerCase() == deviceId;
    bool startsWithDeviceId(Device device) =>
        device.id.toLowerCase().startsWith(deviceId) ||
        device.name.toLowerCase().startsWith(deviceId);

    final Device exactMatch = devices.firstWhere(
        exactlyMatchesDeviceId, orElse: () => null);
    if (exactMatch != null) {
      yield exactMatch;
      return;
    }

    // Match on a id or name starting with [deviceId].
    for (Device device in devices.where(startsWithDeviceId))
      yield device;
  }

  /// Return the list of connected devices, filtered by any user-specified device id.
  Stream<Device> getDevices() {
    return hasSpecifiedDeviceId
        ? getDevicesById(specifiedDeviceId)
        : getAllConnectedDevices();
  }

  /// Return the list of all connected devices.
  Stream<Device> getAllConnectedDevices() {
    return new Stream<Device>.fromIterable(_deviceDiscoverers
      .where((DeviceDiscovery discoverer) => discoverer.supportsPlatform)
      .expand((DeviceDiscovery discoverer) => discoverer.devices));
  }
}

/// An abstract class to discover and enumerate a specific type of devices.
abstract class DeviceDiscovery {
  bool get supportsPlatform;

  /// Whether this device discovery is capable of listing any devices given the
  /// current environment configuration.
  bool get canListAnything;

  List<Device> get devices;
}

/// A [DeviceDiscovery] implementation that uses polling to discover device adds
/// and removals.
abstract class PollingDeviceDiscovery extends DeviceDiscovery {
  PollingDeviceDiscovery(this.name);

  static const Duration _pollingDuration = const Duration(seconds: 4);

  final String name;
  ItemListNotifier<Device> _items;
  Timer _timer;

  List<Device> pollingGetDevices();

  void startPolling() {
    if (_timer == null) {
      _items ??= new ItemListNotifier<Device>();
      _timer = new Timer.periodic(_pollingDuration, (Timer timer) {
        _items.updateWithNewList(pollingGetDevices());
      });
    }
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  List<Device> get devices {
    _items ??= new ItemListNotifier<Device>.from(pollingGetDevices());
    return _items.items;
  }

  Stream<Device> get onAdded {
    _items ??= new ItemListNotifier<Device>();
    return _items.onAdded;
  }

  Stream<Device> get onRemoved {
    _items ??= new ItemListNotifier<Device>();
    return _items.onRemoved;
  }

  void dispose() => stopPolling();

  @override
  String toString() => '$name device discovery';
}

abstract class Device {
  Device(this.id);

  final String id;

  String get name;

  bool get supportsStartPaused => true;

  /// Whether it is an emulated device running on localhost.
  Future<bool> get isLocalEmulator;

  /// Check if a version of the given app is already installed
  Future<bool> isAppInstalled(ApplicationPackage app);

  /// Check if the latest build of the [app] is already installed.
  Future<bool> isLatestBuildInstalled(ApplicationPackage app);

  /// Install an app package on the current device
  Future<bool> installApp(ApplicationPackage app);

  /// Uninstall an app package from the current device
  Future<bool> uninstallApp(ApplicationPackage app);

  /// Check if the device is supported by Flutter
  bool isSupported();

  // String meant to be displayed to the user indicating if the device is
  // supported by Flutter, and, if not, why.
  String supportMessage() => isSupported() ? "Supported" : "Unsupported";

  /// The device's platform.
  Future<TargetPlatform> get targetPlatform;

  Future<String> get sdkNameAndVersion;

  /// Get a log reader for this device.
  /// If [app] is specified, this will return a log reader specific to that
  /// application. Otherwise, a global log reader will be returned.
  DeviceLogReader getLogReader({ApplicationPackage app});

  /// Get the port forwarder for this device.
  DevicePortForwarder get portForwarder;

  Future<int> forwardPort(int devicePort, {int hostPort}) async {
    try {
      hostPort = await portForwarder
          .forward(devicePort, hostPort: hostPort)
          .timeout(const Duration(seconds: 60), onTimeout: () {
            throw new ToolExit(
                'Timeout while atempting to foward device port $devicePort');
          });
      printTrace('Forwarded host port $hostPort to device port $devicePort');
      return hostPort;
    } catch (e) {
      throw new ToolExit(
          'Unable to forward host port $hostPort to device port $devicePort: $e');
    }
  }

  /// Clear the device's logs.
  void clearLogs();

  /// Start an app package on the current device.
  ///
  /// [platformArgs] allows callers to pass platform-specific arguments to the
  /// start call. The build mode is not used by all platforms.
  Future<LaunchResult> startApp(
    ApplicationPackage package,
    BuildMode mode, {
    String mainPath,
    String route,
    DebuggingOptions debuggingOptions,
    Map<String, dynamic> platformArgs,
    String kernelPath,
    bool prebuiltApplication: false,
    bool applicationNeedsRebuild: false
  });

  /// Does this device implement support for hot reloading / restarting?
  bool get supportsHotMode => true;

  /// Stop an app package on the current device.
  Future<bool> stopApp(ApplicationPackage app);

  bool get supportsScreenshot => false;

  Future<Null> takeScreenshot(File outputFile) => new Future<Null>.error('unimplemented');

  /// Find the apps that are currently running on this device.
  Future<List<DiscoveredApp>> discoverApps() =>
      new Future<List<DiscoveredApp>>.value(<DiscoveredApp>[]);

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! Device)
      return false;
    return id == other.id;
  }

  @override
  String toString() => name;

  static Stream<String> descriptions(List<Device> devices) async* {
    if (devices.isEmpty)
      return;

    // Extract device information
    final List<List<String>> table = <List<String>>[];
    for (Device device in devices) {
      String supportIndicator = device.isSupported() ? '' : ' (unsupported)';
      final TargetPlatform targetPlatform = await device.targetPlatform;
      if (await device.isLocalEmulator) {
        final String type = targetPlatform == TargetPlatform.ios ? 'simulator' : 'emulator';
        supportIndicator += ' ($type)';
      }
      table.add(<String>[
        device.name,
        device.id,
        '${getNameForTargetPlatform(targetPlatform)}',
        '${await device.sdkNameAndVersion}$supportIndicator',
      ]);
    }

    // Calculate column widths
    final List<int> indices = new List<int>.generate(table[0].length - 1, (int i) => i);
    List<int> widths = indices.map((int i) => 0).toList();
    for (List<String> row in table) {
      widths = indices.map((int i) => math.max(widths[i], row[i].length)).toList();
    }

    // Join columns into lines of text
    for (List<String> row in table) {
      yield indices.map((int i) => row[i].padRight(widths[i])).join(' • ') + ' • ${row.last}';
    }
  }

  static Future<Null> printDevices(List<Device> devices) async {
    await descriptions(devices).forEach(printStatus);
  }
}

class DebuggingOptions {
  DebuggingOptions.enabled(this.buildMode, {
    this.startPaused: false,
    this.enableSoftwareRendering: false,
    this.useTestFonts: false,
    this.observatoryPort,
    this.diagnosticPort
   }) : debuggingEnabled = true;

  DebuggingOptions.disabled(this.buildMode) :
    debuggingEnabled = false,
    useTestFonts = false,
    startPaused = false,
    enableSoftwareRendering = false,
    observatoryPort = null,
    diagnosticPort = null;

  final bool debuggingEnabled;

  final BuildMode buildMode;
  final bool startPaused;
  final bool enableSoftwareRendering;
  final bool useTestFonts;
  final int observatoryPort;
  final int diagnosticPort;

  bool get hasObservatoryPort => observatoryPort != null;

  /// Return the user specified observatory port. If that isn't available,
  /// return [kDefaultObservatoryPort], or a port close to that one.
  Future<int> findBestObservatoryPort() {
    if (hasObservatoryPort)
      return new Future<int>.value(observatoryPort);
    return portScanner.findPreferredPort(observatoryPort ?? kDefaultObservatoryPort);
  }

  bool get hasDiagnosticPort => diagnosticPort != null;

  /// Return the user specified diagnostic port. If that isn't available,
  /// return [kDefaultDiagnosticPort], or a port close to that one.
  Future<int> findBestDiagnosticPort() {
    if (hasDiagnosticPort)
      return new Future<int>.value(diagnosticPort);
    return portScanner.findPreferredPort(diagnosticPort ?? kDefaultDiagnosticPort);
  }
}

class LaunchResult {
  LaunchResult.succeeded({ this.observatoryUri, this.diagnosticUri }) : started = true;
  LaunchResult.failed() : started = false, observatoryUri = null, diagnosticUri = null;

  bool get hasObservatory => observatoryUri != null;

  final bool started;
  final Uri observatoryUri;
  final Uri diagnosticUri;

  @override
  String toString() {
    final StringBuffer buf = new StringBuffer('started=$started');
    if (observatoryUri != null)
      buf.write(', observatory=$observatoryUri');
    if (diagnosticUri != null)
      buf.write(', diagnostic=$diagnosticUri');
    return buf.toString();
  }
}

class ForwardedPort {
  ForwardedPort(this.hostPort, this.devicePort) : context = null;
  ForwardedPort.withContext(this.hostPort, this.devicePort, this.context);

  final int hostPort;
  final int devicePort;
  final dynamic context;

  @override
  String toString() => 'ForwardedPort HOST:$hostPort to DEVICE:$devicePort';
}

/// Forward ports from the host machine to the device.
abstract class DevicePortForwarder {
  /// Returns a Future that completes with the current list of forwarded
  /// ports for this device.
  List<ForwardedPort> get forwardedPorts;

  /// Forward [hostPort] on the host to [devicePort] on the device.
  /// If [hostPort] is null, will auto select a host port.
  /// Returns a Future that completes with the host port.
  Future<int> forward(int devicePort, { int hostPort });

  /// Stops forwarding [forwardedPort].
  Future<Null> unforward(ForwardedPort forwardedPort);
}

/// Read the log for a particular device.
abstract class DeviceLogReader {
  String get name;

  /// A broadcast stream where each element in the string is a line of log output.
  Stream<String> get logLines;

  @override
  String toString() => name;

  /// Process ID of the app on the deivce.
  int appPid;
}

/// Describes an app running on the device.
class DiscoveredApp {
  DiscoveredApp(this.id, this.observatoryPort, this.diagnosticPort);
  final String id;
  final int observatoryPort;
  final int diagnosticPort;
}
