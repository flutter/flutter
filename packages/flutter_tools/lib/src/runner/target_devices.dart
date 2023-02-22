import 'dart:async';

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/user_messages.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../project.dart';

class TargetDevices {
  /// This class handles functionality of finding and selecting target devices.
  ///
  /// Target devices are devices that are supported and selectable to run
  /// a flutter application on.
  factory TargetDevices({
    required Platform platform,
    required DeviceManager deviceManager,
    required Logger logger,
    DeviceConnectionInterface? deviceConnectionInterface,
  }) {
    if (platform.isMacOS) {
      return MacPlatformTargetDevices(
        deviceManager: deviceManager,
        logger: logger,
        deviceConnectionInterface: deviceConnectionInterface,
      );
    }
    return TargetDevices._default(
      deviceManager: deviceManager,
      logger: logger,
      deviceConnectionInterface: deviceConnectionInterface,
    );
  }

  TargetDevices._default({
    required DeviceManager deviceManager,
    required Logger logger,
    this.deviceConnectionInterface,
  })  : _deviceManager = deviceManager,
        _logger = logger;

  final DeviceManager _deviceManager;
  final Logger _logger;
  final DeviceConnectionInterface? deviceConnectionInterface;

  bool get _includeAttachedDevices =>
      deviceConnectionInterface == null ||
      deviceConnectionInterface == DeviceConnectionInterface.attached;
  bool get _includeWirelessDevices =>
      deviceConnectionInterface == null ||
      deviceConnectionInterface == DeviceConnectionInterface.wireless;

  Future<List<Device>> _getAttachedDevices({
    DeviceDiscoverySupportFilter? supportFilter,
  }) async {
    if (!_includeAttachedDevices) {
      return <Device>[];
    }
    return _deviceManager.getDevices(
      filter: DeviceDiscoveryFilter(
        deviceConnectionFilter: DeviceConnectionInterface.attached,
        supportFilter: supportFilter,
      ),
    );
  }

  void startPollingWirelessDevices({
    Duration? deviceDiscoveryTimeout,
  }) => VoidCallback;

  Future<List<Device>> _getWirelessDevices({
    DeviceDiscoverySupportFilter? supportFilter,
  }) async {
    if (!_includeWirelessDevices) {
      return <Device>[];
    }
    return _deviceManager.getDevices(
      filter: DeviceDiscoveryFilter(
        deviceConnectionFilter: DeviceConnectionInterface.wireless,
        supportFilter: supportFilter,
      ),
    );
  }

  Future<List<Device>> _getDeviceById({
    required FlutterProject? flutterProject,
    bool waitForDeviceToConnect = false,
  }) async {
    return _deviceManager.getDevices(
      filter: DeviceDiscoveryFilter(
        deviceConnectionFilter: deviceConnectionInterface,
        supportFilter: _defaultSupportFilter(flutterProject),
      ),
      waitForDeviceToConnect: waitForDeviceToConnect,
    );
  }

