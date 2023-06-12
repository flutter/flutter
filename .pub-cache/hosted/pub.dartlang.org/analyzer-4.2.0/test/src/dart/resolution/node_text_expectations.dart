// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/source/line_info.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

class NodeTextExpectationsCollector {
  static const updatingIsEnabled = false;

  static const assertMethods = {
    'ContextResolutionTest.assertDriverStateString',
    'FileResolutionTest.assertStateString',
    'ResolutionTest.assertResolvedNodeText',
  };

  static final Map<String, _File> _files = {};

  static void add(String actual) {
    if (!updatingIsEnabled) {
      return;
    }

    var traceLines = '${StackTrace.current}'.split('\n');
    for (var traceIndex = 0; traceIndex < traceLines.length; traceIndex++) {
      var traceLine = traceLines[traceIndex];
      for (var assertMethod in assertMethods) {
        if (traceLine.contains(' $assertMethod ')) {
          var invocationLine = traceLines[traceIndex + 1];
          var locationMatch = RegExp(
            r'file://(.+_test.dart):(\d+):',
          ).firstMatch(invocationLine);
          if (locationMatch == null) {
            fail('Cannot parse: $invocationLine');
          }

          var path = locationMatch.group(1)!;
          var line = int.parse(locationMatch.group(2)!);
          var file = _getFile(path);

          var invocationOffset = file.lineInfo.getOffsetOfLine(line - 1);

          const String rawStringPrefix = "r'''";
          var expectationOffset = file.content.indexOf(
            rawStringPrefix,
            invocationOffset,
          );
          expectationOffset += rawStringPrefix.length;
          var expectationEnd = file.content.indexOf("'''", expectationOffset);

          file.replacements.add(
            _Replacement(
              expectationOffset,
              expectationEnd,
              '\n$actual',
            ),
          );
        }
      }
    }
  }

  static void _apply() {
    for (var file in _files.values) {
      file.applyReplacements();
    }
    _files.clear();
  }

  static _File _getFile(String path) {
    return _files[path] ??= _File(path);
  }
}

@reflectiveTest
class UpdateNodeTextExpectations {
  test_applyReplacements() {
    NodeTextExpectationsCollector._apply();
  }
}

class _File {
  final String path;
  final String content;
  final LineInfo lineInfo;
  final List<_Replacement> replacements = [];

  factory _File(String path) {
    var content = io.File(path).readAsStringSync();
    return _File._(
      path: path,
      content: content,
      lineInfo: LineInfo.fromContent(content),
    );
  }

  _File._({
    required this.path,
    required this.content,
    required this.lineInfo,
  });

  void applyReplacements() {
    replacements.sort((a, b) => b.offset - a.offset);
    var newCode = content;
    for (var replacement in replacements) {
      newCode = newCode.substring(0, replacement.offset) +
          replacement.text +
          newCode.substring(replacement.end);
    }
    io.File(path).writeAsStringSync(newCode);
  }
}

class _Replacement {
  final int offset;
  final int end;
  final String text;

  _Replacement(this.offset, this.end, this.text);
}
