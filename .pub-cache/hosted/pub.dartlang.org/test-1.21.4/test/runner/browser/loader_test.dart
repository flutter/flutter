// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Tags(['chrome'])
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/src/runner/browser/platform.dart';
import 'package:test/test.dart';
import 'package:test_api/src/backend/runtime.dart';
import 'package:test_api/src/backend/state.dart';
import 'package:test_api/src/backend/test.dart';
import 'package:test_core/src/runner/hack_register_platform.dart';
import 'package:test_core/src/runner/loader.dart';
import 'package:test_core/src/runner/runner_suite.dart';
import 'package:test_core/src/runner/runner_test.dart';
import 'package:test_core/src/runner/runtime_selection.dart';
import 'package:test_core/src/runner/suite.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../../utils.dart';

late Loader _loader;

/// A configuration that loads suites on Chrome.
final _chrome =
    SuiteConfiguration.runtimes([RuntimeSelection(Runtime.chrome.identifier)]);

void main() {
  setUp(() async {
    // The default loader doesn't have the platforms registered.
    registerPlatformPlugin([
      Runtime.chrome,
    ], () => BrowserPlatform.start(root: d.sandbox));

    _loader = Loader();

    await d.file('a_test.dart', '''
      import 'dart:async';

      import 'package:test/test.dart';

      void main() {
        test("success", () {});
        test("failure", () => throw TestFailure('oh no'));
        test("error", () => throw 'oh no');
      }
    ''').create();
  });

  tearDown(() => _loader.close());

  group('.loadFile()', () {
    late RunnerSuite suite;
    setUp(() async {
      var suites = await _loader
          .loadFile(p.join(d.sandbox, 'a_test.dart'), _chrome)
          .toList();

      expect(suites, hasLength(1));
      var loadSuite = suites.first;
      suite = (await loadSuite.getSuite())!;
    });

    test('returns a suite with the file path and platform', () {
      expect(suite.path, equals(p.join(d.sandbox, 'a_test.dart')));
      expect(suite.platform.runtime, equals(Runtime.chrome));
    });

    test('returns tests with the correct names', () {
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

  test('loads tests that are defined asynchronously', () async {
    File(p.join(d.sandbox, 'a_test.dart')).writeAsStringSync('''
import 'dart:async';

import 'package:test/test.dart';

Future main() {
  return Future(() {
    test("success", () {});

    return Future(() {
      test("failure", () => throw TestFailure('oh no'));

      return Future(() {
        test("error", () => throw 'oh no');
      });
    });
  });
}
''');

    var suites = await _loader
        .loadFile(p.join(d.sandbox, 'a_test.dart'), _chrome)
        .toList();
    expect(suites, hasLength(1));
    var loadSuite = suites.first;
    var suite = (await loadSuite.getSuite())!;
    expect(suite.group.entries, hasLength(3));
    expect(suite.group.entries[0].name, equals('success'));
    expect(suite.group.entries[1].name, equals('failure'));
    expect(suite.group.entries[2].name, equals('error'));
  });

  test('loads a suite both in the browser and the VM', () async {
    var path = p.join(d.sandbox, 'a_test.dart');

    var suites = await _loader
        .loadFile(
            path,
            SuiteConfiguration.runtimes([
              RuntimeSelection(Runtime.vm.identifier),
              RuntimeSelection(Runtime.chrome.identifier)
            ]))
        .asyncMap((loadSuite) => loadSuite.getSuite())
        .cast<RunnerSuite>()
        .toList();
    expect(suites[0].platform.runtime, equals(Runtime.vm));
    expect(suites[0].path, equals(path));
    expect(suites[1].platform.runtime, equals(Runtime.chrome));
    expect(suites[1].path, equals(path));

    for (var suite in suites) {
      expect(suite.group.entries, hasLength(3));
      expect(suite.group.entries[0].name, equals('success'));
      expect(suite.group.entries[1].name, equals('failure'));
      expect(suite.group.entries[2].name, equals('error'));
    }
  });

  test('a print in a loaded file is piped through the LoadSuite', () async {
    File(p.join(d.sandbox, 'a_test.dart')).writeAsStringSync('''
void main() {
  print('print within test');
}
''');
    var suites = await _loader
        .loadFile(p.join(d.sandbox, 'a_test.dart'), _chrome)
        .toList();
    expect(suites, hasLength(1));
    var loadSuite = suites.first;

    var liveTest = (loadSuite.group.entries.single as Test).load(loadSuite);
    // Skip the "Compiled" message from dart2js.
    expect(liveTest.onMessage.skip(1).first.then((message) => message.text),
        completion(equals('print within test')));
    await liveTest.run();
    expectTestPassed(liveTest);
  });
}
