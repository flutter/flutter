// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Deprecated('package:test_core is not intended for general use. '
    'Please use package:test.')
library test_core.scaffolding;

import 'dart:async';

import 'package:meta/meta.dart' show isTest, isTestGroup;
import 'package:path/path.dart' as p;
import 'package:test_api/backend.dart'; //ignore: deprecated_member_use
import 'package:test_api/scaffolding.dart' show Timeout, pumpEventQueue;
import 'package:test_api/src/backend/declarer.dart'; // ignore: implementation_imports
import 'package:test_api/src/backend/invoker.dart'; // ignore: implementation_imports

import 'src/runner/engine.dart';
import 'src/runner/plugin/environment.dart';
import 'src/runner/reporter/expanded.dart';
import 'src/runner/runner_suite.dart';
import 'src/runner/suite.dart';
import 'src/util/async.dart';
import 'src/util/os.dart';
import 'src/util/print_sink.dart';

// Hide implementations which don't support being run directly.
// This file is an almost direct copy of import below, but with the global
// declarer added.
export 'package:test_api/scaffolding.dart'
    hide test, group, setUp, setUpAll, tearDown, tearDownAll;

/// The global declarer.
///
/// This is used if a test file is run directly, rather than through the runner.
Declarer? _globalDeclarer;

