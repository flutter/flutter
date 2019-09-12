// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'android/android_emulator.dart';
import 'android/android_sdk.dart';
import 'base/context.dart';
import 'base/process.dart';
import 'device.dart';
import 'globals.dart';
import 'ios/ios_emulators.dart';

EmulatorManager get emulatorManager => context.get<EmulatorManager>();

/// A class to get all available emulators.
class EmulatorManager {
  /// Constructing EmulatorManager is cheap; they only do expensive work if some
  /// of their methods are called.
  EmulatorManager() {
    // Register the known discoverers.
    _emulatorDiscoverers.add(AndroidEmulators());
    _emulatorDiscoverers.add(IOSEmulators());
  }

  final List<EmulatorDiscovery> _emulatorDiscoverers = <EmulatorDiscovery>[];

  Future<List<Emulator>> getEmulatorsMatching(String searchText) async {
    final List<Emulator> emulators = await getAllAvailableEmulators();
    searchText = searchText.toLowerCase();
    bool exactlyMatchesEmulatorId(Emulator emulator) =>
        emulator.id?.toLowerCase() == searchText ||
        emulator.name?.toLowerCase() == searchText;
    bool startsWithEmulatorId(Emulator emulator) =>
        emulator.id?.toLowerCase()?.startsWith(searchText) == true ||
        emulator.name?.toLowerCase()?.startsWith(searchText) == true;

    final Emulator exactMatch =
        emulators.firstWhere(exactlyMatchesEmulatorId, orElse: () => null);
    if (exactMatch != null) {
      return <Emulator>[exactMatch];
    }

    // Match on a id or name starting with [emulatorId].
    return emulators.where(startsWithEmulatorId).toList();
  }

  Iterable<EmulatorDiscovery> get _platformDiscoverers {
    return _emulatorDiscoverers.where((EmulatorDiscovery discoverer) => discoverer.supportsPlatform);
  }

  /// Return the list of all available emulators.
  Future<List<Emulator>> getAllAvailableEmulators() async {
    final List<Emulator> emulators = <Emulator>[];
    await Future.forEach<EmulatorDiscovery>(_platformDiscoverers, (EmulatorDiscovery discoverer) async {
      emulators.addAll(await discoverer.emulators);
    });
    return emulators;
  }

  /// Return the list of all available emulators.
  Future<CreateEmulatorResult> createEmulator({ String name }) async {
    if (name == null || name == '') {
      const String autoName = 'flutter_emulator';
      // Don't use getEmulatorsMatching here, as it will only return one
      // if there's an exact match and we need all those with this prefix
      // so we can keep adding suffixes until we miss.
      final List<Emulator> all = await getAllAvailableEmulators();
      final Set<String> takenNames = all
          .map<String>((Emulator e) => e.id)
          .where((String id) => id.startsWith(autoName))
          .toSet();
      int suffix = 1;
      name = autoName;
      while (takenNames.contains(name)) {
        name = '${autoName}_${++suffix}';
      }
    }

    final String device = await _getPreferredAvailableDevice();
    if (device == null)
      return CreateEmulatorResult(name,
          success: false, error: 'No device definitions are available');

    final String sdkId = await _getPreferredSdkId();
    if (sdkId == null)
      return CreateEmulatorResult(name,
          success: false,
          error:
              'No suitable Android AVD system images are available. You may need to install these'
              ' using sdkmanager, for example:\n'
              '  sdkmanager "system-images;android-27;google_apis_playstore;x86"');

    // Cleans up error output from avdmanager to make it more suitable to show
    // to flutter users. Specifically:
    // - Removes lines that say "null" (!)
    // - Removes lines that tell the user to use '--force' to overwrite emulators
    String cleanError(String error) {
      if (error == null || error.trim() == '')
        return null;
      return error
          .split('\n')
          .where((String l) => l.trim() != 'null')
          .where((String l) =>
              l.trim() != 'Use --force if you want to replace it.')
          .join('\n')
          .trim();
    }

    final List<String> args = <String>[
      getAvdManagerPath(androidSdk),
      'create',
      'avd',
      '-n', name,
      '-k', sdkId,
      '-d', device,
    ];
    final RunResult runResult = processUtils.runSync(args,
        environment: androidSdk?.sdkManagerEnv);
    return CreateEmulatorResult(
      name,
      success: runResult.exitCode == 0,
      output: runResult.stdout,
      error: cleanError(runResult.stderr),
    );
  }

