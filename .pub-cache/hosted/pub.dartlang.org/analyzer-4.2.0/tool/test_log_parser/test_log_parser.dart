// @dart = 2.9
// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// A simple command-line app that reads the content of a file containing the
/// output from `test.py` and performs some simple analysis of it.
main(List<String> args) async {
  if (args.length != 1) {
    print('Usage: dart test_log_parser logFilePath');
    return;
  }
  String filePath = args[0];

  List<String> output = File(filePath).readAsLinesSync();
  int failureCount = 0;
  int index = 0;
  final int expectedPrefixLength = 'Expected: '.length;
  final int actualPrefixLength = 'Actual: '.length;
  TestResult currentResult;
  Map<String, List<TestResult>> testsByExpectedAndActual =
      <String, List<TestResult>>{};
  Map<String, List<TestResult>> testsByStackTrace =
      <String, List<TestResult>>{};
  while (index < output.length) {
    String currentLine = output[index];
    if (currentLine.startsWith('FAILED:')) {
      failureCount++;
      String testName = currentLine.substring(currentLine.lastIndexOf(' ') + 1);
      String expected = output[index + 1].substring(expectedPrefixLength);
      String actual = output[index + 2].substring(actualPrefixLength);
      String key = '$expected-$actual';
      currentResult = TestResult(testName, expected, actual);
      testsByExpectedAndActual
          .putIfAbsent(key, () => <TestResult>[])
          .add(currentResult);
      index += 3;
    } else if (currentLine.startsWith('stderr:')) {
      if (currentResult != null) {
        currentResult.message = output[index + 1];
        bool hasStackTrace = false;
        int endIndex = index + 1;
        while (endIndex < output.length) {
          String endLine = output[endIndex];
          if (endLine.startsWith('--- ')) {
            break;
          } else if (endLine.startsWith('#0')) {
            hasStackTrace = true;
          }
          endIndex++;
        }
        if (hasStackTrace) {
          currentResult.stackTrace = output.sublist(index + 1, endIndex - 2);
          String traceLine = currentResult.traceLine;
          testsByStackTrace
              .putIfAbsent(traceLine, () => <TestResult>[])
              .add(currentResult);
        }
        index = endIndex;
      }
    } else {
      index += 1;
    }
  }

  List<String> missingCodes = <String>[];
  for (List<TestResult> results in testsByExpectedAndActual.values) {
    for (TestResult result in results) {
      String message = result.message;
      if (message != null) {
        if (message.startsWith('Bad state: Unable to convert (')) {
          missingCodes.add(message);
        }
      }
    }
  }

  print('$failureCount failing tests:');
  print('');
  List<String> keys = testsByExpectedAndActual.keys.toList();
  keys.sort();
  for (String key in keys) {
    List<TestResult> results = testsByExpectedAndActual[key];
    results.sort((first, second) => first.testName.compareTo(second.testName));
    print('$key (${results.length})');
    for (TestResult result in results) {
      if (result.message == null) {
        print('  ${result.testName}');
      } else {
        print('  ${result.testName} (${result.message})');
      }
    }
  }
  if (missingCodes.isNotEmpty) {
    missingCodes.sort();
    print('');
    print('Missing error codes (${missingCodes.length}):');
    for (String message in missingCodes) {
      print('  $message');
    }
  }
  if (testsByStackTrace.isNotEmpty) {
    print('');
    print('Unique stack traces (${testsByStackTrace.length}):');
    List<String> keys = testsByStackTrace.keys.toList();
    keys.sort((first, second) {
      return testsByStackTrace[second].length - testsByStackTrace[first].length;
    });
    for (String traceLine in keys) {
      print('  (${testsByStackTrace[traceLine].length}) $traceLine');
    }
  }
}

/// A representation of the result of a single test.
class TestResult {
  static final RegExp framePattern = RegExp('#[0-9]+ ');

  String testName;
  String expected;
  String actual;
  String message;
  List<String> stackTrace;

  TestResult(this.testName, this.expected, this.actual);

  String get traceLine {
    for (int i = 0; i < stackTrace.length; i++) {
      String traceLine = stackTrace[i];
      if (traceLine.startsWith(framePattern) &&
          traceLine.contains('(package:')) {
        if (traceLine.contains('ResolutionApplier._get') ||
            traceLine.contains('ElementWalker.getAccessor') ||
            traceLine.contains('ElementWalker.getClass') ||
            traceLine.contains('ElementWalker.getEnum') ||
            traceLine.contains('ElementWalker.getVariable') ||
            traceLine.contains('DeclarationResolver._match') ||
            traceLine.contains('DeclarationResolver.applyParameters') ||
            traceLine.contains('ResolutionStorer._store')) {
          return stackTrace[i + 1];
        }
        return traceLine;
      }
    }
    return null;
  }
}
