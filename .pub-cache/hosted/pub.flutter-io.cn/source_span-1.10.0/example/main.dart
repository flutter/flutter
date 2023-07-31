// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:source_span/source_span.dart';

void main(List<String> args) {
  final file = File('README.md');
  final contents = file.readAsStringSync();

  final sourceFile = SourceFile.fromString(contents, url: file.uri);
  final spans = _parseFile(contents, sourceFile);

  for (var span in spans.take(30)) {
    print('[${span.start.line + 1}:${span.start.column + 1}] ${span.text}');
  }
}

Iterable<SourceSpan> _parseFile(String contents, SourceFile sourceFile) sync* {
  var wordStart = 0;
  var inWhiteSpace = true;

  for (var i = 0; i < contents.length; i++) {
    final codeUnit = contents.codeUnitAt(i);

    if (codeUnit == _eol || codeUnit == _space) {
      if (!inWhiteSpace) {
        inWhiteSpace = true;

        // emit a word
        yield sourceFile.span(wordStart, i);
      }
    } else {
      if (inWhiteSpace) {
        inWhiteSpace = false;

        wordStart = i;
      }
    }
  }

  if (!inWhiteSpace) {
    // emit a word
    yield sourceFile.span(wordStart, contents.length);
  }
}

const int _eol = 10;
const int _space = 32;
