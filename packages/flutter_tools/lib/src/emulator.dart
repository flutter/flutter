// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'android/android_emulator.dart';
import 'base/context.dart';
import 'globals.dart';

EmulatorManager get emulatorManager => context[EmulatorManager];

/// A class to get all available emulators.
class EmulatorManager {
  /// Constructing EmulatorManager is cheap; they only do expensive work if some
  /// of their methods are called.
  EmulatorManager() {
    // Register the known discoverers.
    _emulatorDiscoverers.add(new AndroidEmulators());
  }

  final List<EmulatorDiscovery> _emulatorDiscoverers = <EmulatorDiscovery>[];

  String _specifiedEmulatorId;

  /// A user-specified emulator ID.
  String get specifiedEmulatorId {
    if (_specifiedEmulatorId == null || _specifiedEmulatorId == 'all')
      return null;
    return _specifiedEmulatorId;
  }

  set specifiedEmulatorId(String id) {
    _specifiedEmulatorId = id;
  }

  /// True when the user has specified a single specific emulator.
  bool get hasSpecifiedEmulatorId => specifiedEmulatorId != null;

  /// True when the user has specified all emulators by setting
  /// specifiedEmulatorId = 'all'.
  bool get hasSpecifiedAllEmulators => _specifiedEmulatorId == 'all';

  Stream<Emulator> getEmulatorsById(String emulatorId) async* {
    final List<Emulator> emulators = await getAllAvailableEmulators().toList();
    emulatorId = emulatorId.toLowerCase();
    bool exactlyMatchesEmulatorId(Emulator emulator) =>
        emulator.id.toLowerCase() == emulatorId ||
        emulator.name.toLowerCase() == emulatorId;
    bool startsWithEmulatorId(Emulator emulator) =>
        emulator.id.toLowerCase().startsWith(emulatorId) ||
        emulator.name.toLowerCase().startsWith(emulatorId);

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

  /// Return the list of available emulators, filtered by any user-specified emulator id.
  Stream<Emulator> getEmulators() {
    return hasSpecifiedEmulatorId
        ? getEmulatorsById(specifiedEmulatorId)
        : getAllAvailableEmulators();
  }

  Iterable<EmulatorDiscovery> get _platformDiscoverers {
    return _emulatorDiscoverers.where((EmulatorDiscovery discoverer) => discoverer.supportsPlatform);
  }

  /// Return the list of all connected emulators.
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

  /// Get diagnostics about issues with any emulators.
  Future<List<String>> getEmulatorDiagnostics() async {
    final List<String> diagnostics = <String>[];
    for (EmulatorDiscovery discoverer in _platformDiscoverers) {
      diagnostics.addAll(await discoverer.getDiagnostics());
    }
    return diagnostics;
  }
}

/// An abstract class to discover and enumerate a specific type of emulators.
abstract class EmulatorDiscovery {
  bool get supportsPlatform;

  /// Whether this emulator discovery is capable of listing any emulators given the
  /// current environment configuration.
  bool get canListAnything;

  Future<List<Emulator>> get emulators;

  /// Gets a list of diagnostic messages pertaining to issues with any available
  /// emulators (will be an empty list if there are no issues).
  Future<List<String>> getDiagnostics() => new Future<List<String>>.value(<String>[]);
}

abstract class Emulator {
  Emulator(this.id);

  final String id;

  String get name;

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

  @override
  String toString() => name;

  static Stream<String> descriptions(List<Emulator> emulators) async* {
    if (emulators.isEmpty)
      return;

    // Extract emulators information
    final List<List<String>> table = <List<String>>[];
    for (Emulator emulator in emulators) {
      table.add(<String>[
        emulator.name,
        emulator.id,
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