  static const List<String> preferredDevices = <String>[
    'pixel',
    'pixel_xl',
  ];
  Future<String> _getPreferredAvailableDevice() async {
    final List<String> args = <String>[
      getAvdManagerPath(androidSdk),
      'list',
      'device',
      '-c',
    ];
    final RunResult runResult = processUtils.runSync(args,
        environment: androidSdk?.sdkManagerEnv);
    if (runResult.exitCode != 0) {
      return null;
    }

    final List<String> availableDevices = runResult.stdout
        .split('\n')
        .where((String l) => preferredDevices.contains(l.trim()))
        .toList();

    return preferredDevices.firstWhere(
      (String d) => availableDevices.contains(d),
      orElse: () => null,
    );
  }

  RegExp androidApiVersion = RegExp(r';android-(\d+);');
  Future<String> _getPreferredSdkId() async {
    // It seems that to get the available list of images, we need to send a
    // request to create without the image and it'll provide us a list :-(
    final List<String> args = <String>[
      getAvdManagerPath(androidSdk),
      'create',
      'avd',
      '-n', 'temp',
    ];
    final RunResult runResult = processUtils.runSync(args,
        environment: androidSdk?.sdkManagerEnv);

    // Get the list of IDs that match our criteria
    final List<String> availableIDs = runResult.stderr
        .split('\n')
        .where((String l) => androidApiVersion.hasMatch(l))
        .where((String l) => l.contains('system-images'))
        .where((String l) => l.contains('google_apis_playstore'))
        .toList();

    final List<int> availableApiVersions = availableIDs
        .map<String>((String id) => androidApiVersion.firstMatch(id).group(1))
        .map<int>((String apiVersion) => int.parse(apiVersion))
        .toList();

    // Get the highest Android API version or whats left
    final int apiVersion = availableApiVersions.isNotEmpty
        ? availableApiVersions.reduce(math.max)
        : -1; // Don't match below

    // We're out of preferences, we just have to return the first one with the high
    // API version.
    return availableIDs.firstWhere(
      (String id) => id.contains(';android-$apiVersion;'),
      orElse: () => null,
    );
  }

  /// Whether we're capable of listing any emulators given the current environment configuration.
  bool get canListAnything {
    return _platformDiscoverers.any((EmulatorDiscovery discoverer) => discoverer.canListAnything);
  }
}

/// An abstract class to discover and enumerate a specific type of emulators.
abstract class EmulatorDiscovery {
  bool get supportsPlatform;

  /// Whether this emulator discovery is capable of listing any emulators given the
  /// current environment configuration.
  bool get canListAnything;

  Future<List<Emulator>> get emulators;
}

abstract class Emulator {
  Emulator(this.id, this.hasConfig);

  final String id;
  final bool hasConfig;
  String get name;
  String get manufacturer;
  Category get category;
  PlatformType get platformType;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! Emulator)
      return false;
    return id == other.id;
  }

  Future<void> launch();

  @override
  String toString() => name;

  static List<String> descriptions(List<Emulator> emulators) {
    if (emulators.isEmpty)
      return <String>[];

    // Extract emulators information
    final List<List<String>> table = <List<String>>[];
    for (Emulator emulator in emulators) {
      table.add(<String>[
        emulator.id ?? '',
        emulator.name ?? '',
        emulator.manufacturer ?? '',
        emulator.platformType?.toString() ?? '',
      ]);
    }

    // Calculate column widths
    final List<int> indices = List<int>.generate(table[0].length - 1, (int i) => i);
    List<int> widths = indices.map<int>((int i) => 0).toList();
    for (List<String> row in table) {
      widths = indices.map<int>((int i) => math.max(widths[i], row[i].length)).toList();
    }

    // Join columns into lines of text
    final RegExp whiteSpaceAndDots = RegExp(r'[•\s]+$');
    return table
        .map<String>((List<String> row) {
          return indices
                  .map<String>((int i) => row[i].padRight(widths[i]))
                  .join(' • ') +
              ' • ${row.last}';
        })
        .map<String>((String line) => line.replaceAll(whiteSpaceAndDots, ''))
        .toList();
  }

  static void printEmulators(List<Emulator> emulators) {
    descriptions(emulators).forEach(printStatus);
  }
}

class CreateEmulatorResult {
  CreateEmulatorResult(this.emulatorName, {this.success, this.output, this.error});

  final bool success;
  final String emulatorName;
  final String output;
  final String error;
}
