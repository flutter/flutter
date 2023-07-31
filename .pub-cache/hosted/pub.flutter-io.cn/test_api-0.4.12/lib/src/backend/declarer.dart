// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:stack_trace/stack_trace.dart';

import 'configuration/timeout.dart';
import 'group.dart';
import 'group_entry.dart';
import 'invoker.dart';
import 'metadata.dart';
import 'test.dart';

/// A class that manages the state of tests as they're declared.
///
/// A nested tree of Declarers tracks the current group, set-up, and tear-down
/// functions. Each Declarer in the tree corresponds to a group. This tree is
/// tracked by a zone-scoped "current" Declarer; the current declarer can be set
/// for a block using [Declarer.declare], and it can be accessed using
/// [Declarer.current].
class Declarer {
  /// The parent declarer, or `null` if this corresponds to the root group.
  final Declarer? _parent;

  /// The name of the current test group, including the name of any parent
  /// groups.
  ///
  /// This is `null` if this is the root group.
  final String? _name;

  /// The metadata for this group, including the metadata of any parent groups
  /// and of the test suite.
  final Metadata _metadata;

  /// The set of variables that are valid for platform selectors, in addition to
  /// the built-in variables that are allowed everywhere.
  final Set<String> _platformVariables;

  /// The stack trace for this group.
  ///
  /// This is `null` for the root (implicit) group.
  final Trace? _trace;

  /// Whether to collect stack traces for [GroupEntry]s.
  final bool _collectTraces;

  /// Whether to disable retries of tests.
  final bool _noRetry;

  /// The set-up functions to run for each test in this group.
  final _setUps = <dynamic Function()>[];

  /// The tear-down functions to run for each test in this group.
  final _tearDowns = <dynamic Function()>[];

  /// The set-up functions to run once for this group.
  final _setUpAlls = <dynamic Function()>[];

  /// The default timeout for synthetic tests.
  final _timeout = Timeout(Duration(minutes: 12));

  /// The trace for the first call to [setUpAll].
  ///
  /// All [setUpAll]s are run in a single logical test, so they can only have
  /// one trace. The first trace is most often correct, since the first
  /// [setUpAll] is always run and the rest are only run if that one succeeds.
  Trace? _setUpAllTrace;

  /// The tear-down functions to run once for this group.
  final _tearDownAlls = <Function()>[];

  /// The trace for the first call to [tearDownAll].
  ///
  /// All [tearDownAll]s are run in a single logical test, so they can only have
  /// one trace. The first trace matches [_setUpAllTrace].
  Trace? _tearDownAllTrace;

  /// The children of this group, either tests or sub-groups.
  ///
  /// All modifications to this must go through [_addEntry].
  final _entries = <GroupEntry>[];

  /// Whether [build] has been called for this declarer.
  bool _built = false;

  /// The tests and/or groups that have been flagged as solo.
  final _soloEntries = <GroupEntry>[];

  /// Whether any tests and/or groups have been flagged as solo.
  bool get _solo => _soloEntries.isNotEmpty;

  /// An exact full test name to match.
  ///
  /// When non-null only tests with exactly this name will be considered. The
  /// full test name is the combination of the test case name with all group
  /// prefixes. All other tests, including their metadata like `solo`, is
  /// ignored. Uniqueness is not guaranteed so this may match more than one
  /// test.
  ///
  /// Groups which are not a strict prefix of this name will be ignored.
  final String? _fullTestName;

