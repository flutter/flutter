// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../convert.dart';
import '../device.dart';
import '../doctor.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

/// The `flutter devices` command, which lists all connected devices.
class DevicesCommand extends FlutterCommand {
  DevicesCommand({
    DeviceManager? deviceManager,
    Doctor? doctor,
    super.toolContext,
    super.verboseHelp,
  }) : _deviceManager = deviceManager ?? globals.deviceManager!,
       _doctor = doctor ?? globals.doctor! {
    addMachineOutputFlag(verboseHelp: verboseHelp);
    argParser.addOption(
      'timeout',
      abbr: 't',
      help: '(deprecated) This option has been replaced by "--${FlutterOptions.kDeviceTimeout}".',
      hide: !verboseHelp,
    );
    usesDeviceTimeoutOption();
    usesDeviceConnectionOption();
  }

  final DeviceManager _deviceManager;
  final Doctor _doctor;

  @override
  final name = 'devices';

  @override
  final description = 'List all connected devices.';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  Duration? get deviceDiscoveryTimeout {
    if (argResults?['timeout'] != null) {
      final int? timeoutSeconds = int.tryParse(stringArg('timeout')!);
      if (timeoutSeconds == null) {
        throwToolExit('Could not parse -t/--timeout argument. It must be an integer.');
      }
      return Duration(seconds: timeoutSeconds);
    }
    return super.deviceDiscoveryTimeout;
  }

  @override
  Future<void> validateCommand() {
    if (argResults?['timeout'] != null) {
      final Logger logger = super.toolContext?.logger ?? globals.logger;
      final Terminal terminal = super.toolContext?.terminal ?? globals.logger.terminal;
      logger.printWarning(
        '${terminal.warningMark} The "--timeout" argument is deprecated; use "--${FlutterOptions.kDeviceTimeout}" instead.',
      );
    }
    return super.validateCommand();
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (!_doctor.canListAnything) {
      throwToolExit(
        "Unable to locate a development device; please run 'flutter doctor' for "
        'information about installing additional components.',
        exitCode: 1,
      );
    }

    final output = DevicesCommandOutput(
      platform: super.toolContext?.platform ?? globals.platform,
      logger: super.toolContext?.logger ?? globals.logger,
      deviceManager: _deviceManager,
      deviceDiscoveryTimeout: deviceDiscoveryTimeout,
      deviceConnectionInterface: deviceConnectionInterface,
    );

    await output.findAndOutputAllTargetDevices(machine: outputMachineFormat);

    return FlutterCommandResult.success();
  }
}

class DevicesCommandOutput {
  factory DevicesCommandOutput({
    required Logger logger,
    required Platform platform,
    DeviceConnectionInterface? deviceConnectionInterface,
    Duration? deviceDiscoveryTimeout,
    DeviceManager? deviceManager,
  }) {
    final DeviceManager effectiveDeviceManager = deviceManager ?? globals.deviceManager!;
    if (platform.isMacOS) {
      return DevicesCommandOutputWithExtendedWirelessDeviceDiscovery(
        deviceConnectionInterface: deviceConnectionInterface,
        deviceDiscoveryTimeout: deviceDiscoveryTimeout,
        deviceManager: effectiveDeviceManager,
        logger: logger,
      );
    }
    return DevicesCommandOutput._private(
      deviceConnectionInterface: deviceConnectionInterface,
      deviceDiscoveryTimeout: deviceDiscoveryTimeout,
      deviceManager: effectiveDeviceManager,
      logger: logger,
    );
  }

  DevicesCommandOutput._private({
    this.deviceConnectionInterface,
    this.deviceDiscoveryTimeout,
    required DeviceManager deviceManager,
    required Logger logger,
  }) : _deviceManager = deviceManager,
       _logger = logger;

  final DeviceManager _deviceManager;
  final Logger _logger;
  final Duration? deviceDiscoveryTimeout;
  final DeviceConnectionInterface? deviceConnectionInterface;

  bool get _includeAttachedDevices =>
      deviceConnectionInterface == null ||
      deviceConnectionInterface == DeviceConnectionInterface.attached;

  bool get _includeWirelessDevices =>
      deviceConnectionInterface == null ||
      deviceConnectionInterface == DeviceConnectionInterface.wireless;

  Future<List<Device>> _getAttachedDevices(DeviceManager deviceManager) async {
    if (!_includeAttachedDevices) {
      return <Device>[];
    }
    return deviceManager.getAllDevices(
      filter: DeviceDiscoveryFilter(deviceConnectionInterface: DeviceConnectionInterface.attached),
    );
  }

  Future<List<Device>> _getWirelessDevices(DeviceManager deviceManager) async {
    if (!_includeWirelessDevices) {
      return <Device>[];
    }
    return deviceManager.getAllDevices(
      filter: DeviceDiscoveryFilter(deviceConnectionInterface: DeviceConnectionInterface.wireless),
    );
  }

  Future<void> findAndOutputAllTargetDevices({required bool machine}) async {
    // Refresh the cache and then get the attached and wireless devices from
    // the cache.
    await _deviceManager.refreshAllDevices(timeout: deviceDiscoveryTimeout);
    final List<Device> attachedDevices = await _getAttachedDevices(_deviceManager);
    final List<Device> wirelessDevices = await _getWirelessDevices(_deviceManager);
    final List<Device> allDevices = attachedDevices + wirelessDevices;

    if (machine) {
      await printDevicesAsJson(allDevices);
      return;
    }

    if (allDevices.isEmpty) {
      _logger.printStatus('No authorized devices detected.');
    } else {
      if (attachedDevices.isNotEmpty) {
        _logger.printStatus(
          'Found ${attachedDevices.length} connected ${pluralize('device', attachedDevices.length)}:',
        );
        await Device.printDevices(attachedDevices, _logger, prefix: '  ');
      }
      if (wirelessDevices.isNotEmpty) {
        if (attachedDevices.isNotEmpty) {
          _logger.printStatus('');
        }
        _logger.printStatus(
          'Found ${wirelessDevices.length} wirelessly connected ${pluralize('device', wirelessDevices.length)}:',
        );
        await Device.printDevices(wirelessDevices, _logger, prefix: '  ');
      }
    }
    await _printDiagnostics(foundAny: allDevices.isNotEmpty);
  }

