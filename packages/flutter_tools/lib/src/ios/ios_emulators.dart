// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../device.dart';
import '../emulator.dart';
import '../macos/xcode.dart';
import 'ios_workflow.dart';
import 'simulators.dart';

class IOSEmulators extends EmulatorDiscovery {
  IOSEmulators({
    Platform? platform,
    this._iosWorkflow,
    this._xcode,
    required this._processUtils,
    required this._logger,
  }) : _platform = platform ?? const LocalPlatform();

  final Platform _platform;
  final IOSWorkflow? _iosWorkflow;
  final Xcode? _xcode;
  final ProcessUtils _processUtils;
  final Logger _logger;

  @override
  bool get supportsPlatform => _platform.isMacOS;

  @override
  bool get canListAnything =>
      _iosWorkflow?.canListEmulators ??
      (_platform.isMacOS && (_xcode?.isInstalledAndMeetsVersionCheck ?? false));

  @override
  Future<List<Emulator>> get emulators async =>
      getEmulators(xcode: _xcode, processUtils: _processUtils, logger: _logger);

  @override
  bool get canLaunchAnything => canListAnything;
}

class IOSEmulator extends Emulator {
  const IOSEmulator(String id, {this._xcode, required this._processUtils, required this._logger})
    : super(id, true);

  final Xcode? _xcode;
  final ProcessUtils _processUtils;
  final Logger _logger;

  @override
  String get name => 'iOS Simulator';

  @override
  String get manufacturer => 'Apple';

  @override
  Category get category => Category.mobile;

  @override
  PlatformType get platformType => PlatformType.ios;

  @override
  Future<void> launch({bool coldBoot = false}) async {
    final String? simulatorPath = _xcode?.getSimulatorPath();
    if (simulatorPath == null) {
      throwToolExit('Could not find Simulator app');
    }
    Future<bool> launchSimulator(List<String> additionalArgs) async {
      final args = <String>['open', ...additionalArgs, '-a', simulatorPath];

      final RunResult launchResult = await _processUtils.run(args);
      if (launchResult.exitCode != 0) {
        _logger.printError('$launchResult');
        return false;
      }
      return true;
    }

    // First run with `-n` to force a device to boot if there isn't already one
    if (!await launchSimulator(<String>['-n'])) {
      return;
    }

    // Run again to force it to Foreground (using -n doesn't force existing
    // devices to the foreground)
    await launchSimulator(<String>[]);
  }
}

/// Return the list of iOS Simulators (there can only be zero or one).
List<IOSEmulator> getEmulators({
  Xcode? xcode,
  required ProcessUtils processUtils,
  required Logger logger,
}) {
  final String? simulatorPath = xcode?.getSimulatorPath();
  if (simulatorPath == null) {
    return <IOSEmulator>[];
  }

  return <IOSEmulator>[
    IOSEmulator(iosSimulatorId, xcode: xcode, processUtils: processUtils, logger: logger),
  ];
}
