// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:boolean_selector/boolean_selector.dart';
import 'package:glob/glob.dart';
import 'package:test/test.dart';
import 'package:test_api/src/backend/declarer.dart';
import 'package:test_api/src/backend/group.dart';
import 'package:test_api/src/backend/group_entry.dart';
import 'package:test_api/src/backend/invoker.dart';
import 'package:test_api/src/backend/live_test.dart';
import 'package:test_api/src/backend/metadata.dart';
import 'package:test_api/src/backend/platform_selector.dart';
import 'package:test_api/src/backend/runtime.dart';
import 'package:test_api/src/backend/state.dart';
import 'package:test_api/src/backend/suite.dart';
import 'package:test_api/src/backend/suite_platform.dart';
import 'package:test_core/src/runner/application_exception.dart';
import 'package:test_core/src/runner/configuration.dart';
import 'package:test_core/src/runner/configuration/custom_runtime.dart';
import 'package:test_core/src/runner/configuration/runtime_settings.dart';
import 'package:test_core/src/runner/engine.dart';
import 'package:test_core/src/runner/load_suite.dart';
import 'package:test_core/src/runner/plugin/environment.dart';
import 'package:test_core/src/runner/runner_suite.dart';
import 'package:test_core/src/runner/runtime_selection.dart';
import 'package:test_core/src/runner/suite.dart';

/// A dummy suite platform to use for testing suites.
final suitePlatform = SuitePlatform(Runtime.vm);

// The last state change detected via [expectStates].
State? lastState;

/// Asserts that exactly [states] will be emitted via [liveTest.onStateChange].
///
/// The most recent emitted state is stored in [_lastState].
void expectStates(LiveTest liveTest, Iterable<State> statesIter) {
  var states = Queue.from(statesIter);
  liveTest.onStateChange.listen(expectAsync1((state) {
    lastState = state;
    expect(state, equals(states.removeFirst()));
  }, count: states.length, max: states.length));
}

/// Asserts that errors will be emitted via [liveTest.onError] that match
/// [validators], in order.
void expectErrors(LiveTest liveTest, Iterable<Function> validatorsIter) {
  var validators = Queue.from(validatorsIter);
  liveTest.onError.listen(expectAsync1((error) {
    validators.removeFirst()(error.error);
  }, count: validators.length, max: validators.length));
}

/// Asserts that [liveTest] will have a single failure with message `"oh no"`.
void expectSingleFailure(LiveTest liveTest) {
  expectStates(liveTest, [
    const State(Status.running, Result.success),
    const State(Status.complete, Result.failure)
  ]);

  expectErrors(liveTest, [
    (error) {
      expect(lastState!.status, equals(Status.complete));
      expect(error, isTestFailure('oh no'));
    }
  ]);
}

/// Asserts that [liveTest] will have a single error, the string `"oh no"`.
void expectSingleError(LiveTest liveTest) {
  expectStates(liveTest, [
    const State(Status.running, Result.success),
    const State(Status.complete, Result.error)
  ]);

  expectErrors(liveTest, [
    (error) {
      expect(lastState!.status, equals(Status.complete));
      expect(error, equals('oh no'));
    }
  ]);
}

/// Returns a matcher that matches a callback or Future that throws a
/// [TestFailure] with the given [message].
///
/// [message] can be a string or a [Matcher].
Matcher throwsTestFailure(message) => throwsA(isTestFailure(message));

/// Returns a matcher that matches a [TestFailure] with the given [message].
///
/// [message] can be a string or a [Matcher].
Matcher isTestFailure(message) => const TypeMatcher<TestFailure>()
    .having((e) => e.message, 'message', message);

/// Returns a matcher that matches a [ApplicationException] with the given
/// [message].
///
/// [message] can be a string or a [Matcher].
Matcher isApplicationException(message) =>
    const TypeMatcher<ApplicationException>()
        .having((e) => e.message, 'message', message);

/// Returns a local [LiveTest] that runs [body].
LiveTest createTest(dynamic Function() body) {
  var test = LocalTest('test', Metadata(chainStackTraces: true), body);
  var suite = Suite(Group.root([test]), suitePlatform, ignoreTimeouts: false);
  return test.load(suite);
}

