// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/user_messages.dart';
import '../base/utils.dart';
import '../convert.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

class DevicesCommand extends FlutterCommand {
  DevicesCommand({ bool verboseHelp = false }) {
    argParser.addFlag('machine',
      negatable: false,
      help: 'Output device information in machine readable structured JSON format.',
    );
    argParser.addOption(
      'timeout',
      abbr: 't',
      help: '(deprecated) This option has been replaced by "--${FlutterOptions.kDeviceTimeout}".',
      hide: !verboseHelp,
    );
    usesDeviceTimeoutOption();
    usesDeviceConnectionOption();
  }

  @override
  final String name = 'devices';

  @override
  final String description = 'List all connected devices.';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  Duration? get deviceDiscoveryTimeout {
    if (argResults?['timeout'] != null) {
      final int? timeoutSeconds = int.tryParse(stringArgDeprecated('timeout')!);
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
      globals.printWarning('${globals.logger.terminal.warningMark} The "--timeout" argument is deprecated; use "--${FlutterOptions.kDeviceTimeout}" instead.');
    }
    return super.validateCommand();
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (globals.doctor?.canListAnything != true) {
      throwToolExit(
        "Unable to locate a development device; please run 'flutter doctor' for "
        'information about installing additional components.',
        exitCode: 1);
    }

    final DevicesOutput output = DevicesOutput(
      platform: globals.platform,
      deviceDiscoveryTimeout: deviceDiscoveryTimeout,
      deviceConnectionInterface: deviceConnectionInterface,
    );

    await output.findAndOutputAllTargetDevices(
      machine: boolArgDeprecated('machine'),
    );

    return FlutterCommandResult.success();
  }
}

class DevicesOutput {
  factory DevicesOutput({
    required Platform platform,
    required Duration? deviceDiscoveryTimeout,
    required DeviceConnectionInterface? deviceConnectionInterface,
  }) {
    if (platform.isMacOS) {
      return MacDevicesOutput(
        deviceDiscoveryTimeout: deviceDiscoveryTimeout,
        deviceConnectionInterface: deviceConnectionInterface,
      );
    }
    return DevicesOutput._default(
      deviceDiscoveryTimeout: deviceDiscoveryTimeout,
      deviceConnectionInterface: deviceConnectionInterface,
    );
  }
  DevicesOutput._default({
    required this.deviceDiscoveryTimeout,
    required this.deviceConnectionInterface,
  });

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
      filter: DeviceDiscoveryFilter(
        deviceConnectionFilter: DeviceConnectionInterface.attached,
      ),
    );
  }

  Future<List<Device>> _getWirelessDevices(DeviceManager deviceManager) async {
    if (!_includeWirelessDevices) {
      return <Device>[];
    }
    return deviceManager.getAllDevices(
      filter: DeviceDiscoveryFilter(
        deviceConnectionFilter: DeviceConnectionInterface.wireless,
      ),
    );
  }

  Future<void> findAndOutputAllTargetDevices({required bool machine}) async {
    List<Device> attachedDevices = <Device>[];
    List<Device> wirelessDevices = <Device>[];
    final DeviceManager? deviceManager = globals.deviceManager;
    if (deviceManager != null) {
      await deviceManager.refreshAllDevices();
      attachedDevices = await _getAttachedDevices(deviceManager);
      wirelessDevices = await _getWirelessDevices(deviceManager);
    }
    final List<Device> allDevices = attachedDevices + wirelessDevices;

    if (machine) {
      await printDevicesAsJson(allDevices);
      return;
    }

    if (allDevices.isEmpty) {
      globals.printStatus('No devices detected.');
      _printNoDevicesDetected();
    } else {
      if (attachedDevices.isNotEmpty) {
        globals.printStatus('${attachedDevices.length} connected ${pluralize('device', attachedDevices.length)}:\n');
        await Device.printDevices(attachedDevices, globals.logger);
      }
      if (wirelessDevices.isNotEmpty) {
        if (attachedDevices.isNotEmpty) {
          globals.printStatus('');
        }
        globals.printStatus('${wirelessDevices.length} wirelessly connected ${pluralize('device', wirelessDevices.length)}:\n');
        await Device.printDevices(wirelessDevices, globals.logger);
      }
    }
    await _printDiagnostics();
  }

  void _printNoDevicesDetected() {
    final StringBuffer status = StringBuffer();
    status.writeln();
    status.writeln('Run "flutter emulators" to list and start any available device emulators.');
    status.writeln();
    status.write('If you expected your device to be detected, please run "flutter doctor" to diagnose potential issues. ');
    if (deviceDiscoveryTimeout == null) {
      status.write('You may also try increasing the time to wait for connected devices with the --${FlutterOptions.kDeviceTimeout} flag. ');
    }
    status.write('Visit https://flutter.dev/setup/ for troubleshooting tips.');

    globals.printStatus(status.toString());
  }

  Future<void> _printDiagnostics() async {
    final List<String> diagnostics = await globals.deviceManager?.getDeviceDiagnostics() ?? <String>[];
    if (diagnostics.isNotEmpty) {
      globals.printStatus('');
      for (final String diagnostic in diagnostics) {
        globals.printStatus('• $diagnostic', hangingIndent: 2);
      }
    }
  }

  Future<void> printDevicesAsJson(List<Device> devices) async {
    globals.printStatus(
      const JsonEncoder.withIndent('  ').convert(
        await Future.wait(devices.map((Device d) => d.toJson()))
      )
    );
  }
}