  Future<void> _printDiagnostics({required bool foundAny}) async {
    final status = StringBuffer();
    status.writeln();
    final List<String> diagnostics = await _deviceManager.getDeviceDiagnostics();
    if (diagnostics.isNotEmpty) {
      for (final diagnostic in diagnostics) {
        status.writeln(diagnostic);
        status.writeln();
      }
    }
    status.writeln('Run "flutter emulators" to list and start any available device emulators.');
    status.writeln();
    status.write(
      'If you expected ${foundAny ? 'another' : 'a'} device to be detected, please run "flutter doctor" to diagnose potential issues. ',
    );
    if (deviceDiscoveryTimeout == null) {
      status.write(
        'You may also try increasing the time to wait for connected devices with the "--${FlutterOptions.kDeviceTimeout}" flag. ',
      );
    }
    status.write('Visit https://flutter.dev/setup/ for troubleshooting tips.');
    _logger.printStatus(status.toString());
  }

  Future<void> printDevicesAsJson(List<Device> devices) async {
    _logger.printStatus(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(await Future.wait(devices.map((Device d) => d.toJson()))),
    );
  }
}

const _checkingForWirelessDevicesMessage = 'Checking for wireless devices...';
const _noAttachedCheckForWireless = 'No devices found yet. Checking for wireless devices...';
const _noWirelessDevicesFoundMessage = 'No wireless devices were found.';

class DevicesCommandOutputWithExtendedWirelessDeviceDiscovery extends DevicesCommandOutput {
  DevicesCommandOutputWithExtendedWirelessDeviceDiscovery({
    required super.deviceManager,
    required super.logger,
    super.deviceConnectionInterface,
    super.deviceDiscoveryTimeout,
  }) : super._private();

  @override
  Future<void> findAndOutputAllTargetDevices({required bool machine}) async {
    // When a user defines the timeout or filters to only attached devices,
    // use the super function that does not do longer wireless device discovery.
    if (deviceDiscoveryTimeout != null ||
        deviceConnectionInterface == DeviceConnectionInterface.attached) {
      return super.findAndOutputAllTargetDevices(machine: machine);
    }

    if (machine) {
      final List<Device> devices = await _deviceManager.refreshAllDevices(
        filter: DeviceDiscoveryFilter(deviceConnectionInterface: deviceConnectionInterface),
        timeout: DeviceManager.minimumWirelessDeviceDiscoveryTimeout,
      );
      await printDevicesAsJson(devices);
      return;
    }

    final Future<void> extendedWirelessDiscovery = _deviceManager
        .refreshExtendedWirelessDeviceDiscoverers(
          timeout: DeviceManager.minimumWirelessDeviceDiscoveryTimeout,
        );

    final List<Device> attachedDevices = await _getAttachedDevices(_deviceManager);

    // Number of lines to clear starts at 1 because it's inclusive of the line
    // the cursor is on, which will be blank for this use case.
    var numLinesToClear = 1;

    // Display list of attached devices.
    if (attachedDevices.isNotEmpty) {
      _logger.printStatus(
        'Found ${attachedDevices.length} connected ${pluralize('device', attachedDevices.length)}:',
      );
      await Device.printDevices(attachedDevices, _logger, prefix: '  ');
      _logger.printStatus('');
      numLinesToClear += 1;
    }

    // Display waiting message.
    if (attachedDevices.isEmpty && _includeAttachedDevices) {
      _logger.printStatus(_noAttachedCheckForWireless);
    } else {
      _logger.printStatus(_checkingForWirelessDevicesMessage);
    }
    numLinesToClear += 1;

    final Status waitingStatus = _logger.startSpinner();
    await extendedWirelessDiscovery;
    final List<Device> wirelessDevices = await _getWirelessDevices(_deviceManager);
    waitingStatus.stop();

    final Terminal terminal = _logger.terminal;
    if (_logger.isVerbose && _includeAttachedDevices) {
      // Reprint the attach devices.
      if (attachedDevices.isNotEmpty) {
        _logger.printStatus(
          '\nFound ${attachedDevices.length} connected ${pluralize('device', attachedDevices.length)}:',
        );
        await Device.printDevices(attachedDevices, _logger, prefix: '  ');
      }
    } else if (terminal.supportsColor && terminal is AnsiTerminal) {
      _logger.printStatus(terminal.clearLines(numLinesToClear), newline: false);
    }

    if (attachedDevices.isNotEmpty || !terminal.supportsColor) {
      _logger.printStatus('');
    }

    if (wirelessDevices.isEmpty) {
      if (attachedDevices.isEmpty) {
        // No wireless or attached devices were found.
        _logger.printStatus('No authorized devices detected.');
      } else {
        // Attached devices found, wireless devices not found.
        _logger.printStatus(_noWirelessDevicesFoundMessage);
      }
    } else {
      // Display list of wireless devices.
      _logger.printStatus(
        'Found ${wirelessDevices.length} wirelessly connected ${pluralize('device', wirelessDevices.length)}:',
      );
      await Device.printDevices(wirelessDevices, _logger, prefix: '  ');
    }
    await _printDiagnostics(foundAny: wirelessDevices.isNotEmpty || attachedDevices.isNotEmpty);
  }
}