/// Runs [body] as a test.
///
/// Once it completes, returns the [LiveTest] used to run it.
Future<LiveTest> runTestBody(dynamic Function() body) async {
  var liveTest = createTest(body);
  await liveTest.run();
  return liveTest;
}

/// Asserts that [liveTest] has completed and passed.
///
/// If the test had any errors, they're surfaced nicely into the outer test.
void expectTestPassed(LiveTest liveTest) {
  // Since the test is expected to pass, we forward any current or future errors
  // to the outer test, because they're definitely unexpected.
  for (var error in liveTest.errors) {
    registerException(error.error, error.stackTrace);
  }
  liveTest.onError.listen((error) {
    registerException(error.error, error.stackTrace);
  });

  expect(liveTest.state.status, equals(Status.complete));
  expect(liveTest.state.result, equals(Result.success));
}

/// Asserts that [liveTest] failed with a single [TestFailure] whose message
/// matches [message].
void expectTestFailed(LiveTest liveTest, message) {
  expect(liveTest.state.status, equals(Status.complete));
  expect(liveTest.state.result, equals(Result.failure));
  expect(liveTest.errors, hasLength(1));
  expect(liveTest.errors.first.error, isTestFailure(message));
}

/// Assert that the [test] callback causes a test to block until [stopBlocking]
/// is called at some later time.
///
/// [stopBlocking] is passed the return value of [test].
Future<void> expectTestBlocks(
    dynamic Function() test, dynamic Function(dynamic) stopBlocking) async {
  late LiveTest liveTest;
  late Future<void> future;
  liveTest = createTest(() {
    var value = test();
    future = pumpEventQueue().then((_) {
      expect(liveTest.state.status, equals(Status.running));
      stopBlocking(value);
    });
  });

  await liveTest.run();
  expectTestPassed(liveTest);
  // Ensure that the outer test doesn't complete until the inner future
  // completes.
  return future;
}

/// Runs [body] with a declarer, runs all the declared tests, and asserts that
/// they pass.
///
/// This is typically used to run multiple tests where later tests make
/// assertions about the results of previous ones.
Future<void> expectTestsPass(void Function() body) async {
  var engine = declareEngine(body);
  var success = await engine.run();

  for (var test in engine.liveTests) {
    expectTestPassed(test);
  }

  expect(success, isTrue);
}

/// Runs [body] with a declarer and returns the declared entries.
List<GroupEntry> declare(void Function() body) {
  var declarer = Declarer()..declare(body);
  return declarer.build().entries;
}

/// Runs [body] with a declarer and returns an engine that runs those tests.
Engine declareEngine(void Function() body,
    {bool runSkipped = false, String? coverage}) {
  var declarer = Declarer()..declare(body);
  return Engine.withSuites([
    RunnerSuite(
        const PluginEnvironment(),
        SuiteConfiguration.runSkipped(runSkipped),
        declarer.build(),
        suitePlatform)
  ], coverage: coverage);
}

/// Returns a [RunnerSuite] with a default environment and configuration.
RunnerSuite runnerSuite(Group root) => RunnerSuite(
    const PluginEnvironment(), SuiteConfiguration.empty, root, suitePlatform);

/// Returns a [LoadSuite] with a default configuration.
LoadSuite loadSuite(String name, FutureOr<RunnerSuite> Function() body) =>
    LoadSuite(name, SuiteConfiguration.empty, suitePlatform, body);

SuiteConfiguration suiteConfiguration(
        {bool? allowDuplicateTestNames,
        bool? allowTestRandomization,
        bool? jsTrace,
        bool? runSkipped,
        Iterable<String>? dart2jsArgs,
        String? precompiledPath,
        Iterable<Pattern>? patterns,
        Iterable<RuntimeSelection>? runtimes,
        BooleanSelector? includeTags,
        BooleanSelector? excludeTags,
        Map<BooleanSelector, SuiteConfiguration>? tags,
        Map<PlatformSelector, SuiteConfiguration>? onPlatform,
        int? line,
        int? col,
        bool? ignoreTimeouts,

        // Test-level configuration
        Timeout? timeout,
        bool? verboseTrace,
        bool? chainStackTraces,
        bool? skip,
        int? retry,
        String? skipReason,
        PlatformSelector? testOn,
        Iterable<String>? addTags}) =>
    SuiteConfiguration(
        allowDuplicateTestNames: allowDuplicateTestNames,
        allowTestRandomization: allowTestRandomization,
        jsTrace: jsTrace,
        runSkipped: runSkipped,
        dart2jsArgs: dart2jsArgs,
        precompiledPath: precompiledPath,
        patterns: patterns,
        runtimes: runtimes,
        includeTags: includeTags,
        excludeTags: excludeTags,
        tags: tags,
        onPlatform: onPlatform,
        line: line,
        col: col,
        ignoreTimeouts: ignoreTimeouts,
        timeout: timeout,
        verboseTrace: verboseTrace,
        chainStackTraces: chainStackTraces,
        skip: skip,
        retry: retry,
        skipReason: skipReason,
        testOn: testOn,
        addTags: addTags);

