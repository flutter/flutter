// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../convert.dart';
import '../device.dart';
import '../macos/xcode.dart';

/// A wrapper around the `devicectl` command line tool.
///
/// CoreDevice is a device connectivity stack introduced in Xcode 15. Devices
/// with iOS 17 or greater are CoreDevices.
///
/// `devicectl` (CoreDevice Device Control) is an Xcode CLI tool used for
/// interacting with CoreDevices.
class IOSCoreDeviceControl {
  IOSCoreDeviceControl({
    required Logger logger,
    required ProcessUtils processUtils,
    required Xcode xcode,
    required FileSystem fileSystem,
  })  : _logger = logger,
        _processUtils = processUtils,
        _xcode = xcode,
        _fileSystem = fileSystem;

  final Logger _logger;
  final ProcessUtils _processUtils;
  final Xcode _xcode;
  final FileSystem _fileSystem;

  /// When the `--timeout` flag is used with `devicectl`, it must be at
  /// least 5 seconds. If lower than 5 seconds, `devicectl` will error and not
  /// run the command.
  static const int _minimumTimeoutInSeconds = 5;

  /// Executes `devicectl` command to get list of devices. The command will
  /// likely complete before [timeout] is reached. If [timeout] is reached,
  /// the command will be stopped as a failure.
  Future<List<Object?>> _listCoreDevices({
    Duration timeout = const Duration(seconds: _minimumTimeoutInSeconds),
  }) async {
    if (!_xcode.isDevicectlInstalled) {
      _logger.printTrace('devicectl is not installed.');
      return <Object?>[];
    }

    // Default to minimum timeout if needed to prevent error.
    Duration validTimeout = timeout;
    if (timeout.inSeconds < _minimumTimeoutInSeconds) {
      _logger.printTrace(
          'Timeout of ${timeout.inSeconds} seconds is below the minimum timeout value '
          'for devicectl. Changing the timeout to the minimum value of $_minimumTimeoutInSeconds.');
      validTimeout = const Duration(seconds: _minimumTimeoutInSeconds);
    }

    final Directory tempDirectory = _fileSystem.systemTempDirectory.createTempSync('core_devices.');
    final File output = tempDirectory.childFile('core_device_list.json');
    output.createSync();

    final List<String> command = <String>[
      ..._xcode.xcrunCommand(),
      'devicectl',
      'list',
      'devices',
      '--timeout',
      validTimeout.inSeconds.toString(),
      '--json-output',
      output.path,
    ];

    final RunResult results = await _processUtils.run(command);
    if (results.exitCode != 0) {
      _logger.printTrace('Error executing devicectl: ${results.exitCode}\n${results.stderr}');
      return <Object?>[];
    }

    final String stringOutput = output.readAsStringSync();

    try {
      final Object? decodeResult = (json.decode(stringOutput) as Map<String, Object?>)['result'];
      if (decodeResult is Map<String, Object?>) {
        final Object? decodeDevices = decodeResult['devices'];
        if (decodeDevices is List<Object?>) {
          return decodeDevices;
        }
      }
      _logger.printTrace('devicectl returned unexpected JSON response: $stringOutput');
      return <Object?>[];
    } on FormatException {
      // We failed to parse the devicectl output, or it returned junk.
      _logger.printTrace('devicectl returned non-JSON response: $stringOutput');
      return <Object?>[];
    } finally {
      tempDirectory.deleteSync(recursive: true);
    }
  }

  Future<List<IOSCoreDevice>> getCoreDevices({
    Duration timeout = const Duration(seconds: _minimumTimeoutInSeconds),
  }) async {
    final List<IOSCoreDevice> devices = <IOSCoreDevice>[];

    final List<Object?> devicesSection = await _listCoreDevices(timeout: timeout);
    for (final Object? deviceObject in devicesSection) {
      if (deviceObject is Map<String, Object?>) {
        devices.add(IOSCoreDevice(deviceObject, logger: _logger));
      }
    }
    return devices;
  }
}

class IOSCoreDevice {
  IOSCoreDevice(
    Map<String, Object?> data, {
    required Logger logger,
  })  : _data = data,
        _logger = logger;

