// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/logger.dart';
import '../base/user_messages.dart';
import '../device.dart';
import '../globals.dart' as globals;

const String _wirelesslyConnectedDevicesMessage = 'Wirelessly connected devices:';

/// This class handles functionality of finding and selecting target devices.
///
/// Target devices are devices that are supported and selectable to run
/// a flutter application on.
class TargetDevices {
  TargetDevices({
    required DeviceManager deviceManager,
    required Logger logger,
  })  : _deviceManager = deviceManager,
        _logger = logger;

  final DeviceManager _deviceManager;
  final Logger _logger;

  Future<List<Device>> _getAttachedDevices({
    DeviceDiscoverySupportFilter? supportFilter,
  }) async {
    return _deviceManager.getDevices(
      filter: DeviceDiscoveryFilter(
        deviceConnectionInterface: DeviceConnectionInterface.attached,
        supportFilter: supportFilter,
      ),
    );
  }

  Future<List<Device>> _getWirelessDevices({
    DeviceDiscoverySupportFilter? supportFilter,
  }) async {
    return _deviceManager.getDevices(
      filter: DeviceDiscoveryFilter(
        deviceConnectionInterface: DeviceConnectionInterface.wireless,
        supportFilter: supportFilter,
      ),
    );
  }

  Future<List<Device>> _getDeviceById({
    bool includeDevicesUnsupportedByProject = false,
  }) async {
    return _deviceManager.getDevices(
      filter: DeviceDiscoveryFilter(
        supportFilter: _deviceManager.deviceSupportFilter(
          includeDevicesUnsupportedByProject: includeDevicesUnsupportedByProject,
        ),
      ),
    );
  }

  DeviceDiscoverySupportFilter _defaultSupportFilter(
    bool includeDevicesUnsupportedByProject,
  ) {
    return _deviceManager.deviceSupportFilter(
      includeDevicesUnsupportedByProject: includeDevicesUnsupportedByProject,
    );
  }

  /// Find and return all target [Device]s based upon criteria entered by the
  /// user on the command line.
  ///
  /// When the user has specified `all` devices, return all devices meeting criteria.
  ///
  /// When the user has specified a device id/name, attempt to find an exact or
  /// partial match. If an exact match or a single partial match is found,
  /// return it immediately.
  ///
  /// When multiple devices are found and there is a terminal attached to
  /// stdin, allow the user to select which device to use. When a terminal
  /// with stdin is not available, print a list of available devices and
  /// return null.
  ///
  /// When no devices meet user specifications, print a list of unsupported
  /// devices and return null.
  Future<List<Device>?> findAllTargetDevices({
    Duration? deviceDiscoveryTimeout,
    bool includeDevicesUnsupportedByProject = false,
  }) async {
    if (!globals.doctor!.canLaunchAnything) {
      _logger.printError(userMessages.flutterNoDevelopmentDevice);
      return null;
    }

    if (deviceDiscoveryTimeout != null) {
      // Reset the cache with the specified timeout.
      await _deviceManager.refreshAllDevices(timeout: deviceDiscoveryTimeout);
    }

    if (_deviceManager.hasSpecifiedDeviceId) {
      // Must check for device match separately from `_getAttachedDevices` and
      // `_getWirelessDevices` because if an exact match is found in one
      // and a partial match is found in another, there is no way to distinguish
      // between them.
      final List<Device> devices = await _getDeviceById(
        includeDevicesUnsupportedByProject: includeDevicesUnsupportedByProject,
      );
      if (devices.length == 1) {
        return devices;
      }
    }

    final List<Device> attachedDevices = await _getAttachedDevices(
      supportFilter: _defaultSupportFilter(includeDevicesUnsupportedByProject),
    );
    final List<Device> wirelessDevices = await _getWirelessDevices(
      supportFilter: _defaultSupportFilter(includeDevicesUnsupportedByProject),
    );
    final List<Device> allDevices = attachedDevices + wirelessDevices;

    if (allDevices.isEmpty) {
      return _handleNoDevices();
    } else if (_deviceManager.hasSpecifiedAllDevices) {
      return allDevices;
    } else if (allDevices.length > 1) {
      return _handleMultipleDevices(attachedDevices, wirelessDevices);
    }
    return allDevices;
  }

  /// When no supported devices are found, display a message and list of
  /// unsupported devices found.
  Future<List<Device>?> _handleNoDevices() async {
    // Get connected devices from cache, including unsupported ones.
    final List<Device> unsupportedDevices = await _deviceManager.getAllDevices();

    if (_deviceManager.hasSpecifiedDeviceId) {
      _logger.printStatus(
        userMessages.flutterNoMatchingDevice(_deviceManager.specifiedDeviceId!),
      );
      if (unsupportedDevices.isNotEmpty) {
        _logger.printStatus('');
        _logger.printStatus('The following devices were found:');
        await Device.printDevices(unsupportedDevices, _logger);
      }
      return null;
    }

    _logger.printStatus(_deviceManager.hasSpecifiedAllDevices
        ? userMessages.flutterNoDevicesFound
        : userMessages.flutterNoSupportedDevices);
    await _printUnsupportedDevice(unsupportedDevices);
    return null;
  }