class MacDevicesOutput extends DevicesOutput {
  MacDevicesOutput({
    required super.deviceDiscoveryTimeout,
    required super.deviceConnectionInterface,
  }) : super._default();

  @override
  Future<void> findAndOutputAllTargetDevices({required bool machine}) async {
    // When a user defines the timeout or has specified the device id, use the super function
    // that only does one device discovery refresh
    if (deviceDiscoveryTimeout != null ||
        deviceConnectionInterface == DeviceConnectionInterface.attached) {
      return super.findAndOutputAllTargetDevices(machine: machine);
    }

    if (machine) {
      final List<Device> devices = await globals.deviceManager?.refreshAllDevices(
        filter: DeviceDiscoveryFilter(
          deviceConnectionFilter: deviceConnectionInterface,
        ),
        timeout: DeviceManager.minimumWirelessTimeout,
      ) ?? <Device>[];
      await printDevicesAsJson(devices);
      return;
    }

    final Future<List<Device>>? futureWirelessDevices = globals.deviceManager?.refreshWirelesslyConnectedDevices(
      filter: DeviceDiscoveryFilter(
        deviceConnectionFilter: DeviceConnectionInterface.wireless,
      ),
      timeout: DeviceManager.minimumWirelessTimeout,
    );

    List<Device> attachedDevices = <Device>[];
    final DeviceManager? deviceManager = globals.deviceManager;
    if (deviceManager != null) {
      attachedDevices = await _getAttachedDevices(deviceManager);
    }

    // Number of lines to clear starts at 1 because it's inclusive of the line
    // the cursor is on, which will be blank for this use case.
    int numLinesToClear = 1;

    // Display list of attached devices.
    if (attachedDevices.isNotEmpty) {
      globals.printStatus('${attachedDevices.length} connected ${pluralize('device', attachedDevices.length)}:\n');
      await Device.printDevices(attachedDevices, globals.logger);
      globals.printStatus('');
      numLinesToClear += 1;
    }

    // Display waiting message.
    if (attachedDevices.isEmpty && _includeAttachedDevices) {
      globals.logger.printStatus(userMessages.flutterNoAttachedCheckForWireless);
    } else {
      globals.logger.printStatus(userMessages.flutterCheckingForWirelessDevices);
    }
    numLinesToClear += 1;

    final Status waitingStatus = globals.logger.startSpinner();
    final List<Device> wirelessDevices = await futureWirelessDevices ?? <Device>[];
    waitingStatus.stop();

    if (globals.logger.isVerbose && _includeAttachedDevices) {
      // Reprint the attach devices.
      if (attachedDevices.isNotEmpty) {
        globals.printStatus('\n${attachedDevices.length} connected ${pluralize('device', attachedDevices.length)}:\n');
        await Device.printDevices(attachedDevices, globals.logger);
      }
    } else if (globals.terminal.supportsColor) {
      globals.logger.printStatus(
        globals.terminal.clearLines(numLinesToClear),
        newline: false,
      );
    }

    if (attachedDevices.isNotEmpty || !globals.terminal.supportsColor) {
      globals.printStatus('');
    }

    if (wirelessDevices.isEmpty) {
      if (attachedDevices.isEmpty) {
        // No wireless or attached devices were found.
        globals.logger.printStatus('No devices detected.');
        _printNoDevicesDetected();
      } else {
        // Attached devices found, wireless devices not found.
        globals.logger.printStatus(userMessages.flutterNoWirelessDevicesFound);
      }
    } else {
      // Display list of wireless devices.
      globals.printStatus('${wirelessDevices.length} wirelessly connected ${pluralize('device', wirelessDevices.length)}:\n');
      await Device.printDevices(wirelessDevices, globals.logger);
    }
    await _printDiagnostics();
  }
}