  /// The current zone-scoped declarer.
  static Declarer? get current => Zone.current[#test.declarer] as Declarer?;

  /// All the test and group names that have been declared in the entire suite.
  ///
  /// If duplicate test names are allowed, this is not tracked and it will be
  /// `null`.
  final Set<String>? _seenNames;

  /// Creates a new declarer for the root group.
  ///
  /// This is the implicit group that exists outside of any calls to `group()`.
  /// If [metadata] is passed, it's used as the metadata for the implicit root
  /// group.
  ///
  /// The [platformVariables] are the set of variables that are valid for
  /// platform selectors in test and group metadata, in addition to the built-in
  /// variables that are allowed everywhere.
  ///
  /// If [collectTraces] is `true`, this will set [GroupEntry.trace] for all
  /// entries built by the declarer. Note that this can be noticeably slow when
  /// thousands of tests are being declared (see #457).
  ///
  /// If [noRetry] is `true` tests will be run at most once.
  ///
  /// If [allowDuplicateTestNames] is `false`, then a
  /// [DuplicateTestNameException] will be thrown if two tests (or groups) have
  /// the same name.
  Declarer({
    Metadata? metadata,
    Set<String>? platformVariables,
    bool collectTraces = false,
    bool noRetry = false,
    String? fullTestName,
    // TODO: Change the default https://github.com/dart-lang/test/issues/1571
    bool allowDuplicateTestNames = true,
  }) : this._(
            null,
            null,
            metadata ?? Metadata(),
            platformVariables ?? const UnmodifiableSetView.empty(),
            collectTraces,
            null,
            noRetry,
            fullTestName,
            allowDuplicateTestNames ? null : <String>{});

  Declarer._(
    this._parent,
    this._name,
    this._metadata,
    this._platformVariables,
    this._collectTraces,
    this._trace,
    this._noRetry,
    this._fullTestName,
    this._seenNames,
  );

  /// Runs [body] with this declarer as [Declarer.current].
  ///
  /// Returns the return value of [body].
  T declare<T>(T Function() body) =>
      runZoned(body, zoneValues: {#test.declarer: this});

  /// Defines a test case with the given name and body.
  void test(String name, dynamic Function() body,
      {String? testOn,
      Timeout? timeout,
      skip,
      Map<String, dynamic>? onPlatform,
      tags,
      int? retry,
      bool solo = false}) {
    _checkNotBuilt('test');

    final fullName = _prefix(name);
    if (_fullTestName != null && fullName != _fullTestName) {
      return;
    }

    var newMetadata = Metadata.parse(
        testOn: testOn,
        timeout: timeout,
        skip: skip,
        onPlatform: onPlatform,
        tags: tags,
        retry: _noRetry ? 0 : retry);
    newMetadata.validatePlatformSelectors(_platformVariables);
    var metadata = _metadata.merge(newMetadata);
    _addEntry(LocalTest(fullName, metadata, () async {
      var parents = <Declarer>[];
      for (Declarer? declarer = this;
          declarer != null;
          declarer = declarer._parent) {
        parents.add(declarer);
      }

      // Register all tear-down functions in all declarers. Iterate through
      // parents outside-in so that the Invoker gets the functions in the order
      // they were declared in source.
      for (var declarer in parents.reversed) {
        for (var tearDown in declarer._tearDowns) {
          Invoker.current!.addTearDown(tearDown);
        }
      }

      await runZoned(() async {
        await _runSetUps();
        await body();
      },
          // Make the declarer visible to running tests so that they'll throw
          // useful errors when calling `test()` and `group()` within a test.
          zoneValues: {#test.declarer: this});
    }, trace: _collectTraces ? Trace.current(2) : null, guarded: false));

    if (solo) {
      _soloEntries.add(_entries.last);
    }
  }

  /// Creates a group of tests.
  void group(String name, void Function() body,
      {String? testOn,
      Timeout? timeout,
      skip,
      Map<String, dynamic>? onPlatform,
      tags,
      int? retry,
      bool solo = false}) {
    _checkNotBuilt('group');

    final fullTestPrefix = _prefix(name);
    if (_fullTestName != null && !_fullTestName!.startsWith(fullTestPrefix)) {
      return;
    }

    var newMetadata = Metadata.parse(
        testOn: testOn,
        timeout: timeout,
        skip: skip,
        onPlatform: onPlatform,
        tags: tags,
        retry: _noRetry ? 0 : retry);
    newMetadata.validatePlatformSelectors(_platformVariables);
    var metadata = _metadata.merge(newMetadata);
    var trace = _collectTraces ? Trace.current(2) : null;

    var declarer = Declarer._(
        this,
        fullTestPrefix,
        metadata,
        _platformVariables,
        _collectTraces,
        trace,
        _noRetry,
        _fullTestName,
        _seenNames);
    declarer.declare(() {
      // Cast to dynamic to avoid the analyzer complaining about us using the
      // result of a void method.
      var result = (body as dynamic)();
      if (result is! Future) return;
      throw ArgumentError('Groups may not be async.');
    });
    _addEntry(declarer.build());

    if (solo || declarer._solo) {
      _soloEntries.add(_entries.last);
    }
  }

  /// Returns [name] prefixed with this declarer's group name.
  String _prefix(String name) => _name == null ? name : '$_name $name';

  /// Registers a function to be run before each test in this group.
  void setUp(dynamic Function() callback) {
    _checkNotBuilt('setUp');
    _setUps.add(callback);
  }

  /// Registers a function to be run after each test in this group.
  void tearDown(dynamic Function() callback) {
    _checkNotBuilt('tearDown');
    _tearDowns.add(callback);
  }

  /// Registers a function to be run once before all tests.
  void setUpAll(dynamic Function() callback) {
    _checkNotBuilt('setUpAll');
    if (_collectTraces) _setUpAllTrace ??= Trace.current(2);
    _setUpAlls.add(callback);
  }

  /// Registers a function to be run once after all tests.
  void tearDownAll(dynamic Function() callback) {
    _checkNotBuilt('tearDownAll');
    if (_collectTraces) _tearDownAllTrace ??= Trace.current(2);
    _tearDownAlls.add(callback);
  }

  /// Like [tearDownAll], but called from within a running [setUpAll] test to
  /// dynamically add a [tearDownAll].
  void addTearDownAll(dynamic Function() callback) =>
      _tearDownAlls.add(callback);

  /// Finalizes and returns the group being declared.
  ///
  /// **Note**: The tests in this group must be run in a [Invoker.guard]
  /// context; otherwise, test errors won't be captured.
  Group build() {
    _checkNotBuilt('build');

    _built = true;
    var entries = _entries.map((entry) {
      if (_solo && !_soloEntries.contains(entry)) {
        entry = LocalTest(
            entry.name,
            entry.metadata
                .change(skip: true, skipReason: 'does not have "solo"'),
            () {});
      }
      return entry;
    }).toList();

    return Group(_name ?? '', entries,
        metadata: _metadata,
        trace: _trace,
        setUpAll: _setUpAll,
        tearDownAll: _tearDownAll);
  }

  /// Throws a [StateError] if [build] has been called.
  ///
  /// [name] should be the name of the method being called.
  void _checkNotBuilt(String name) {
    if (!_built) return;
    throw StateError("Can't call $name() once tests have begun running.");
  }

  /// Run the set-up functions for this and any parent groups.
  ///
  /// If no set-up functions are declared, this returns a [Future] that
  /// completes immediately.
  Future _runSetUps() async {
    if (_parent != null) await _parent!._runSetUps();
    // TODO: why does type inference not work here?
    await Future.forEach<Function>(_setUps, (setUp) => setUp());
  }

  /// Returns a [Test] that runs the callbacks in [_setUpAll], or `null`.
  Test? get _setUpAll {
    if (_setUpAlls.isEmpty) return null;

    return LocalTest(_prefix('(setUpAll)'), _metadata.change(timeout: _timeout),
        () {
      return runZoned(
          () => Future.forEach<Function>(_setUpAlls, (setUp) => setUp()),
          // Make the declarer visible to running scaffolds so they can add to
          // the declarer's `tearDownAll()` list.
          zoneValues: {#test.declarer: this});
    }, trace: _setUpAllTrace, guarded: false, isScaffoldAll: true);
  }

  /// Returns a [Test] that runs the callbacks in [_tearDownAll], or `null`.
  Test? get _tearDownAll {
    // We have to create a tearDownAll if there's a setUpAll, since it might
    // dynamically add tear-down code using [addTearDownAll].
    if (_setUpAlls.isEmpty && _tearDownAlls.isEmpty) return null;

    return LocalTest(
        _prefix('(tearDownAll)'), _metadata.change(timeout: _timeout), () {
      return runZoned(() => Invoker.current!.runTearDowns(_tearDownAlls),
          // Make the declarer visible to running scaffolds so they can add to
          // the declarer's `tearDownAll()` list.
          zoneValues: {#test.declarer: this});
    }, trace: _tearDownAllTrace, guarded: false, isScaffoldAll: true);
  }

  void _addEntry(GroupEntry entry) {
    if (_seenNames?.add(entry.name) == false) {
      throw DuplicateTestNameException(entry.name);
    }
    _entries.add(entry);
  }
}

/// An exception thrown when two test cases in the same test suite (same `main`)
/// have an identical name.
class DuplicateTestNameException implements Exception {
  final String name;
  DuplicateTestNameException(this.name);

  @override
  String toString() => 'A test with the name "$name" was already declared. '
      'Test cases must have unique names.\n\n'
      'See https://github.com/dart-lang/test/blob/master/pkgs/test/doc/'
      'configuration.md#allow_test_randomization for info on enabling this.';
}