  /// Determine which device to use when multiple found.
  ///
  /// If user has not specified a device id/name, attempt to prioritize
  /// ephemeral devices. If a single ephemeral device is found, return it
  /// immediately.
  ///
  /// Otherwise, prompt the user to select a device if there is a terminal
  /// with stdin. If there is not a terminal, display the list of devices with
  /// instructions to use a device selection flag.
  Future<List<Device>?> _handleMultipleDevices(
    List<Device> attachedDevices,
    List<Device> wirelessDevices,
  ) async {
    final List<Device> allDevices = attachedDevices + wirelessDevices;

    final Device? ephemeralDevice = _deviceManager.getSingleEphemeralDevice(allDevices);
    if (ephemeralDevice != null) {
      return <Device>[ephemeralDevice];
    }

    if (globals.terminal.stdinHasTerminal) {
      return _selectFromMultipleDevices(attachedDevices, wirelessDevices);
    } else {
      return _printMultipleDevices(attachedDevices, wirelessDevices);
    }
  }

  /// Display a list of found devices. When the user has not specified the
  /// device id/name, display devices unsupported by the project as well and
  /// give instructions to use a device selection flag.
  Future<List<Device>?> _printMultipleDevices(
    List<Device> attachedDevices,
    List<Device> wirelessDevices,
  ) async {
    List<Device> supportedAttachedDevices = attachedDevices;
    List<Device> supportedWirelessDevices = wirelessDevices;
    if (_deviceManager.hasSpecifiedDeviceId) {
      final int allDeviceLength = supportedAttachedDevices.length + supportedWirelessDevices.length;
      _logger.printStatus(userMessages.flutterFoundSpecifiedDevices(
        allDeviceLength,
        _deviceManager.specifiedDeviceId!,
      ));
    } else {
      // Get connected devices from cache, including ones unsupported for the
      // project but still supported by Flutter.
      supportedAttachedDevices = await _getAttachedDevices(
        supportFilter: DeviceDiscoverySupportFilter.excludeDevicesUnsupportedByFlutter(),
      );
      supportedWirelessDevices = await _getWirelessDevices(
        supportFilter: DeviceDiscoverySupportFilter.excludeDevicesUnsupportedByFlutter(),
      );

      _logger.printStatus(userMessages.flutterSpecifyDeviceWithAllOption);
      _logger.printStatus('');
    }

    await Device.printDevices(supportedAttachedDevices, _logger);

    if (supportedWirelessDevices.isNotEmpty) {
      if (_deviceManager.hasSpecifiedDeviceId || supportedAttachedDevices.isNotEmpty) {
        _logger.printStatus('');
      }
      _logger.printStatus(_wirelesslyConnectedDevicesMessage);
      await Device.printDevices(supportedWirelessDevices, _logger);
    }

    return null;
  }

  /// Display a list of selectable devices, prompt the user to choose one, and
  /// wait for the user to select a valid option.
  Future<List<Device>?> _selectFromMultipleDevices(
    List<Device> attachedDevices,
    List<Device> wirelessDevices,
  ) async {
    final List<Device> allDevices = attachedDevices + wirelessDevices;

    if (_deviceManager.hasSpecifiedDeviceId) {
      _logger.printStatus(userMessages.flutterFoundSpecifiedDevices(
        allDevices.length,
        _deviceManager.specifiedDeviceId!,
      ));
    } else {
      _logger.printStatus(userMessages.flutterMultipleDevicesFound);
    }

    await Device.printDevices(attachedDevices, _logger);

    if (wirelessDevices.isNotEmpty) {
      _logger.printStatus('');
      _logger.printStatus(_wirelesslyConnectedDevicesMessage);
      await Device.printDevices(wirelessDevices, _logger);
      _logger.printStatus('');
    }

    final Device chosenDevice = await _chooseOneOfAvailableDevices(allDevices);

    // Update the [DeviceManager.specifiedDeviceId] so that the user will not be prompted again.
    _deviceManager.specifiedDeviceId = chosenDevice.id;

    return <Device>[chosenDevice];
  }

  Future<void> _printUnsupportedDevice(List<Device> unsupportedDevices) async {
    if (unsupportedDevices.isNotEmpty) {
      final StringBuffer result = StringBuffer();
      result.writeln();
      result.writeln(userMessages.flutterFoundButUnsupportedDevices);
      result.writeAll(
        (await Device.descriptions(unsupportedDevices))
            .map((String desc) => desc)
            .toList(),
        '\n',
      );
      result.writeln();
      result.writeln(userMessages.flutterMissPlatformProjects(
        Device.devicesPlatformTypes(unsupportedDevices),
      ));
      _logger.printStatus(result.toString(), newline: false);
    }
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
      _logger.printStatus(userMessages.flutterChooseDevice(count, device.name, device.id));
      count++;
    }
  }

  Future<String> _readUserInput(int deviceCount) async {
    globals.terminal.usesTerminalUi = true;
    final String result = await globals.terminal.promptForCharInput(
      <String>[ for (int i = 0; i < deviceCount; i++) '${i + 1}', 'q', 'Q'],
      displayAcceptedCharacters: false,
      logger: _logger,
      prompt: userMessages.flutterChooseOne,
    );
    return result;
  }
}
