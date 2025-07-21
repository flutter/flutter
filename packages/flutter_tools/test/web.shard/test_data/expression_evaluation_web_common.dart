// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/web/web_device.dart' show GoogleChromeDevice;
import 'package:vm_service/vm_service.dart';

import '../../integration.shard/test_data/basic_project.dart';
import '../../integration.shard/test_data/tests_project.dart';
import '../../integration.shard/test_driver.dart';
import '../../integration.shard/test_utils.dart';
import '../../src/common.dart';

// Created here as multiple groups use it.
final stackTraceCurrentRegexp = RegExp(r'\.dart\s+[0-9]+:[0-9]+\s+get current');

Future<void> testAll({required bool useDDCLibraryBundleFormat}) async {
  group('Flutter run for web, DDC library bundle format: $useDDCLibraryBundleFormat', () {
    final project = BasicProject();
    late Directory tempDir;
    late FlutterRunTestDriver flutter;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync('run_expression_eval_test.');
      await project.setUpIn(tempDir);
      flutter = FlutterRunTestDriver(tempDir);
      flutter.stdout.listen((String line) {
        expect(line, isNot(contains('Unresolved uri:')));
        expect(line, isNot(contains('No module for')));
      });
    });

    tearDown(() async {
      await flutter.stop();
      tryToDelete(tempDir);
    });

    Future<void> start({required bool expressionEvaluation}) async {
      // The non-test project has a loop around its breakpoints.
      // No need to start paused as all breakpoint would be eventually reached.
      await flutter.run(
        withDebugger: true,
        device: GoogleChromeDevice.kChromeDeviceId,
        expressionEvaluation: expressionEvaluation,
        additionalCommandArgs: <String>[
          '--verbose',
          '--no-web-resources-cdn',
          if (useDDCLibraryBundleFormat)
            '--web-experimental-hot-reload'
          else
            '--no-web-experimental-hot-reload',
        ],
      );
    }

    Future<void> breakInBuildMethod(FlutterTestDriver flutter) async {
      await flutter.breakAt(project.buildMethodBreakpointUri, project.buildMethodBreakpointLine);
    }

    Future<void> breakInTopLevelFunction(FlutterTestDriver flutter) async {
      await flutter.breakAt(
        project.topLevelFunctionBreakpointUri,
        project.topLevelFunctionBreakpointLine,
      );
    }

    testWithoutContext('cannot evaluate expression if feature is disabled', () async {
      await start(expressionEvaluation: false);
      await breakInTopLevelFunction(flutter);
      await failToEvaluateExpression(flutter);
    });

    testWithoutContext('can evaluate expressions in library, top level and build method', () async {
      await start(expressionEvaluation: true);

      await evaluateTrivialExpressionsInLibrary(flutter);
      await evaluateComplexExpressionsInLibrary(flutter);
      await evaluateWebLibraryBooleanFromEnvironmentInLibrary(flutter);

      await breakInTopLevelFunction(flutter);
      await checkStaticScope(flutter);
      await evaluateErrorExpressions(flutter);
      await evaluateTrivialExpressions(flutter);
      await evaluateComplexExpressions(flutter);

      // Test that the call comes from some Dart getter called `current` (the
      // location of which will be compiler-specific) and that the lines and
      // file name of the current location is correct and reports a Dart path.
      await evaluateStackTraceCurrent(flutter, (String stackTrace) {
        final Iterable<RegExpMatch> matches = stackTraceCurrentRegexp.allMatches(stackTrace);
        if (matches.length != 1) {
          return false;
        }
        int end = matches.first.end;
        end = stackTrace.indexOf('package:test/main.dart 24:5', end);
        if (end == -1) {
          return false;
        }
        end = stackTrace.indexOf('package:test/main.dart 15:7', end);
        return end != -1;
      });

      await breakInBuildMethod(flutter);
      await evaluateTrivialExpressions(flutter);
      await evaluateComplexExpressions(flutter);
    });
  });

  group('Flutter test for web, DDC library bundle format: $useDDCLibraryBundleFormat', () {
    final project = TestsProject();
    late Directory tempDir;
    late FlutterRunTestDriver flutter;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync('run_expression_eval_test.');
      await project.setUpIn(tempDir);
      flutter = FlutterRunTestDriver(tempDir);
    });

    tearDown(() async {
      await flutter.stop();
      tryToDelete(tempDir);
    });

    Future<Isolate?> breakInMethod(FlutterTestDriver flutter) async {
      await flutter.addBreakpoint(project.breakpointAppUri, project.breakpointLine);
      return flutter.resume(waitForNextPause: true);
    }

    Future<void> startPaused({required bool expressionEvaluation}) {
      // The test project does not have a loop around its breakpoints.
      // Start paused so we can set a breakpoint before passing it
      // in the execution.
      return flutter.run(
        withDebugger: true,
        device: GoogleChromeDevice.kChromeDeviceId,
        expressionEvaluation: expressionEvaluation,
        startPaused: true,
        script: project.testFilePath,
        additionalCommandArgs: <String>[
          '--verbose',
          '--no-web-resources-cdn',
          if (useDDCLibraryBundleFormat)
            '--web-experimental-hot-reload'
          else
            '--no-web-experimental-hot-reload',
        ],
      );
    }

    testWithoutContext('cannot evaluate expressions if feature is disabled', () async {
      await startPaused(expressionEvaluation: false);
      await breakInMethod(flutter);
      await failToEvaluateExpression(flutter);
    });

    testWithoutContext('can evaluate expressions in a test', () async {
      await startPaused(expressionEvaluation: true);

      await evaluateTrivialExpressionsInLibrary(flutter);
      await evaluateComplexExpressionsInLibrary(flutter);
      await evaluateWebLibraryBooleanFromEnvironmentInLibrary(flutter);

      await breakInMethod(flutter);
      await evaluateTrivialExpressions(flutter);
      await evaluateComplexExpressions(flutter);

      await evaluateStackTraceCurrent(flutter, (String stackTrace) {
        final Iterable<RegExpMatch> matches = stackTraceCurrentRegexp.allMatches(stackTrace);
        if (matches.length != 1) {
          return false;
        }
        int end = matches.first.end;
        end = stackTrace.indexOf('test.dart 6:9', end);
        return end != -1;
      });
    });
  });
}

