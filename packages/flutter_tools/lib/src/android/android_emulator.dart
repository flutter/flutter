// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../android/android_sdk.dart';
import '../android/android_workflow.dart';
import '../base/file_system.dart';
import '../base/process.dart';
import '../emulator.dart';
import '../globals.dart';
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

  Map<String, String> _properties;

  @override
  String get name => _properties['hw.device.name'];

  @override
  String get manufacturer => _properties['hw.device.manufacturer'];

  @override
  String get label => _properties['avd.ini.displayname'];

  @override
  Future<bool> launch() async {
    final RunResult launchResult =
        await runAsync(<String>[getEmulatorPath(), '-avd', id]);
    if (launchResult.exitCode != 0) {
      printError(
          'Error: emulator exited with exit code ${launchResult.exitCode}');
      printError('$launchResult');
      return false;
    }

    return true;
  }
}

/// Return the list of available emulator AVDs.
List<AndroidEmulator> getEmulatorAvds() {
  final String emulatorPath = getEmulatorPath(androidSdk);
  if (emulatorPath == null) {
    return <AndroidEmulator>[];
  }

  final String listAvdsOutput = runSync(<String>[emulatorPath, '-list-avds']);

  final List<AndroidEmulator> emulators = <AndroidEmulator>[];
  extractEmulatorAvdInfo(listAvdsOutput, emulators);
  return emulators;
}

/// Parse the given `emulator -list-avds` output in [text], and fill out the given list
/// of emulators by reading information from the relevant ini files.
void extractEmulatorAvdInfo(String text, List<AndroidEmulator> emulators) {
  for (String id in text.trim().split('\n')) {
    emulators.add(_createEmulator(id));
  }
}

AndroidEmulator _createEmulator(String id) {
  id = id.trim();
  final File iniFile = fs.file(fs.path.join(getAvdPath(), '$id.ini'));
  final Map<String, String> ini = parseIniLines(iniFile.readAsLinesSync());

  if (ini['path'] != null) {
    final File configFile = fs.file(fs.path.join(ini['path'], 'config.ini'));
    if (configFile.existsSync()) {
      final Map<String, String> properties =
          parseIniLines(configFile.readAsLinesSync());
      return new AndroidEmulator(id, properties);
    }
  }

  return new AndroidEmulator(id);
}

@visibleForTesting
Map<String, String> parseIniLines(List<String> contents) {
  final Map<String, String> results = <String, String>{};

  final Iterable<List<String>> properties = contents
      .map((String l) => l.trim())
      // Strip blank lines/comments
      .where((String l) => l != '' && !l.startsWith('#'))
      // Discard anything that isn't simple name=value
      .where((String l) => l.contains('='))
      // Split into name/value
      .map((String l) => l.split('='));

  for (List<String> property in properties) {
    results[property[0].trim()] = property[1].trim();
  }

  return results;
}