  /// Example:
  /// {
  ///   "capabilities" : [
  ///   ],
  ///   "connectionProperties" : {
  ///   },
  ///   "deviceProperties" : {
  ///   },
  ///   "hardwareProperties" : {
  ///   },
  ///   "identifier" : "123456BB5-AEDE-7A22-B890-1234567890DD",
  ///   "visibilityClass" : "default"
  /// }
  final Map<String, Object?> _data;
  final Logger _logger;

  String? get udid => hardwareProperties?.udid;

  DeviceConnectionInterface? get connectionInterface {
    final String? transportType = connectionProperties?.transportType;
    if (transportType != null) {
      if (transportType.toLowerCase() == 'localnetwork') {
        return DeviceConnectionInterface.wireless;
      } else if (transportType.toLowerCase() == 'wired') {
        return DeviceConnectionInterface.attached;
      }
    }
    return null;
  }

  @visibleForTesting
  List<IOSCoreDeviceCapability> get capabilities {
    final List<IOSCoreDeviceCapability> capabilitiesList = <IOSCoreDeviceCapability>[];
    if (_data['capabilities'] is List<Object?>) {
      final List<Object?> capabilitiesData = _data['capabilities']! as List<Object?>;
      for (final Object? capabilityData in capabilitiesData) {
        if (capabilityData != null && capabilityData is Map<String, Object?>) {
          capabilitiesList.add(IOSCoreDeviceCapability(capabilityData));
        }
      }
    }
    return capabilitiesList;
  }

  @visibleForTesting
  IOSCoreDeviceConnectionProperties? get connectionProperties {
    if (_data['connectionProperties'] is Map<String, Object?>) {
      final Map<String, Object?> connectionPropertiesData = _data['connectionProperties']! as Map<String, Object?>;
      return IOSCoreDeviceConnectionProperties(
        connectionPropertiesData,
        logger: _logger,
      );
    }
    return null;
  }

  @visibleForTesting
  IOSCoreDeviceProperties? get deviceProperties {
    if (_data['deviceProperties'] is Map<String, Object?>) {
      final Map<String, Object?> devicePropertiesData = _data['deviceProperties']! as Map<String, Object?>;
      return IOSCoreDeviceProperties(devicePropertiesData);
    }
    return null;
  }

  @visibleForTesting
  IOSCoreDeviceHardwareProperties? get hardwareProperties {
    if (_data['hardwareProperties'] is Map<String, Object?>) {
      final Map<String, Object?> hardwarePropertiesData = _data['hardwareProperties']! as Map<String, Object?>;
      return IOSCoreDeviceHardwareProperties(
        hardwarePropertiesData,
        logger: _logger,
      );
    }
    return null;
  }

  /// This is not the UDID of the device.
  String? get coreDeviceIdentifer => _data['identifier']?.toString();

  String? get visibilityClass => _data['visibilityClass']?.toString();
}

class IOSCoreDeviceCapability {
  IOSCoreDeviceCapability(
    Map<String, Object?> data,
  ) : _data = data;

  /// Example:
  /// "capabilities" : [
  ///   {
  ///     "featureIdentifier" : "com.apple.coredevice.feature.spawnexecutable",
  ///     "name" : "Spawn Executable"
  ///   },
  ///   {
  ///     "featureIdentifier" : "com.apple.coredevice.feature.launchapplication",
  ///     "name" : "Launch Application"
  ///   }
  /// ]
  final Map<String, Object?> _data;

  String? get featureIdentifier => _data['featureIdentifier']?.toString();
  String? get name => _data['name']?.toString();
}

class IOSCoreDeviceConnectionProperties {
  IOSCoreDeviceConnectionProperties(
    Map<String, Object?> data, {
    required Logger logger,
  })  : _data = data,
        _logger = logger;

