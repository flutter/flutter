// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/file_system.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../emulator.dart';
import '../globals.dart';
import '../ios/mac.dart';
import 'ios_workflow.dart';

class IOSEmulators extends EmulatorDiscovery {
  @override
  bool get supportsPlatform => platform.isMacOS;

  @override
  bool get canListAnything => iosWorkflow.canListEmulators;

  @override
  Future<List<Emulator>> get emulators async => getEmulators();
}

class IOSEmulator extends Emulator {
  IOSEmulator(String id) : super(id, true);

  @override
  String get name => 'iOS Simulator';

  @override
  String get manufacturer => 'Apple';

  @override
  String get label => null;

  @override
  Future<void> launch() async {
    final RunResult launchResult =
        await runAsync(<String>['open', '-a', getSimulatorPath()]);
    if (launchResult.exitCode != 0) {
      printError('$launchResult');
    }
  }
}

/// Return the list of iOS Simulators (there can only be zero or one).
List<IOSEmulator> getEmulators() {
  final String simulatorPath = getSimulatorPath();
  if (simulatorPath == null) {
    return <IOSEmulator>[];
  }

  return <IOSEmulator>[new IOSEmulator('apple_ios_simulator')];
}

String getSimulatorPath() {
  final List<String> searchPaths = <String>[
    fs.path.join(xcode.xcodeSelectPath, 'Applications', 'Simulator.app'),
  ];
  return searchPaths.where((String p) => p != null).firstWhere(
        (String p) => fs.directory(p).existsSync(),
        orElse: () => null,
      );
}