Future<void> failToEvaluateExpression(FlutterTestDriver flutter) async {
  await expectLater(
    flutter.evaluateInFrame('"test"'),
    throwsA(
      isA<RPCError>().having(
        (RPCError error) => error.message,
        'message',
        contains('Expression evaluation is not supported for this configuration'),
      ),
    ),
  );
}

Future<void> checkStaticScope(FlutterTestDriver flutter) async {
  final Frame res = await flutter.getTopStackFrame();
  expect(res.vars, equals(<BoundVariable>[]));
}

Future<void> evaluateErrorExpressions(FlutterTestDriver flutter) async {
  final ObjRef res = await flutter.evaluateInFrame('typo');
  expectError(res, 'CompilationError:');
}

Future<void> evaluateTrivialExpressions(FlutterTestDriver flutter) async {
  ObjRef res;

  res = await flutter.evaluateInFrame('"test"');
  expectInstance(res, InstanceKind.kString, 'test');

  res = await flutter.evaluateInFrame('1');
  expectInstance(res, InstanceKind.kDouble, 1.toString());

  res = await flutter.evaluateInFrame('true');
  expectInstance(res, InstanceKind.kBool, true.toString());
}

Future<void> evaluateComplexExpressions(FlutterTestDriver flutter) async {
  final ObjRef res = await flutter.evaluateInFrame('new DateTime.now().year');
  expectInstance(res, InstanceKind.kDouble, DateTime.now().year.toString());
}

Future<void> evaluateTrivialExpressionsInLibrary(FlutterTestDriver flutter) async {
  final LibraryRef library = await getRootLibrary(flutter);
  final ObjRef res = await flutter.evaluate(library.id!, '"test"');
  expectInstance(res, InstanceKind.kString, 'test');
}

Future<void> evaluateComplexExpressionsInLibrary(FlutterTestDriver flutter) async {
  final LibraryRef library = await getRootLibrary(flutter);
  final ObjRef res = await flutter.evaluate(library.id!, 'new DateTime.now().year');
  expectInstance(res, InstanceKind.kDouble, DateTime.now().year.toString());
}

Future<void> evaluateWebLibraryBooleanFromEnvironmentInLibrary(FlutterTestDriver flutter) async {
  final LibraryRef library = await getRootLibrary(flutter);
  final ObjRef res = await flutter.evaluate(
    library.id!,
    'const bool.fromEnvironment("dart.library.html")',
  );
  expectInstance(res, InstanceKind.kBool, true.toString());
}

Future<void> evaluateStackTraceCurrent(
  FlutterTestDriver flutter,
  bool Function(String) matchStackTraces,
) async {
  final LibraryRef library = await getRootLibrary(flutter);
  final ObjRef res = await flutter.evaluate(library.id!, 'StackTrace.current.toString()');
  expectInstance(res, InstanceKind.kString, predicate(matchStackTraces));
}

Future<LibraryRef> getRootLibrary(FlutterTestDriver flutter) async {
  // `isolate.rootLib` returns incorrect library, so find the
  // entrypoint manually here instead.
  //
  // Issue: https://github.com/dart-lang/sdk/issues/44760
  final Isolate isolate = await flutter.getFlutterIsolate();
  return isolate.libraries!.firstWhere((LibraryRef l) => l.uri!.contains('org-dartlang-app'));
}

void expectInstance(ObjRef result, String kind, Object matcher) {
  expect(
    result,
    const TypeMatcher<InstanceRef>()
        .having((InstanceRef instance) => instance.kind, 'kind', kind)
        .having((InstanceRef instance) => instance.valueAsString, 'valueAsString', matcher),
  );
}

void expectError(ObjRef result, String message) {
  expect(
    result,
    const TypeMatcher<ErrorRef>().having(
      (ErrorRef instance) => instance.message,
      'message',
      contains(message),
    ),
  );
}