  DeviceDiscoverySupportFilter _defaultSupportFilter(
    FlutterProject? flutterProject,
  ) {
    // Device must be supported for the project, unless they have specified the device
    return DeviceDiscoverySupportFilter(
      flutterProject: flutterProject,
      mustBeSupportedByFlutter: true,
      mustBeSupportedForProject: !_deviceManager.hasSpecifiedDeviceId,
      mustBeSupportedForAll: _deviceManager.hasSpecifiedAllDevices,
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
  /// When no devices meet user specificiations, print a list of unsupported
  /// devices and return null.
  Future<List<Device>?> findAllTargetDevices({
    Duration? deviceDiscoveryTimeout,
    FlutterProject? flutterProject,
  }) async {
    if (!globals.doctor!.canLaunchAnything) {
      globals.printError(userMessages.flutterNoDevelopmentDevice);
      return null;
    }

    if (deviceDiscoveryTimeout != null) {
      // Reset the cache with the specified timeout.
      await _deviceManager.refreshAllDevices(timeout: deviceDiscoveryTimeout);
    }

    if (_deviceManager.hasSpecifiedDeviceId) {
      final List<Device> devices = await _getDeviceById(
        flutterProject: flutterProject,
      );
      if (devices.length == 1) {
        return devices;
      }
    }

    final List<Device> attachedDevices = await _getAttachedDevices(
      supportFilter: _defaultSupportFilter(flutterProject),
    );
    final List<Device> wirelessDevices = await _getWirelessDevices(
      supportFilter: _defaultSupportFilter(flutterProject),
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
    final List<Device> unsupportedDevices = await _deviceManager.getAllDevices(
      filter: DeviceDiscoveryFilter(
        deviceConnectionFilter: deviceConnectionInterface,
      ),
    );

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

  /// If user has not specificed a device id/name, attempt to prioritize
  /// ephemeral devices. If a single ephermal device is found, return it
  /// immediately.
  ///
  /// If only a single ephemeral device cannot be found or the user has
  /// specificied the device id/name, prompt the user to select a device if
  /// there is a terminal with stdin. If there is not a terminal, display the
  /// list of devices with instructions to use a device selection flag.
  Future<List<Device>?> _handleMultipleDevices(
    List<Device> attachedDevices,
    List<Device> wirelessDevices,
  ) async {
    final List<Device> allDevices = attachedDevices + wirelessDevices;
    if (!_deviceManager.hasSpecifiedDeviceId) {
      // If there are still multiple devices and the user did not specify to run
      // all or a specific device, then attempt to prioritize ephemeral devices.
      // For example, if the user only typed 'flutter run' and both an Android
      // device and desktop device are available, choose the Android device.

      // Note: ephemeral is nullable for device types where this is not well
      // defined.
      final List<Device> ephemeralDevices = allDevices
          .where((Device element) => element.ephemeral == true)
          .toList();
      if (ephemeralDevices.length == 1) {
        return ephemeralDevices;
      }
    }
    if (globals.terminal.stdinHasTerminal) {
      return _selectFromMultipleDevices(attachedDevices, wirelessDevices);
    } else {
      return _printMultipleDevices(attachedDevices, wirelessDevices);
    }
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
      _logger.printStatus(userMessages.flutterWirelesslyConnectedDevices);
      await Device.printDevices(wirelessDevices, _logger);
      _logger.printStatus('');
    }

    final Device chosenDevice = await _chooseOneOfAvailableDevices(allDevices);

    // Update the [DeviceManager.specifiedDeviceId] so that we will not be prompted again.
    _deviceManager.specifiedDeviceId = chosenDevice.id;

    return <Device>[chosenDevice];
  }

  /// Display a list of found devices. When the user has not specified the
  /// device id/name, display devices unsupported by the project too and give
  /// instructions to use a device selection flag.
  Future<List<Device>?> _printMultipleDevices(
    List<Device> attachedDevices,
    List<Device> wirelessDevices,
  ) async {
    if (_deviceManager.hasSpecifiedDeviceId) {
      final int allDeviceLength =
          attachedDevices.length + wirelessDevices.length;
      _logger.printStatus(userMessages.flutterFoundSpecifiedDevices(
        allDeviceLength,
        _deviceManager.specifiedDeviceId!,
      ));
    } else {
      // Get connected devices from cache, including ones unsupported for the
      // project but still supported by flutter.
      attachedDevices = await _getAttachedDevices(
        supportFilter: DeviceDiscoverySupportFilter(
          flutterProject: null,
          mustBeSupportedByFlutter: true,
        ),
      );
      wirelessDevices = await _getWirelessDevices(
        supportFilter: DeviceDiscoverySupportFilter(
          flutterProject: null,
          mustBeSupportedByFlutter: true,
        ),
      );

      _logger.printStatus(userMessages.flutterSpecifyDeviceWithAllOption);
      _logger.printStatus('');
    }

    await Device.printDevices(attachedDevices, _logger);

    if (wirelessDevices.isNotEmpty) {
      if (_deviceManager.hasSpecifiedDeviceId || attachedDevices.isNotEmpty) {
        _logger.printStatus('');
      }
      _logger.printStatus(userMessages.flutterWirelesslyConnectedDevices);
      await Device.printDevices(wirelessDevices, _logger);
    }

    return null;
  }

  // Display list of device options and wait for user to select one.
  Future<Device> _chooseOneOfAvailableDevices(List<Device> devices) async {
    _displayDeviceOptions(devices);

    final String userInput = await _readUserInput(deviceCount: devices.length);
    if (userInput.toLowerCase() == 'q') {
      throwToolExit('');
    }
    return devices[int.parse(userInput) - 1];
  }

  void _displayDeviceOptions(List<Device> devices) {
    int count = 1;
    for (final Device device in devices) {
      _logger.printStatus(userMessages.flutterChooseDevice(
        count,
        device.name,
        device.id,
      ));
      count++;
    }
  }

  Future<String> _readUserInput({int deviceCount = 0}) async {
    globals.terminal.usesTerminalUi = true;
    final String result = await globals.terminal.promptForCharInput(
      <String>[for (int i = 0; i < deviceCount; i++) '${i + 1}', 'q', 'Q'],
      displayAcceptedCharacters: false,
      logger: _logger,
      prompt: userMessages.flutterChooseOne,
    );
    return result;
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
}

@visibleForTesting
class MacPlatformTargetDevices extends TargetDevices {
  MacPlatformTargetDevices({
    required super.deviceManager,
    required super.logger,
    super.deviceConnectionInterface,
  })  : _deviceSelection = TargetDeviceSelection(logger),
        super._default();

  final TargetDeviceSelection _deviceSelection;

  @visibleForTesting
  bool waitForWirelessBeforeInput = false;

  @visibleForTesting
  TargetDeviceSelection get deviceSelection => _deviceSelection;

  Future<void>? _wirelessDevicesRefresh;

  @override
  void startPollingWirelessDevices({
    Duration? deviceDiscoveryTimeout,
  }) {
    if (_includeWirelessDevices) {
      _wirelessDevicesRefresh ??= _deviceManager.refreshWirelesslyConnectedDevices(
        timeout: DeviceManager.minimumWirelessTimeout,
      );
    }
    return;
  }

  Future<List<Device>> _getRefreshedWirelessDevices({
    required FlutterProject? flutterProject,
  }) async {
    if (!_includeWirelessDevices) {
      return <Device>[];
    }
    startPollingWirelessDevices();
    return () async {
      await _wirelessDevicesRefresh;
      return _deviceManager.getDevices(
        filter: DeviceDiscoveryFilter(
          deviceConnectionFilter: DeviceConnectionInterface.wireless,
          supportFilter: _defaultSupportFilter(flutterProject),
        ),
      );
    }();
  }

  /// Find and return all target [Device]s based upon criteria entered by the
  /// user on the command line.
  ///
  /// When the user has specified `all` devices, return all devices meeting criteria.
  ///
  /// When the user has specified a device id/name, attempt to find an exact or
  /// partial match. If an exact match or a single partial match is found and
  /// the device is connected, return it immediately. If an exact match is
  /// found but the device is not connected, wait for it to connect
  /// (iOS physical devices only).
  ///
  /// When multiple devices are found and there is a terminal attached to
  /// stdin, allow the user to select which device to use. When a terminal
  /// with stdin is not available, print a list of available devices and
  /// return null.
  ///
  /// When no devices meet user specificiations, print a list of unsupported
  /// devices and return null.
  @override
  Future<List<Device>?> findAllTargetDevices({
    Duration? deviceDiscoveryTimeout,
    FlutterProject? flutterProject,
  }) async {
    if (!globals.doctor!.canLaunchAnything) {
      globals.printError(userMessages.flutterNoDevelopmentDevice);
      return null;
    }

    // When a user defines the timeout or filters to only attached devices,
    // use the super function that does not do longer wireless device
    // discovery and does not wait for devices to connect.
    if (deviceDiscoveryTimeout != null ||
        deviceConnectionInterface == DeviceConnectionInterface.attached) {
      return super.findAllTargetDevices(
        deviceDiscoveryTimeout: deviceDiscoveryTimeout,
        flutterProject: flutterProject,
      );
    }

    final Future<List<Device>> futureWirelessDevices = _getRefreshedWirelessDevices(
      flutterProject: flutterProject,
    );

    if (_deviceManager.hasSpecifiedDeviceId) {
      final List<Device> devices = await _getDeviceById(
        flutterProject: flutterProject,
        waitForDeviceToConnect: true,
      );
      if (devices.length == 1 && devices.first.isConnected == true) {
        return devices;
      }
    }

    final List<Device> attachedDevices = await _getAttachedDevices(
      supportFilter: _defaultSupportFilter(flutterProject),
    );

    if (attachedDevices.isEmpty) {
      return _handleNoAttachedDevices(attachedDevices, futureWirelessDevices);
    } else if (_deviceManager.hasSpecifiedAllDevices) {
      return _handleAllDevices(attachedDevices, futureWirelessDevices);
    }
    // Even if there's only a single attached device, continue to
    // _handleRemainingDevices since there might be wireless devices
    // that are not loaded yet.
    return _handleRemainingDevices(attachedDevices, futureWirelessDevices);
  }

  /// When no supported attached devices are found, wait for wireless devices
  /// to load. If no wireless devices are found, continue to no device handling.
  /// If wireless devices are found, continue to multiple device handling.
  Future<List<Device>?> _handleNoAttachedDevices(
    List<Device> attachedDevices,
    Future<List<Device>> futureWirelessDevices,
  ) async {
    if (_includeAttachedDevices) {
      _logger.printStatus(userMessages.flutterNoAttachedCheckForWireless);
    } else {
      _logger.printStatus(userMessages.flutterCheckingForWirelessDevices);
    }

    final List<Device> wirelessDevices = await futureWirelessDevices;
    final List<Device> allDevices = attachedDevices + wirelessDevices;

    if (allDevices.isEmpty) {
      _logger.printStatus('');
      return _handleNoDevices();
    } else if (allDevices.length > 1 &&
        !_deviceManager.hasSpecifiedAllDevices) {
      _logger.printStatus('');
      return _handleMultipleDevices(attachedDevices, wirelessDevices);
    }
    return allDevices;
  }

  /// Wait for wireless devices to load and then return all attached and
  /// wireless devices.
  Future<List<Device>?> _handleAllDevices(
    List<Device> devices,
    Future<List<Device>> futureWirelessDevices,
  ) async {
    _logger.printStatus(userMessages.flutterCheckingForWirelessDevices);
    final List<Device> wirelessDevices = await futureWirelessDevices;
    return devices + wirelessDevices;
  }

  /// If user has not specificed a device id/name, attempt to prioritize
  /// ephemeral devices. If a single ephermal device is found, return it
  /// immediately.
  ///
  /// If only a single ephemeral device cannot be found or the user has
  /// specificied the device id/name, prompt the user to select a device if
  /// there is a terminal with stdin. If there is not a terminal, display the
  /// list of devices with instructions to use a device selection flag.
  Future<List<Device>?> _handleRemainingDevices(
    List<Device> attachedDevices,
    Future<List<Device>> futureWirelessDevices,
  ) async {
    if (!_deviceManager.hasSpecifiedDeviceId) {
      // If there are still multiple devices and the user did not specify to run
      // all or a specific device, then attempt to prioritize ephemeral devices.
      // For example, if the user only typed 'flutter run' and both an Android
      // device and desktop device are available, choose the Android device.

      // Note: ephemeral is nullable for device types where this is not well
      // defined.
      final List<Device> ephemeralDevices = attachedDevices
          .where((Device element) => element.ephemeral == true)
          .toList();
      if (ephemeralDevices.length == 1) {
        return ephemeralDevices;
      }
    }

    if (!globals.terminal.stdinHasTerminal || !_logger.supportsColor) {
      _logger.printStatus(userMessages.flutterCheckingForWirelessDevices);
      final List<Device> wirelessDevices = await futureWirelessDevices;
      if (attachedDevices.length + wirelessDevices.length == 1) {
        return attachedDevices + wirelessDevices;
      }
      _logger.printStatus('');
      // If the terminal has stdin but does not support color/ANSI (which is
      // needed to clear lines), fallback to standard selection of device.
      if (globals.terminal.stdinHasTerminal && !_logger.supportsColor) {
        return _handleMultipleDevices(attachedDevices, wirelessDevices);
      }
      // If terminal does not have stdin, print out device list.
      return _printMultipleDevices(attachedDevices, wirelessDevices);
    }

    return _selectFromDevicesAndCheckForWireless(
      attachedDevices,
      futureWirelessDevices,
    );
  }

  /// Display a list of selectable attached devices and prompt the user to
  /// choose one.
  ///
  /// Also display message about waiting for wireless devices to load. Once
  /// wireless devices have loaded, update waiting message, device list, and
  /// selection options.
  ///
  /// Wait for user to select a device.
  Future<List<Device>?> _selectFromDevicesAndCheckForWireless(
    List<Device> attachedDevices,
    Future<List<Device>> futureWirelessDevices,
  ) async {
    if (_deviceManager.hasSpecifiedDeviceId) {
      // Multiple devices were found with part of the name/id provided.
      _logger.printStatus(userMessages.flutterFoundMultipleSpecifiedDevices(
        _deviceManager.specifiedDeviceId!,
      ));
    } else {
      _logger.printStatus(userMessages.flutterMultipleDevicesFound);
    }

    // Display list of attached devices.
    await Device.printDevices(attachedDevices, _logger);

    // Display waiting message.
    _logger.printStatus('');
    _logger.printStatus(userMessages.flutterCheckingForWirelessDevices);
    _logger.printStatus('');

    // Start user device selection so user can select device while waiting
    // for wireless devices to load if they want.
    _displayDeviceOptions(attachedDevices);
    deviceSelection.devices = attachedDevices;
    final Future<Device> futureChosenDevice = deviceSelection.userSelectDevice();
    Device? chosenDevice;

    // Once wireless devices are found, we clear out the waiting message (3),
    // device option list (attachedDevices.length), and device option prompt (1).
    int numLinesToClear = attachedDevices.length + 4;

    futureWirelessDevices = futureWirelessDevices.then((List<Device> wirelessDevices) async {
      // If device is already chosen, don't update terminal with
      // wireless device list.
      if (chosenDevice != null) {
        return wirelessDevices;
      }

      final List<Device> allDevices = attachedDevices + wirelessDevices;

      if (_logger.isVerbose) {
        await _verbosePrintWirelessDevices(attachedDevices, wirelessDevices);
      } else {
        // Also clear any invalid device selections.
        numLinesToClear += deviceSelection.invalidAttempts;
        await _printWirelessDevices(wirelessDevices, numLinesToClear);
      }
      _logger.printStatus('');

      // Reprint device option list.
      _displayDeviceOptions(allDevices);
      deviceSelection.devices = allDevices;
      // Reprint device option prompt.
      _logger.printStatus(
        '${userMessages.flutterChooseOne}: ',
        emphasis: true,
        newline: false,
      );
      return wirelessDevices;
    });

    // Used for testing.
    if (waitForWirelessBeforeInput) {
      await futureWirelessDevices;
    }

    // Wait for user to select a device.
    chosenDevice = await futureChosenDevice;

    // Update the [DeviceManager.specifiedDeviceId] so that we will not be
    // prompted again.
    _deviceManager.specifiedDeviceId = chosenDevice.id;

    return <Device>[chosenDevice];
  }

  /// Reprint attached devices before printing list of wireless devices.
  Future<void> _verbosePrintWirelessDevices(
    List<Device> attachedDevices,
    List<Device> wirelessDevices,
  ) async {
    if (wirelessDevices.isEmpty) {
      _logger.printStatus(userMessages.flutterNoWirelessDevicesFound);
    }
    // The iOS xcdevice outputs once wireless devices are done loading, so
    // reprint attached devices so they're grouped with the wireless ones.
    _logger.printStatus(userMessages.flutterMultipleDevicesFound);
    await Device.printDevices(attachedDevices, _logger);

    if (wirelessDevices.isNotEmpty) {
      _logger.printStatus('');
      _logger.printStatus(userMessages.flutterWirelesslyConnectedDevices);
      await Device.printDevices(wirelessDevices, _logger);
    }
  }

  /// Clear [numLinesToClear] lines from terminal. Print message and list of
  /// wireless devices.
  Future<void> _printWirelessDevices(
    List<Device> wirelessDevices,
    int numLinesToClear,
  ) async {
    _logger.printStatus(
      globals.terminal.clearLines(numLinesToClear),
      newline: false,
    );
    _logger.printStatus('');
    if (wirelessDevices.isEmpty) {
      _logger.printStatus(userMessages.flutterNoWirelessDevicesFound);
    } else {
      _logger.printStatus(userMessages.flutterWirelesslyConnectedDevices);
      await Device.printDevices(wirelessDevices, _logger);
    }
  }
}

@visibleForTesting
class TargetDeviceSelection {
  TargetDeviceSelection(this._logger);

  List<Device> devices = <Device>[];
  final Logger _logger;
  int invalidAttempts = 0;

  Future<Device> userSelectDevice() async {
    Device? chosenDevice;
    while (chosenDevice == null) {
      final String userInputString = await readUserInput();
      if (userInputString.toLowerCase() == 'q') {
        throwToolExit('');
      }
      final int deviceIndex = int.parse(userInputString) - 1;
      if (deviceIndex < devices.length) {
        chosenDevice = devices[deviceIndex];
      }
    }

    return chosenDevice;
  }

  @visibleForTesting
  Future<String> readUserInput() async {
    final RegExp pattern = RegExp(r'\d+$|q', caseSensitive: false);
    final String prompt = userMessages.flutterChooseOne;
    String? choice;
    globals.terminal.singleCharMode = true;
    while (choice == null || choice.length > 1 || !pattern.hasMatch(choice)) {
      _logger.printStatus(prompt, emphasis: true, newline: false);
      // prompt ends with ': '
      _logger.printStatus(': ', emphasis: true, newline: false);
      choice = (await globals.terminal.keystrokes.first).trim();
      _logger.printStatus(choice);
      invalidAttempts++;
    }
    globals.terminal.singleCharMode = false;
    return choice;
  }
}
