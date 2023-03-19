// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
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

    final DevicesCommandOutput output = DevicesCommandOutput(
      deviceDiscoveryTimeout: deviceDiscoveryTimeout,
    );

    await output.findAndOutputAllTargetDevices(
      machine: boolArg('machine'),
    );

    return FlutterCommandResult.success();
  }
}

class DevicesCommandOutput {
  DevicesCommandOutput({this.deviceDiscoveryTimeout});

  final Duration? deviceDiscoveryTimeout;

  Future<List<Device>> _getAttachedDevices(DeviceManager deviceManager) async {
    return deviceManager.getAllDevices(
      filter: DeviceDiscoveryFilter(
        deviceConnectionInterface: DeviceConnectionInterface.attached,
      ),
    );
  }

  Future<List<Device>> _getWirelessDevices(DeviceManager deviceManager) async {
    return deviceManager.getAllDevices(
      filter: DeviceDiscoveryFilter(
        deviceConnectionInterface: DeviceConnectionInterface.wireless,
      ),
    );
  }

  Future<void> findAndOutputAllTargetDevices({required bool machine}) async {
    List<Device> attachedDevices = <Device>[];
    List<Device> wirelessDevices = <Device>[];
    final DeviceManager? deviceManager = globals.deviceManager;
    if (deviceManager != null) {
      // Refresh the cache and then get the attached and wireless devices from
      // the cache.
      await deviceManager.refreshAllDevices(timeout: deviceDiscoveryTimeout);
      attachedDevices = await _getAttachedDevices(deviceManager);
      wirelessDevices = await _getWirelessDevices(deviceManager);
    }
    final List<Device> allDevices = attachedDevices + wirelessDevices;

    if (machine) {
      await printDevicesAsJson(allDevices);
      return;
    }

    if (allDevices.isEmpty) {
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
    final StringBuffer status = StringBuffer('No devices detected.');
    status.writeln();
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
