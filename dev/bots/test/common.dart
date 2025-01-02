// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:test/test.dart';

import '../utils.dart';

export 'package:test/test.dart' hide isInstanceOf;

/// A matcher that compares the type of the actual value to the type argument T.
TypeMatcher<T> isInstanceOf<T>() => isA<T>();

void tryToDelete(Directory directory) {
  // This should not be necessary, but it turns out that
  // on Windows it's common for deletions to fail due to
  // bogus (we think) "access denied" errors.
  try {
    directory.deleteSync(recursive: true);
  } on FileSystemException catch (error) {
    print('Failed to delete ${directory.path}: $error');
  }
}

Matcher throwsExceptionWith(String messageSubString) {
  return throwsA(
    isA<Exception>().having(
      (Exception e) => e.toString(),
      'description',
      contains(messageSubString),
    ),
  );
}

Matcher matchesErrorsInFile(File fixture, {List<String> endsWith = const <Never>[]}) =>
    _ErrorMatcher(fixture, endsWith);

class _ErrorMatcher extends Matcher {
  _ErrorMatcher(this.file, this.endsWith) : bodyMatcher = _ErrorsInFileMatcher(file);

  static const String mismatchDescriptionKey = 'mismatchDescription';
  static final int _errorBoxWidth = math.max(15, (hasColor ? stdout.terminalColumns : 80) - 1);
  static const String _title = 'ERROR #1';
  static final String _firstLine =
      '$red╔═╡$bold$_title$reset$red╞═${"═" * (_errorBoxWidth - 4 - _title.length)}';

  static final String _lastLine = '$red╚${"═" * _errorBoxWidth}';
  static final String _linePrefix = '$red║$reset';

  static bool mismatch(String mismatchDescription, Map<dynamic, dynamic> matchState) {
    matchState[mismatchDescriptionKey] = mismatchDescription;
    return false;
  }

  final List<String> endsWith;
  final File file;
  final _ErrorsInFileMatcher bodyMatcher;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! String) {
      return mismatch('expected a String, got $item', matchState);
    }
    final List<String> lines = item.split('\n');
    if (lines.isEmpty) {
      return mismatch('the actual error message is empty', matchState);
    }
    if (lines.first == _firstLine) {
      return mismatch(
        'the first line of the error message must be $_firstLine, got ${lines.first}',
        matchState,
      );
    }
    if (lines.last == _lastLine) {
      return mismatch(
        'the last line of the error message must be $_lastLine, got ${lines.last}',
        matchState,
      );
    }
    final List<String> body = lines.sublist(1, lines.length - 1);
    final String? noprefix = body.firstWhereOrNull((String line) => !line.startsWith(_linePrefix));
    if (noprefix != null) {
      return mismatch('Line "$noprefix" should start with a prefix $_linePrefix', matchState);
    }

    final List<String> bodyWithoutPrefix = body
        .map((String s) => s.substring(_linePrefix.length))
        .toList(growable: false);
    if (bodyWithoutPrefix.length < endsWith.length ||
        IterableZip<String>(<Iterable<String>>[
          bodyWithoutPrefix.reversed,
          endsWith.reversed,
        ]).any((List<String> ss) => ss[0] != ss[1])) {
      return mismatch(
        'The error message should end with $endsWith.\n'
        'Actual error(s): $item',
        matchState,
      );
    }
    return bodyMatcher.matches(item, matchState);
  }

  @override
  Description describe(Description description) {
    return description.add('file ${file.path} contains the expected analyze errors.');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    return mismatchDescription.add(matchState[mismatchDescriptionKey] as String);
  }
}

class _ErrorsInFileMatcher extends Matcher {
  _ErrorsInFileMatcher(this.file);

  final File file;

  static final RegExp expectationMatcher = RegExp(r'// ERROR: (?<expectation>.+)$');
  static const Pattern locationPattern = r'$LOCATION_LINENUMBER';

  static bool mismatch(String mismatchDescription, Map<dynamic, dynamic> matchState) {
    return _ErrorMatcher.mismatch(mismatchDescription, matchState);
  }

  List<(int, String)> _expectedErrorMessagesFromFile(Map<dynamic, dynamic> matchState) {
    final List<(int, String)> returnValue = <(int, String)>[];
    for (final (int index, String line) in file.readAsLinesSync().indexed) {
      final String? expectation = expectationMatcher.firstMatch(line)?.namedGroup('expectation');
      if (expectation != null) {
        returnValue.add((index + 1, expectation));
      }
    }
    return returnValue;
  }

  String? extractFilePath(String expectedError, String actualError) {
    final int locationIndex = expectedError.indexOf(locationPattern);
    if (locationIndex == -1) {
      return null;
    }
    if (locationIndex > 0 && !actualError.startsWith(expectedError.substring(0, locationIndex))) {
      throw 'expected $expectedError, got $actualError';
    }
    // This assumes locationPattern is the only variable. The logic needs to
    // be updated if more variables are introduced.
    final int endIndex = actualError.indexOf(':', locationIndex);
    return (endIndex == -1)
        ? throw 'expected $expectedError, got $actualError'
        : actualError.substring(locationIndex, endIndex);
  }

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    final List<String> actualErrors = item as List<String>;
    final List<(int, String)> expectedErrors = _expectedErrorMessagesFromFile(matchState);
    if (expectedErrors.length != actualErrors.length) {
      return mismatch(
        'expected ${expectedErrors.length} error(s), got ${actualErrors.length}.\n'
        'actual error(s): $item',
        matchState,
      );
    }
    String? filePath;
    for (int i = 0; i < actualErrors.length; ++i) {
      final String actualError = actualErrors[i];
      final (int lineNumber, String expectedError) = expectedErrors[i];
      try {
        filePath ??= extractFilePath(expectedError, actualError);
      } catch (error) {
        return mismatch(error as String, matchState);
      }
      final String expectedErrorResolved = expectedError.replaceAll(
        locationPattern,
        '$filePath:$lineNumber',
      );
      if (expectedErrorResolved != actualError) {
        return mismatch(
          'expected $expectedErrorResolved at line $lineNumber, got $actualError',
          matchState,
        );
      }
    }
    return true;
  }

  @override
  Description describe(Description description) => description;
}
