// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:simulators/simulator_manager.dart';

import 'browser_lock.dart';
import 'common.dart';
import 'utils.dart';

/// Returns [IosSimulator] if the [Platform] is `macOS` and simulator
/// is started.
///
/// Throws an [StateError] if these two conditions are not met.
IosSimulator get iosSimulator {
  if (!io.Platform.isMacOS) {
    throw StateError('iOS Simulator is only available on macOS machines.');
  }
  if (_iosSimulator == null) {
    throw StateError(
      'iOS Simulator not started. Please first call initIOSSimulator method',
    );
  }
  return _iosSimulator!;
}
IosSimulator? _iosSimulator;

/// Inializes and boots an [IosSimulator] using the [iosMajorVersion],
/// [iosMinorVersion] and [iosDevice] arguments.
Future<void> initIosSimulator() async {
  if (_iosSimulator != null) {
    throw StateError('_iosSimulator can only be initialized once');
  }
  final IosSimulatorManager iosSimulatorManager = IosSimulatorManager();
  final IosSimulator simulator;
  final SafariIosLock lock = browserLock.safariIosLock;
  try {
    simulator = await iosSimulatorManager.getSimulator(
      lock.majorVersion,
      lock.minorVersion,
      lock.device,
    );
    _iosSimulator = simulator;
  } catch (e) {
    io.stderr.writeln(
      'Error getting iOS Simulator for ${lock.simulatorDescription}.\n'
      'Try running `felt create` command before running tests.',
    );
    rethrow;
  }

  if (!simulator.booted) {
    await simulator.boot();
    print('INFO: Simulator ${simulator.id} booted.');
    cleanupCallbacks.add(() async {
      await simulator.shutdown();
      print('INFO: Simulator ${simulator.id} shutdown.');
    });
  }
}

/// Returns the installation of Safari.
///
/// Currently uses the Safari version installed on the operating system.
///
/// Latest Safari version for Catalina, Mojave, High Siera is 13.
///
/// Latest Safari version for Sierra is 12.
Future<BrowserInstallation> getOrInstallSafari({
  StringSink? infoLog,
}) async {
  // These tests are aimed to run only on macOS machines local or on LUCI.
  if (!io.Platform.isMacOS) {
    throw UnimplementedError('Safari on ${io.Platform.operatingSystem} is'
        ' not supported. Safari is only supported on macOS.');
  }

  infoLog ??= io.stdout;

  // Since Safari is included in macOS, always assume there will be one on the
  // system.
  infoLog.writeln('Using the system version that is already installed.');
  return BrowserInstallation(
    version: 'system',
    executable: PlatformBinding.instance.getMacApplicationLauncher(),
  );
}
