// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../android/android_sdk.dart';
import '../android/android_workflow.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/utils.dart';
import '../convert.dart';
import '../device.dart';
import '../emulator.dart';
import '../globals.dart' as globals;
import 'android_sdk.dart';

class AndroidEmulators extends EmulatorDiscovery {
  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => androidWorkflow.canListEmulators;

  @override
  Future<List<Emulator>> get emulators async => getEmulatorAvds();
}

class AndroidEmulator extends Emulator {
  AndroidEmulator(String id, [this._properties])
    : super(id, _properties != null && _properties.isNotEmpty);

  final Map<String, String> _properties;

  // Android Studio uses the ID with underscores replaced with spaces
  // for the name if displayname is not set so we do the same.
  @override
  String get name => _prop('avd.ini.displayname') ?? id.replaceAll('_', ' ').trim();

  @override
  String get manufacturer => _prop('hw.device.manufacturer');

  @override
  Category get category => Category.mobile;

  @override
  PlatformType get platformType => PlatformType.android;

  String _prop(String name) => _properties != null ? _properties[name] : null;

  @override
  Future<void> launch() async {
    final Process process = await globals.processUtils.start(
      <String>[getEmulatorPath(androidSdk), '-avd', id],
    );

    // Record output from the emulator process.
    final List<String> stdoutList = <String>[];
    final List<String> stderrList = <String>[];
    final StreamSubscription<String> stdoutSubscription = process.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen(stdoutList.add);
    final StreamSubscription<String> stderrSubscription = process.stderr
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen(stderrList.add);
    final Future<void> stdioFuture = waitGroup<void>(<Future<void>>[
      stdoutSubscription.asFuture<void>(),
      stderrSubscription.asFuture<void>(),
    ]);

    // The emulator continues running on success, so we don't wait for the
    // process to complete before continuing. However, if the process fails
    // after the startup phase (3 seconds), then we only echo its output if
    // its error code is non-zero and its stderr is non-empty.
    bool earlyFailure = true;
    unawaited(process.exitCode.then((int status) async {
      if (status == 0) {
        globals.printTrace('The Android emulator exited successfully');
        return;
      }
      // Make sure the process' stdout and stderr are drained.
      await stdioFuture;
      unawaited(stdoutSubscription.cancel());
      unawaited(stderrSubscription.cancel());
      if (stdoutList.isNotEmpty) {
        globals.printTrace('Android emulator stdout:');
        stdoutList.forEach(globals.printTrace);
      }
      if (!earlyFailure && stderrList.isEmpty) {
        globals.printStatus('The Android emulator exited with code $status');
        return;
      }
      final String when = earlyFailure ? 'during startup' : 'after startup';
      globals.printError('The Android emulator exited with code $status $when');
      globals.printError('Android emulator stderr:');
      stderrList.forEach(globals.printError);
      globals.printError('Address these issues and try again.');
    }));

    // Wait a few seconds for the emulator to start.
    await Future<void>.delayed(const Duration(seconds: 3));
    earlyFailure = false;
    return;
  }
}

/// Return the list of available emulator AVDs.
List<AndroidEmulator> getEmulatorAvds() {
  final String emulatorPath = getEmulatorPath(androidSdk);
  if (emulatorPath == null) {
    return <AndroidEmulator>[];
  }

  final String listAvdsOutput = globals.processUtils.runSync(
    <String>[emulatorPath, '-list-avds']).stdout.trim();

  final List<AndroidEmulator> emulators = <AndroidEmulator>[];
  if (listAvdsOutput != null) {
    extractEmulatorAvdInfo(listAvdsOutput, emulators);
  }
  return emulators;
}

/// Parse the given `emulator -list-avds` output in [text], and fill out the given list
/// of emulators by reading information from the relevant ini files.
void extractEmulatorAvdInfo(String text, List<AndroidEmulator> emulators) {
  for (final String id in text.trim().split('\n').where((String l) => l != '')) {
    emulators.add(_loadEmulatorInfo(id));
  }
}

AndroidEmulator _loadEmulatorInfo(String id) {
  id = id.trim();
  final String avdPath = getAvdPath();
  if (avdPath != null) {
    final File iniFile = globals.fs.file(globals.fs.path.join(avdPath, '$id.ini'));
    if (iniFile.existsSync()) {
      final Map<String, String> ini = parseIniLines(iniFile.readAsLinesSync());
      if (ini['path'] != null) {
        final File configFile =
            globals.fs.file(globals.fs.path.join(ini['path'], 'config.ini'));
        if (configFile.existsSync()) {
          final Map<String, String> properties =
              parseIniLines(configFile.readAsLinesSync());
          return AndroidEmulator(id, properties);
        }
      }
    }
  }

  return AndroidEmulator(id);
}

@visibleForTesting
Map<String, String> parseIniLines(List<String> contents) {
  final Map<String, String> results = <String, String>{};

  final Iterable<List<String>> properties = contents
      .map<String>((String l) => l.trim())
      // Strip blank lines/comments
      .where((String l) => l != '' && !l.startsWith('#'))
      // Discard anything that isn't simple name=value
      .where((String l) => l.contains('='))
      // Split into name/value
      .map<List<String>>((String l) => l.split('='));

  for (final List<String> property in properties) {
    results[property[0].trim()] = property[1].trim();
  }

  return results;
}
