// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'android/android_emulator.dart';
import 'base/context.dart';
import 'globals.dart';
import 'ios/ios_emulators.dart';

EmulatorManager get emulatorManager => context[EmulatorManager];

/// A class to get all available emulators.
class EmulatorManager {
  /// Constructing EmulatorManager is cheap; they only do expensive work if some
  /// of their methods are called.
  EmulatorManager() {
    // Register the known discoverers.
    _emulatorDiscoverers.add(new AndroidEmulators());
    _emulatorDiscoverers.add(new IOSEmulators());
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

    final Emulator exactMatch = emulators.firstWhere(
        exactlyMatchesEmulatorId, orElse: () => null);
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
    await Future.forEach(_platformDiscoverers, (EmulatorDiscovery discoverer) async {
      emulators.addAll(await discoverer.emulators);
    });
    return emulators;
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
  String get label;

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

  Future<bool> launch();

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
        emulator.label ?? '',
      ]);
    }

    // Calculate column widths
    final List<int> indices = new List<int>.generate(table[0].length - 1, (int i) => i);
    List<int> widths = indices.map((int i) => 0).toList();
    for (List<String> row in table) {
      widths = indices.map((int i) => math.max(widths[i], row[i].length)).toList();
    }

    // Join columns into lines of text
    final RegExp whiteSpaceAndDots = new RegExp(r'[•\s]+$');
    return table.map((List<String> row) {
      return indices
        .map((int i) => row[i].padRight(widths[i]))
        .join(' • ') + ' • ${row.last}';
    })
        .map((String line) => line.replaceAll(whiteSpaceAndDots, ''))
        .toList();
  }

  static void printEmulators(List<Emulator> emulators) {
    descriptions(emulators).forEach(printStatus);
  }
}