  /// Example:
  /// "connectionProperties" : {
  ///   "authenticationType" : "manualPairing",
  ///   "isMobileDeviceOnly" : false,
  ///   "lastConnectionDate" : "2023-06-15T15:29:00.082Z",
  ///   "localHostnames" : [
  ///     "iPadName.coredevice.local",
  ///     "00001234-0001234A3C03401E.coredevice.local",
  ///     "12345BB5-AEDE-4A22-B653-6037262550DD.coredevice.local"
  ///   ],
  ///   "pairingState" : "paired",
  ///   "potentialHostnames" : [
  ///     "00001234-0001234A3C03401E.coredevice.local",
  ///     "12345BB5-AEDE-4A22-B653-6037262550DD.coredevice.local"
  ///   ],
  ///   "transportType" : "wired",
  ///   "tunnelIPAddress" : "fdf1:23c4:cd56::1",
  ///   "tunnelState" : "connected",
  ///   "tunnelTransportProtocol" : "tcp"
  /// }
  final Map<String, Object?> _data;
  final Logger _logger;

  String? get authenticationType => _data['authenticationType']?.toString();
  bool? get isMobileDeviceOnly {
    if (_data['isMobileDeviceOnly'] is bool?) {
      return _data['isMobileDeviceOnly'] as bool?;
    }
    return null;
  }

  String? get lastConnectionDate => _data['lastConnectionDate']?.toString();
  List<String>? get localHostnames {
    if (_data['localHostnames'] is List<Object?>) {
      final List<Object?> values = _data['localHostnames']! as List<Object?>;
      try {
        return List<String>.from(values);
      } on TypeError {
        _logger.printTrace('Error parsing localHostnames value: $values');
      }
    }
    return null;
  }

  String? get pairingState => _data['pairingState']?.toString();
  List<String>? get potentialHostnames {
    if (_data['potentialHostnames'] is List<Object?>) {
      final List<Object?> values = _data['potentialHostnames']! as List<Object?>;
      try {
        return List<String>.from(values);
      } on TypeError {
        _logger.printTrace('Error parsing potentialHostnames value: $values');
      }
    }
    return null;
  }

  /// When [transportType] is not null, values may be `wired` or `localNetwork`.
  String? get transportType => _data['transportType']?.toString();
  String? get tunnelIPAddress => _data['tunnelIPAddress']?.toString();
  String? get tunnelState => _data['tunnelState']?.toString();
  String? get tunnelTransportProtocol => _data['tunnelTransportProtocol']?.toString();
}

class IOSCoreDeviceProperties {
  IOSCoreDeviceProperties(
    Map<String, Object?> data,
  ) : _data = data;

  /// Example:
  /// "deviceProperties" : {
  ///   "bootedFromSnapshot" : true,
  ///   "bootedSnapshotName" : "com.apple.os.update-B5336980824124F599FD39FE91016493A74331B09F475250BB010B276FE2439E3DE3537349A3A957D3FF2A4B623B4ECC",
  ///   "bootState" : "booted",
  ///   "ddiServicesAvailable" : true,
  ///   "developerModeStatus" : "enabled",
  ///   "hasInternalOSBuild" : false,
  ///   "name" : "iPadName",
  ///   "osBuildUpdate" : "21A5248v",
  ///   "osVersionNumber" : "17.0",
  ///   "rootFileSystemIsWritable" : false,
  ///   "screenViewingURL" : "coredevice-devices:/viewDeviceByUUID?uuid=123456BB5-AEDE-7A22-B890-1234567890DD"
  /// }
  final Map<String, Object?> _data;

  bool? get bootedFromSnapshot {
    if (_data['bootedFromSnapshot'] is bool?) {
      return _data['bootedFromSnapshot'] as bool?;
    }
    return null;
  }

  String? get bootedSnapshotName => _data['bootedSnapshotName']?.toString();
  String? get bootState => _data['bootState']?.toString();
  bool? get ddiServicesAvailable {
    if (_data['ddiServicesAvailable'] is bool?) {
      return _data['ddiServicesAvailable'] as bool?;
    }
    return null;
  }

  String? get developerModeStatus => _data['developerModeStatus']?.toString();
  bool? get hasInternalOSBuild {
    if (_data['hasInternalOSBuild'] is bool?) {
      return _data['hasInternalOSBuild'] as bool?;
    }
    return null;
  }

  String? get name => _data['name']?.toString();
  String? get osBuildUpdate => _data['osBuildUpdate']?.toString();
  String? get osVersionNumber => _data['osVersionNumber']?.toString();
  bool? get rootFileSystemIsWritable {
    if (_data['rootFileSystemIsWritable'] is bool?) {
      return _data['rootFileSystemIsWritable'] as bool?;
    }
    return null;
  }

