// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stack_trace/stack_trace.dart';
// ignore: deprecated_member_use
import 'package:test_api/scaffolding.dart' show Timeout;
import 'package:test_api/src/backend/group.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/invoker.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/metadata.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/runtime.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/suite.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/suite_platform.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/test.dart'; // ignore: implementation_imports

import '../util/async.dart';
import '../util/io_stub.dart' if (dart.library.io) '../util/io.dart';
import '../util/pair.dart';
import 'load_exception.dart';
import 'plugin/environment.dart';
import 'runner_suite.dart';
import 'suite.dart';

/// The timeout for loading a test suite.
///
/// We want this to be long enough that even a very large application being
/// compiled with dart2js doesn't trigger it, but short enough that it fires
/// before the host kills it. For example, Google's Forge service has a
/// 15-minute timeout.
final _timeout = Duration(minutes: 12);

/// A [Suite] emitted by a [Loader] that provides a test-like interface for
/// loading a test file.
///
/// This is used to expose the current status of test loading to the user. It's
/// important to provide users visibility into what's taking a long time and
/// where failures occur. And since some tests may be loaded at the same time as
/// others are run, it's useful to provide that visibility in the form of a test
/// suite so that it can integrate well into the existing reporting interface
/// without too much extra logic.
///
/// A suite is constructed with logic necessary to produce a test suite. As with
/// a normal test body, this logic isn't run until [LiveTest.run] is called. The
/// suite itself is returned by [suite] once it's available, but any errors or
/// prints will be emitted through the running [LiveTest].
class LoadSuite extends Suite implements RunnerSuite {
  @override
  final environment = const PluginEnvironment();
  @override
  final SuiteConfiguration config;
  @override
  final isDebugging = false;
  @override
  final onDebugging = StreamController<bool>().stream;

  @override
  bool get isLoadSuite => true;

  /// A future that completes to the loaded suite once the suite's test has been
  /// run and completed successfully.
  ///
  /// This will return `null` if the suite is unavailable for some reason (for
  /// example if an error occurred while loading it).
  Future<RunnerSuite?> get suite async => (await _suiteAndZone)?.first;

  /// A future that completes to a pair of [suite] and the load test's [Zone].
  ///
  /// This will return `null` if the suite is unavailable for some reason (for
  /// example if an error occurred while loading it).
  final Future<Pair<RunnerSuite, Zone>?> _suiteAndZone;

  /// Returns the test that loads the suite.
  ///
  /// Load suites are guaranteed to only contain one test. This is a utility
  /// method for accessing it directly.
  Test get test => group.entries.single as Test;

  /// Creates a load suite named [name] on [platform].
  ///
  /// [body] may return either a [RunnerSuite] or a [Future] that completes to a
  /// [RunnerSuite]. Its return value is forwarded through [suite], although if
  /// it throws an error that will be forwarded through the suite's test.
  ///
  /// If the the load test is closed before [body] is complete, it will close
  /// the suite returned by [body] once it completes.
  factory LoadSuite(String name, SuiteConfiguration config,
      SuitePlatform platform, FutureOr<RunnerSuite?> Function() body,
      {String? path}) {
    var completer = Completer<Pair<RunnerSuite, Zone>?>.sync();
    return LoadSuite._(name, config, platform, () {
      var invoker = Invoker.current;
      invoker!.addOutstandingCallback();

      unawaited(() async {
        var suite = await body();
        if (completer.isCompleted) {
          // If the load test has already been closed, close the suite it
          // generated.
          await suite?.close();
          return;
        }

        completer.complete(suite == null ? null : Pair(suite, Zone.current));
        invoker.removeOutstandingCallback();
      }());

      // If the test completes before the body callback, either an out-of-band
      // error occurred or the test was canceled. Either way, we return a `null`
      // suite.
      invoker.liveTest.onComplete.then((_) {
        if (!completer.isCompleted) completer.complete();
      });

      // If the test is forcibly closed, let it complete, since load tests don't
      // have timeouts.
      invoker.onClose.then((_) => invoker.removeOutstandingCallback());
    }, completer.future, path: path, ignoreTimeouts: config.ignoreTimeouts);
  }

  /// A utility constructor for a load suite that just throws [exception].
  ///
  /// The suite's name will be based on [exception]'s path.
  factory LoadSuite.forLoadException(
      LoadException exception, SuiteConfiguration? config,
      {SuitePlatform? platform, StackTrace? stackTrace}) {
    stackTrace ??= Trace.current();

    return LoadSuite(
        'loading ${exception.path}',
        config ?? SuiteConfiguration.empty,
        platform ?? currentPlatform(Runtime.vm),
        () => Future.error(exception, stackTrace),
        path: exception.path);
  }

  /// A utility constructor for a load suite that just emits [suite].
  factory LoadSuite.forSuite(RunnerSuite suite) {
    return LoadSuite(
        'loading ${suite.path}', suite.config, suite.platform, () => suite,
        path: suite.path);
  }

  LoadSuite._(String name, this.config, SuitePlatform platform,
      void Function() body, this._suiteAndZone,
      {required bool ignoreTimeouts, String? path})
      : super(
            Group.root(
                [LocalTest(name, Metadata(timeout: Timeout(_timeout)), body)]),
            platform,
            path: path,
            ignoreTimeouts: ignoreTimeouts);

  /// A constructor used by [changeSuite].
  LoadSuite._changeSuite(LoadSuite old, this._suiteAndZone)
      : config = old.config,
        super(old.group, old.platform,
            path: old.path, ignoreTimeouts: old.ignoreTimeouts);

  /// A constructor used by [filter].
  LoadSuite._filtered(LoadSuite old, Group filtered)
      : config = old.config,
        _suiteAndZone = old._suiteAndZone,
        super(old.group, old.platform,
            path: old.path, ignoreTimeouts: old.ignoreTimeouts);

  /// Creates a new [LoadSuite] that's identical to this one, but that
  /// transforms [suite] once it's loaded.
  ///
  /// If [suite] completes to `null`, [change] won't be run. [change] is run
  /// within the load test's zone, so any errors or prints it emits will be
  /// associated with that test.
  LoadSuite changeSuite(RunnerSuite? Function(RunnerSuite) change) {
    return LoadSuite._changeSuite(this, _suiteAndZone.then((pair) {
      if (pair == null) return null;

      var zone = pair.last;
      RunnerSuite? newSuite;
      zone.runGuarded(() {
        newSuite = change(pair.first);
      });
      return newSuite == null ? null : Pair(newSuite!, zone);
    }));
  }

  /// Runs the test and returns the suite.
  ///
  /// Rather than emitting errors through a [LiveTest], this just pipes them
  /// through the return value.
  Future<RunnerSuite?> getSuite() async {
    var liveTest = test.load(this);
    liveTest.onMessage.listen((message) => print(message.text));
    await liveTest.run();

    if (liveTest.errors.isEmpty) return await suite;

    var error = liveTest.errors.first;
    await Future.error(error.error, error.stackTrace);
    throw 'unreachable';
  }

  @override
  LoadSuite filter(bool Function(Test) callback) {
    var filtered = group.filter(callback);
    filtered ??= Group.root([], metadata: metadata);
    return LoadSuite._filtered(this, filtered);
  }

  @override
  Future close() async {}

  @override
  Future<Map<String, dynamic>> gatherCoverage() =>
      throw UnsupportedError('Coverage is not supported for LoadSuite tests.');
}
