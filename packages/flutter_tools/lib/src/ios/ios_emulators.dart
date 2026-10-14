// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../context/tool_context.dart';
import '../device.dart';
import '../emulator.dart';
import '../macos/xcode.dart';
import 'ios_workflow.dart';
import 'simulators.dart';

class IOSEmulators extends EmulatorDiscovery {
  IOSEmulators({required this._iosWorkflow, required this._toolContext, required this._xcode});

  final IOSWorkflow? _iosWorkflow;
  final ToolContext _toolContext;
  final Xcode? _xcode;

  @override
  bool get supportsPlatform => _toolContext.platform.isMacOS;

  @override
  bool get canListAnything => _iosWorkflow?.canListEmulators ?? false;

  @override
  Future<List<Emulator>> get emulators async =>
      getEmulators(toolContext: _toolContext, xcode: _xcode);

  @override
  bool get canLaunchAnything => canListAnything;
}

class IOSEmulator extends Emulator {
  const IOSEmulator(String id, {required this._toolContext, required this._xcode})
    : super(id, true);

  final ToolContext _toolContext;
  final Xcode _xcode;

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
    final String? simulatorPath = _xcode.getSimulatorPath();
    if (simulatorPath == null) {
      throwToolExit('Could not find Simulator app');
    }
    final ToolContext(:Logger logger, :ProcessUtils processUtils) = _toolContext;
    Future<bool> launchSimulator(List<String> additionalArgs) async {
      final args = <String>['open', ...additionalArgs, '-a', simulatorPath];

      final RunResult launchResult = await processUtils.run(args);
      if (launchResult.exitCode != 0) {
        logger.printError('$launchResult');
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
List<IOSEmulator> getEmulators({required ToolContext toolContext, required Xcode? xcode}) {
  final String? simulatorPath = xcode?.getSimulatorPath();
  if (simulatorPath == null) {
    return <IOSEmulator>[];
  }

  return <IOSEmulator>[IOSEmulator(iosSimulatorId, toolContext: toolContext, xcode: xcode!)];
}