  String? get screenViewingURL => _data['screenViewingURL']?.toString();
}

class IOSCoreDeviceHardwareProperties {
  IOSCoreDeviceHardwareProperties(
    Map<String, Object?> data, {
    required Logger logger,
  })  : _data = data,
        _logger = logger;

  /// Example:
  /// "hardwareProperties" : {
  ///   "cpuType" : {
  ///     "name" : "arm64e",
  ///     "subType" : 2,
  ///     "type" : 16777228
  ///   },
  ///   "deviceType" : "iPad",
  ///   "ecid" : 12345678903408542,
  ///   "hardwareModel" : "J617AP",
  ///   "internalStorageCapacity" : 128000000000,
  ///   "marketingName" : "iPad Pro (11-inch) (4th generation)\"",
  ///   "platform" : "iOS",
  ///   "productType" : "iPad14,3",
  ///   "serialNumber" : "HC123DHCQV",
  ///   "supportedCPUTypes" : [
  ///     {
  ///       "name" : "arm64e",
  ///       "subType" : 2,
  ///       "type" : 16777228
  ///     },
  ///     {
  ///       "name" : "arm64",
  ///       "subType" : 0,
  ///       "type" : 16777228
  ///     }
  ///   ],
  ///   "supportedDeviceFamilies" : [
  ///     1,
  ///     2
  ///   ],
  ///   "thinningProductType" : "iPad14,3-A",
  ///   "udid" : "00001234-0001234A3C03401E"
  /// }
  final Map<String, Object?> _data;
  final Logger _logger;

  IOSCoreDeviceCPUType? get cpuType {
    if (_data['cpuType'] is Map<String, Object?>) {
      return IOSCoreDeviceCPUType(_data['cpuType']! as Map<String, Object?>);
    }
    return null;
  }

  String? get deviceType => _data['deviceType']?.toString();
  int? get ecid {
    if (_data['ecid'] is int?) {
      return _data['ecid'] as int?;
    }
    return null;
  }

  String? get hardwareModel => _data['hardwareModel']?.toString();
  int? get internalStorageCapacity {
    if (_data['internalStorageCapacity'] is int?) {
      return _data['internalStorageCapacity'] as int?;
    }
    return null;
  }

  String? get marketingName => _data['marketingName']?.toString();
  String? get platform => _data['platform']?.toString();
  String? get productType => _data['productType']?.toString();
  String? get serialNumber => _data['serialNumber']?.toString();
  List<IOSCoreDeviceCPUType>? get supportedCPUTypes {
    if (_data['supportedCPUTypes'] is List<Object?>) {
      final List<Object?> values = _data['supportedCPUTypes']! as List<Object?>;
      final List<IOSCoreDeviceCPUType> cpuTypes = <IOSCoreDeviceCPUType>[];
      for (final Object? cpuTypeData in values) {
        if (cpuTypeData is Map<String, Object?>) {
          cpuTypes.add(IOSCoreDeviceCPUType(cpuTypeData));
        }
      }
      return cpuTypes;
    }
    return null;
  }

  List<int>? get supportedDeviceFamilies {
    if (_data['supportedDeviceFamilies'] is List<Object?>) {
      final List<Object?> values = _data['supportedDeviceFamilies']! as List<Object?>;
      try {
        return List<int>.from(values);
      } on TypeError {
        _logger.printTrace('Error parsing supportedDeviceFamilies value: $values');
      }
    }
    return null;
  }

  String? get thinningProductType => _data['thinningProductType']?.toString();
  String? get udid => _data['udid']?.toString();
}

class IOSCoreDeviceCPUType {
  IOSCoreDeviceCPUType(
    Map<String, Object?> data,
  ) : _data = data;

  /// Example:
  /// "cpuType" : {
  ///   "name" : "arm64e",
  ///   "subType" : 2,
  ///   "type" : 16777228
  /// }
  final Map<String, Object?> _data;

  String? get name => _data['name']?.toString();
  int? get subType {
    if (_data['subType'] is int?) {
      return _data['subType'] as int?;
    }
    return null;
  }

  int? get cpuType {
    if (_data['type'] is int?) {
      return _data['type'] as int?;
    }
    return null;
  }
}
