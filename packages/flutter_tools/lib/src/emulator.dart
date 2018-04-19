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

  Stream<Emulator> getEmulatorsMatching(String searchText) async* {
    final List<Emulator> emulators = await getAllAvailableEmulators().toList();
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
      yield exactMatch;
      return;
    }

    // Match on a id or name starting with [emulatorId].
    for (Emulator emulator in emulators.where(startsWithEmulatorId))
      yield emulator;
  }

  Iterable<EmulatorDiscovery> get _platformDiscoverers {
    return _emulatorDiscoverers.where((EmulatorDiscovery discoverer) => discoverer.supportsPlatform);
  }

  /// Return the list of all available emulators.
  Stream<Emulator> getAllAvailableEmulators() async* {
    for (EmulatorDiscovery discoverer in _platformDiscoverers) {
      for (Emulator emulator in await discoverer.emulators) {
        yield emulator;
      }
    }
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

  void launch();

  @override
  String toString() => name;

  static Stream<String> descriptions(List<Emulator> emulators) async* {
    if (emulators.isEmpty)
      return;

    // Extract emulators information
    final List<List<String>> table = <List<String>>[];
    for (Emulator emulator in emulators) {
      table.add(<String>[
        emulator.name ?? emulator.id ?? '',
        emulator.manufacturer ?? '',
        emulator.label ?? '',
        emulator.id ?? '',
      ]);
    }

    // Calculate column widths
    final List<int> indices = new List<int>.generate(table[0].length - 1, (int i) => i);
    List<int> widths = indices.map((int i) => 0).toList();
    for (List<String> row in table) {
      widths = indices.map((int i) => math.max(widths[i], row[i].length)).toList();
    }

    // Join columns into lines of text
    for (List<String> row in table) {
      yield indices.map((int i) => row[i].padRight(widths[i])).join(' • ') + ' • ${row.last}';
    }
  }

  static Future<Null> printEmulators(List<Emulator> emulators) async {
    await descriptions(emulators).forEach(printStatus);
  }
}
