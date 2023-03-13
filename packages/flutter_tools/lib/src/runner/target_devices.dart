// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/logger.dart';
import '../base/user_messages.dart';
import '../device.dart';
import '../globals.dart' as globals;

class TargetDevices {
  TargetDevices({
    required DeviceManager deviceManager,
    required Logger logger,
  })  : _deviceManager = deviceManager,
        _logger = logger;

  final DeviceManager _deviceManager;
  final Logger _logger;

  /// Find and return all target [Device]s based upon currently connected
  /// devices and criteria entered by the user on the command line.
  /// If no device can be found that meets specified criteria,
  /// then print an error message and return null.
  Future<List<Device>?> findAllTargetDevices({
    Duration? deviceDiscoveryTimeout,
    bool includeDevicesUnsupportedByProject = false,
  }) async {
    if (!globals.doctor!.canLaunchAnything) {
      _logger.printError(userMessages.flutterNoDevelopmentDevice);
      return null;
    }
    List<Device> devices = await getDevices(
      includeDevicesUnsupportedByProject: includeDevicesUnsupportedByProject,
      timeout: deviceDiscoveryTimeout,
    );

    if (devices.isEmpty) {
      if (_deviceManager.hasSpecifiedDeviceId) {
        _logger.printStatus(userMessages.flutterNoMatchingDevice(_deviceManager.specifiedDeviceId!));
        final List<Device> allDevices = await _deviceManager.getAllDevices();
        if (allDevices.isNotEmpty) {
          _logger.printStatus('');
          _logger.printStatus('The following devices were found:');
          await Device.printDevices(allDevices, _logger);
        }
        return null;
      } else if (_deviceManager.hasSpecifiedAllDevices) {
        _logger.printStatus(userMessages.flutterNoDevicesFound);
        await _printUnsupportedDevice(_deviceManager);
        return null;
      } else {
        _logger.printStatus(userMessages.flutterNoSupportedDevices);
        await _printUnsupportedDevice(_deviceManager);
        return null;
      }
    } else if (devices.length > 1) {
      if (_deviceManager.hasSpecifiedDeviceId) {
        _logger.printStatus(userMessages.flutterFoundSpecifiedDevices(devices.length, _deviceManager.specifiedDeviceId!));
        return null;
      } else if (!_deviceManager.hasSpecifiedAllDevices) {
        if (globals.terminal.stdinHasTerminal) {
          // If DeviceManager was not able to prioritize a device. For example, if the user
          // has two active Android devices running, then we request the user to
          // choose one. If the user has two nonEphemeral devices running, we also
          // request input to choose one.
          _logger.printStatus(userMessages.flutterMultipleDevicesFound);
          await Device.printDevices(devices, _logger);
          final Device chosenDevice = await _chooseOneOfAvailableDevices(devices);

          // Update the [DeviceManager.specifiedDeviceId] so that we will not be prompted again.
          _deviceManager.specifiedDeviceId = chosenDevice.id;

          devices = <Device>[chosenDevice];
        } else {
          // Show an error message asking the user to specify `-d all` if they
          // want to run on multiple devices.
          final List<Device> allDevices = await _deviceManager.getAllDevices();
          _logger.printStatus(userMessages.flutterSpecifyDeviceWithAllOption);
          _logger.printStatus('');
          await Device.printDevices(allDevices, _logger);
          return null;
        }
      }
    }

    return devices;
  }

  Future<void> _printUnsupportedDevice(DeviceManager deviceManager) async {
    final List<Device> unsupportedDevices = await deviceManager.getDevices();
    if (unsupportedDevices.isNotEmpty) {
      final StringBuffer result = StringBuffer();
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
      _logger.printStatus(result.toString());
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

  /// Find and return all target [Device]s based upon currently connected
  /// devices, the current project, and criteria entered by the user on
  /// the command line.
  ///
  /// Returns a list of devices specified by the user.
  ///
  /// * If the user specified '-d all', then return all connected devices which
  /// support the current project, except for fuchsia and web.
  ///
  /// * If the user specified a device id, then do nothing as the list is already
  /// filtered by [_deviceManager.getDevices].
  ///
  /// * If the user did not specify a device id and there is more than one
  /// device connected, then filter out unsupported devices and prioritize
  /// ephemeral devices.
  @visibleForTesting
  Future<List<Device>> getDevices({
    bool includeDevicesUnsupportedByProject = false,
    Duration? timeout,
  }) async {
    if (timeout != null) {
      // Reset the cache with the specified timeout.
      await _deviceManager.refreshAllDevices(timeout: timeout);
    }

    final List<Device> devices = await _deviceManager.getDevices(
      filter: DeviceDiscoveryFilter(
        supportFilter: _deviceManager.deviceSupportFilter(
          includeDevicesUnsupportedByProject: includeDevicesUnsupportedByProject,
        ),
      ),
    );

    // If there is more than one device, attempt to prioritize ephemeral devices.
    if (devices.length > 1) {
      final Device? ephemeralDevice = _deviceManager.getSingleEphemeralDevice(devices);
      if (ephemeralDevice != null) {
        return <Device>[ephemeralDevice];
      }
    }

    return devices;
  }
}