/// Gets the declarer for the current scope.
///
/// When using the runner, this returns the [Zone]-scoped declarer that's set by
/// [RemoteListener]. If the test file is run directly, this returns
/// [_globalDeclarer] (and sets it up on the first call).
Declarer get _declarer {
  var declarer = Declarer.current;
  if (declarer != null) return declarer;
  if (_globalDeclarer != null) return _globalDeclarer!;

  // Since there's no Zone-scoped declarer, the test file is being run directly.
  // In order to run the tests, we set up our own Declarer via
  // [_globalDeclarer], and pump the event queue as a best effort to wait for
  // all tests to be defined before starting them.
  _globalDeclarer = Declarer();

  () async {
    await pumpEventQueue();

    var suite = RunnerSuite(const PluginEnvironment(), SuiteConfiguration.empty,
        _globalDeclarer!.build(), SuitePlatform(Runtime.vm, os: currentOSGuess),
        path: p.prettyUri(Uri.base));

    var engine = Engine();
    engine.suiteSink.add(suite);
    engine.suiteSink.close();
    ExpandedReporter.watch(engine, PrintSink(),
        color: true, printPath: false, printPlatform: false);

    var success = await runZoned(() => Invoker.guard(engine.run),
        zoneValues: {#test.declarer: _globalDeclarer});
    if (success == true) return null;
    print('');
    unawaited(Future.error('Dummy exception to set exit code.'));
  }();

  return _globalDeclarer!;
}

// TODO(nweiz): This and other top-level functions should throw exceptions if
// they're called after the declarer has finished declaring.
/// Creates a new test case with the given description (converted to a string)
/// and body.
///
/// The description will be added to the descriptions of any surrounding
/// [group]s. If [testOn] is passed, it's parsed as a [platform selector][]; the
/// test will only be run on matching platforms.
///
/// [platform selector]: https://github.com/dart-lang/test/tree/master/pkgs/test#platform-selectors
///
/// If [timeout] is passed, it's used to modify or replace the default timeout
/// of 30 seconds. Timeout modifications take precedence in suite-group-test
/// order, so [timeout] will also modify any timeouts set on the group or suite.
///
/// If [skip] is a String or `true`, the test is skipped. If it's a String, it
/// should explain why the test is skipped; this reason will be printed instead
/// of running the test.
///
/// If [tags] is passed, it declares user-defined tags that are applied to the
/// test. These tags can be used to select or skip the test on the command line,
/// or to do bulk test configuration. All tags should be declared in the
/// [package configuration file][configuring tags]. The parameter can be an
/// [Iterable] of tag names, or a [String] representing a single tag.
///
/// If [retry] is passed, the test will be retried the provided number of times
/// before being marked as a failure.
///
/// [configuring tags]: https://github.com/dart-lang/test/blob/master/pkgs/test/doc/configuration.md#configuring-tags
///
/// [onPlatform] allows tests to be configured on a platform-by-platform
/// basis. It's a map from strings that are parsed as [PlatformSelector]s to
/// annotation classes: [Timeout], [Skip], or lists of those. These
/// annotations apply only on the given platforms. For example:
///
///     test('potentially slow test', () {
///       // ...
///     }, onPlatform: {
///       // This test is especially slow on Windows.
///       'windows': Timeout.factor(2),
///       'browser': [
///         Skip('TODO: add browser support'),
///         // This will be slow on browsers once it works on them.
///         Timeout.factor(2)
///       ]
///     });
///
/// If multiple platforms match, the annotations apply in order as through
/// they were in nested groups.
///
/// If the `solo` flag is `true`, only tests and groups marked as
/// "solo" will be be run. This only restricts tests *within this test
/// suite*—tests in other suites will run as normal. We recommend that users
/// avoid this flag if possible and instead use the test runner flag `-n` to
/// filter tests by name.
@isTest
void test(description, dynamic Function() body,
    {String? testOn,
    Timeout? timeout,
    skip,
    tags,
    Map<String, dynamic>? onPlatform,
    int? retry,
    @Deprecated('Debug only') bool solo = false}) {
  _declarer.test(description.toString(), body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      onPlatform: onPlatform,
      tags: tags,
      retry: retry,
      solo: solo);

  // Force dart2js not to inline this function. We need it to be separate from
  // `main()` in JS stack traces in order to properly determine the line and
  // column where the test was defined. See sdk#26705.
  return;
  return; // ignore: dead_code
}

/// Creates a group of tests.
///
/// A group's description (converted to a string) is included in the descriptions
/// of any tests or sub-groups it contains. [setUp] and [tearDown] are also scoped
/// to the containing group.
///
/// If [testOn] is passed, it's parsed as a [platform selector][]; the test will
/// only be run on matching platforms.
///
/// [platform selector]: https://github.com/dart-lang/test/tree/master/pkgs/test#platform-selectors
///
/// If [timeout] is passed, it's used to modify or replace the default timeout
/// of 30 seconds. Timeout modifications take precedence in suite-group-test
/// order, so [timeout] will also modify any timeouts set on the suite, and will
/// be modified by any timeouts set on individual tests.
///
/// If [skip] is a String or `true`, the group is skipped. If it's a String, it
/// should explain why the group is skipped; this reason will be printed instead
/// of running the group's tests.
///
/// If [tags] is passed, it declares user-defined tags that are applied to the
/// test. These tags can be used to select or skip the test on the command line,
/// or to do bulk test configuration. All tags should be declared in the
/// [package configuration file][configuring tags]. The parameter can be an
/// [Iterable] of tag names, or a [String] representing a single tag.
///
/// [configuring tags]: https://github.com/dart-lang/test/blob/master/pkgs/test/doc/configuration.md#configuring-tags
///
/// [onPlatform] allows groups to be configured on a platform-by-platform
/// basis. It's a map from strings that are parsed as [PlatformSelector]s to
/// annotation classes: [Timeout], [Skip], or lists of those. These
/// annotations apply only on the given platforms. For example:
///
///     group('potentially slow tests', () {
///       // ...
///     }, onPlatform: {
///       // These tests are especially slow on Windows.
///       'windows': Timeout.factor(2),
///       'browser': [
///         Skip('TODO: add browser support'),
///         // They'll be slow on browsers once it works on them.
///         Timeout.factor(2)
///       ]
///     });
///
/// If multiple platforms match, the annotations apply in order as through
/// they were in nested groups.
///
/// If the `solo` flag is `true`, only tests and groups marked as
/// "solo" will be be run. This only restricts tests *within this test
/// suite*—tests in other suites will run as normal. We recommend that users
/// avoid this flag if possible, and instead use the test runner flag `-n` to
/// filter tests by name.
@isTestGroup
void group(description, dynamic Function() body,
    {String? testOn,
    Timeout? timeout,
    skip,
    tags,
    Map<String, dynamic>? onPlatform,
    int? retry,
    @Deprecated('Debug only') bool solo = false}) {
  _declarer.group(description.toString(), body,
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      tags: tags,
      onPlatform: onPlatform,
      retry: retry,
      solo: solo);

  // Force dart2js not to inline this function. We need it to be separate from
  // `main()` in JS stack traces in order to properly determine the line and
  // column where the test was defined. See sdk#26705.
  return;
  return; // ignore: dead_code
}

/// Registers a function to be run before tests.
///
/// This function will be called before each test is run. [callback] may be
/// asynchronous; if so, it must return a [Future].
///
/// If this is called within a test group, it applies only to tests in that
/// group. [callback] will be run after any set-up callbacks in parent groups or
/// at the top level.
///
/// Each callback at the top level or in a given group will be run in the order
/// they were declared.
void setUp(dynamic Function() callback) => _declarer.setUp(callback);

/// Registers a function to be run after tests.
///
/// This function will be called after each test is run. [callback] may be
/// asynchronous; if so, it must return a [Future].
///
/// If this is called within a test group, it applies only to tests in that
/// group. [callback] will be run before any tear-down callbacks in parent
/// groups or at the top level.
///
/// Each callback at the top level or in a given group will be run in the
/// reverse of the order they were declared.
///
/// See also [addTearDown], which adds tear-downs to a running test.
void tearDown(dynamic Function() callback) => _declarer.tearDown(callback);

/// Registers a function to be run once before all tests.
///
/// [callback] may be asynchronous; if so, it must return a [Future].
///
/// If this is called within a test group, [callback] will run before all tests
/// in that group. It will be run after any [setUpAll] callbacks in parent
/// groups or at the top level. It won't be run if none of the tests in the
/// group are run.
///
/// **Note**: This function makes it very easy to accidentally introduce hidden
/// dependencies between tests that should be isolated. In general, you should
/// prefer [setUp], and only use [setUpAll] if the callback is prohibitively
/// slow.
void setUpAll(dynamic Function() callback) => _declarer.setUpAll(callback);

/// Registers a function to be run once after all tests.
///
/// If this is called within a test group, [callback] will run after all tests
/// in that group. It will be run before any [tearDownAll] callbacks in parent
/// groups or at the top level. It won't be run if none of the tests in the
/// group are run.
///
/// **Note**: This function makes it very easy to accidentally introduce hidden
/// dependencies between tests that should be isolated. In general, you should
/// prefer [tearDown], and only use [tearDownAll] if the callback is
/// prohibitively slow.
void tearDownAll(dynamic Function() callback) =>
    _declarer.tearDownAll(callback);
