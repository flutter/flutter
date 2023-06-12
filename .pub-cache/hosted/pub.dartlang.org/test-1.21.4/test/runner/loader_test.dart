// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_api/src/backend/runtime.dart';
import 'package:test_api/src/backend/state.dart';
import 'package:test_api/src/backend/test.dart';
import 'package:test_core/src/runner/loader.dart';
import 'package:test_core/src/runner/runner_suite.dart';
import 'package:test_core/src/runner/runner_test.dart';
import 'package:test_core/src/runner/suite.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../utils.dart';

late Loader _loader;

final _tests = '''
import 'dart:async';

import 'package:test/test.dart';

void main() {
  test("success", () {});
  test("failure", () => throw TestFailure('oh no'));
  test("error", () => throw 'oh no');
}
''';

void main() {
  setUp(() async {
    _loader = Loader();
  });

  tearDown(() => _loader.close());

  group('.loadFile()', () {
    late RunnerSuite suite;
    setUp(() async {
      await d.file('a_test.dart', _tests).create();
      var suites = await _loader
          .loadFile(p.join(d.sandbox, 'a_test.dart'), SuiteConfiguration.empty)
          .toList();
      expect(suites, hasLength(1));
      var loadSuite = suites.first;
      suite = (await loadSuite.getSuite())!;
    });

    test('returns a suite with the file path and platform', () {
      expect(suite.path, equals(p.join(d.sandbox, 'a_test.dart')));
      expect(suite.platform.runtime, equals(Runtime.vm));
    });

    test('returns entries with the correct names and platforms', () {
      expect(suite.group.entries, hasLength(3));
      expect(suite.group.entries[0].name, equals('success'));
      expect(suite.group.entries[1].name, equals('failure'));
      expect(suite.group.entries[2].name, equals('error'));
    });

    test('can load and run a successful test', () {
      var liveTest = (suite.group.entries[0] as RunnerTest).load(suite);

      expectStates(liveTest, [
        const State(Status.running, Result.success),
        const State(Status.complete, Result.success)
      ]);
      expectErrors(liveTest, []);

      return liveTest.run().whenComplete(() => liveTest.close());
    });

    test('can load and run a failing test', () {
      var liveTest = (suite.group.entries[1] as RunnerTest).load(suite);
      expectSingleFailure(liveTest);
      return liveTest.run().whenComplete(() => liveTest.close());
    });
  });

  group('.loadDir()', () {
    test('ignores non-Dart files', () async {
      await d.file('a_test.txt', _tests).create();
      expect(_loader.loadDir(d.sandbox, SuiteConfiguration.empty).toList(),
          completion(isEmpty));
    });

    test("ignores files that don't end in _test.dart", () async {
      await d.file('test.dart', _tests).create();
      expect(_loader.loadDir(d.sandbox, SuiteConfiguration.empty).toList(),
          completion(isEmpty));
    });

    group('with suites loaded from a directory', () {
      late List<RunnerSuite> suites;
      setUp(() async {
        await d.file('a_test.dart', _tests).create();
        await d.file('another_test.dart', _tests).create();
        await d.dir('dir', [d.file('sub_test.dart', _tests)]).create();

        suites = await _loader
            .loadDir(d.sandbox, SuiteConfiguration.empty)
            .asyncMap((loadSuite) async => (await loadSuite.getSuite())!)
            .toList();
      });

      test('gives those suites the correct paths', () {
        expect(
            suites.map((suite) => suite.path),
            unorderedEquals([
              p.join(d.sandbox, 'a_test.dart'),
              p.join(d.sandbox, 'another_test.dart'),
              p.join(d.sandbox, 'dir', 'sub_test.dart')
            ]));
      });

      test('can run tests in those suites', () {
        var suite =
            suites.firstWhere((suite) => suite.path!.contains('a_test'));
        var liveTest = (suite.group.entries[1] as RunnerTest).load(suite);
        expectSingleFailure(liveTest);
        return liveTest.run().whenComplete(() => liveTest.close());
      });
    });
  });

  test('a print in a loaded file is piped through the LoadSuite', () async {
    await d.file('a_test.dart', '''
      void main() {
        print('print within test');
      }
    ''').create();
    var suites = await _loader
        .loadFile(p.join(d.sandbox, 'a_test.dart'), SuiteConfiguration.empty)
        .toList();
    expect(suites, hasLength(1));
    var loadSuite = suites.first;

    var liveTest = (loadSuite.group.entries.single as Test).load(loadSuite);
    expect(liveTest.onMessage.first.then((message) => message.text),
        completion(equals('print within test')));
    await liveTest.run();
    expectTestPassed(liveTest);
  });

  group('LoadException', () {
    test('suites can be retried', () async {
      var numRetries = 5;

      await d.file('a_test.dart', '''
      import 'hello.dart';

      void main() {}
    ''').create();

      var firstFailureCompleter = Completer<void>();

      // After the first load failure we create the missing dependency.
      unawaited(firstFailureCompleter.future.then((_) async {
        await d.file('hello.dart', '''
      String get message => 'hello';
    ''').create();
      }));

      await runZoned(() async {
        var suites = await _loader
            .loadFile(p.join(d.sandbox, 'a_test.dart'),
                suiteConfiguration(retry: numRetries))
            .toList();
        expect(suites, hasLength(1));
        var loadSuite = suites.first;
        var suite = (await loadSuite.getSuite())!;
        expect(suite.path, equals(p.join(d.sandbox, 'a_test.dart')));
        expect(suite.platform.runtime, equals(Runtime.vm));
      }, zoneSpecification:
          ZoneSpecification(print: (_, parent, zone, message) {
        if (message.contains('Retrying load of') &&
            !firstFailureCompleter.isCompleted) {
          firstFailureCompleter.complete(null);
        }
        parent.print(zone, message);
      }));

      expect(firstFailureCompleter.isCompleted, true);
    });
  });

  // TODO: Test load suites. Don't forget to test that prints in loaded files
  // are piped through the suite. Also for browser tests!
}
