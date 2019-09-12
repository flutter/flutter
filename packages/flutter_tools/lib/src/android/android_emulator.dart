// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../android/android_sdk.dart';
import '../android/android_workflow.dart';
import '../base/file_system.dart';
import '../base/process.dart';
import '../device.dart';
import '../emulator.dart';
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
    final Future<void> launchResult = processUtils.run(
      <String>[getEmulatorPath(), '-avd', id],
      throwOnError: true,
    );
    // The emulator continues running on a successful launch, so if it hasn't
    // quit within 3 seconds we assume that's a success and just return. This
    // means that on a slow machine, a failure that takes more than three
    // seconds won't be recognized as such... :-/
    return Future.any<void>(<Future<void>>[
      launchResult,
      Future<void>.delayed(const Duration(seconds: 3)),
    ]);
  }
}

/// Return the list of available emulator AVDs.
List<AndroidEmulator> getEmulatorAvds() {
  final String emulatorPath = getEmulatorPath(androidSdk);
  if (emulatorPath == null) {
    return <AndroidEmulator>[];
  }

  final String listAvdsOutput = processUtils.runSync(
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
  for (String id in text.trim().split('\n').where((String l) => l != '')) {
    emulators.add(_loadEmulatorInfo(id));
  }
}

AndroidEmulator _loadEmulatorInfo(String id) {
  id = id.trim();
  final String avdPath = getAvdPath();
  if (avdPath != null) {
    final File iniFile = fs.file(fs.path.join(avdPath, '$id.ini'));
    if (iniFile.existsSync()) {
      final Map<String, String> ini = parseIniLines(iniFile.readAsLinesSync());
      if (ini['path'] != null) {
        final File configFile =
            fs.file(fs.path.join(ini['path'], 'config.ini'));
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

  for (List<String> property in properties) {
    results[property[0].trim()] = property[1].trim();
  }

  return results;
}