Configuration configuration(
        {bool? help,
        String? customHtmlTemplatePath,
        bool? version,
        bool? pauseAfterLoad,
        bool? debug,
        bool? color,
        String? configurationPath,
        String? reporter,
        Map<String, String>? fileReporters,
        String? coverage,
        int? pubServePort,
        int? concurrency,
        int? shardIndex,
        int? totalShards,
        Iterable<PathConfiguration>? paths,
        Iterable<String>? foldTraceExcept,
        Iterable<String>? foldTraceOnly,
        Glob? filename,
        Iterable<String>? chosenPresets,
        Map<String, Configuration>? presets,
        Map<String, RuntimeSettings>? overrideRuntimes,
        Map<String, CustomRuntime>? defineRuntimes,
        bool? noRetry,
        bool? useDataIsolateStrategy,
        bool? ignoreTimeouts,

        // Suite-level configuration
        bool? allowDuplicateTestNames,
        bool? allowTestRandomization,
        bool? jsTrace,
        bool? runSkipped,
        Iterable<String>? dart2jsArgs,
        String? precompiledPath,
        Iterable<Pattern>? patterns,
        Iterable<RuntimeSelection>? runtimes,
        BooleanSelector? includeTags,
        BooleanSelector? excludeTags,
        Map<BooleanSelector, SuiteConfiguration>? tags,
        Map<PlatformSelector, SuiteConfiguration>? onPlatform,
        int? testRandomizeOrderingSeed,

        // Test-level configuration
        Timeout? timeout,
        bool? verboseTrace,
        bool? chainStackTraces,
        bool? skip,
        int? retry,
        String? skipReason,
        PlatformSelector? testOn,
        Iterable<String>? addTags}) =>
    Configuration(
        help: help,
        customHtmlTemplatePath: customHtmlTemplatePath,
        version: version,
        pauseAfterLoad: pauseAfterLoad,
        debug: debug,
        color: color,
        configurationPath: configurationPath,
        reporter: reporter,
        fileReporters: fileReporters,
        coverage: coverage,
        pubServePort: pubServePort,
        concurrency: concurrency,
        shardIndex: shardIndex,
        totalShards: totalShards,
        paths: paths,
        foldTraceExcept: foldTraceExcept,
        foldTraceOnly: foldTraceOnly,
        filename: filename,
        chosenPresets: chosenPresets,
        presets: presets,
        overrideRuntimes: overrideRuntimes,
        defineRuntimes: defineRuntimes,
        noRetry: noRetry,
        useDataIsolateStrategy: useDataIsolateStrategy,
        ignoreTimeouts: ignoreTimeouts,
        allowDuplicateTestNames: allowDuplicateTestNames,
        allowTestRandomization: allowTestRandomization,
        jsTrace: jsTrace,
        runSkipped: runSkipped,
        dart2jsArgs: dart2jsArgs,
        precompiledPath: precompiledPath,
        patterns: patterns,
        runtimes: runtimes,
        includeTags: includeTags,
        excludeTags: excludeTags,
        tags: tags,
        onPlatform: onPlatform,
        testRandomizeOrderingSeed: testRandomizeOrderingSeed,
        timeout: timeout,
        verboseTrace: verboseTrace,
        chainStackTraces: chainStackTraces,
        skip: skip,
        retry: retry,
        skipReason: skipReason,
        testOn: testOn,
        addTags: addTags);
