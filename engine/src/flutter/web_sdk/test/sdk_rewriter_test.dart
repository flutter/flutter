// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import '../sdk_rewriter.dart';

void main() {
  test('handles exports correctly in the engine library file', () {
    const String source = '''
// Comment 1

library engine;

// Comment 2

export 'engine/file1.dart';
export'engine/file2.dart';
export      'engine/file3.dart';
''';

    const String expected = '''
// Comment 1

@JS()
library dart._engine;

import 'dart:async';
import 'dart:collection';
import 'dart:convert' hide Codec;
import 'dart:developer' as developer;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:_js_annotations';
import 'dart:math' as math;
import 'dart:svg' as svg;
import 'dart:typed_data';
import 'dart:ui' as ui;


// Comment 2

part 'engine/file1.dart';
part 'engine/file2.dart';
part 'engine/file3.dart';
''';

    final String result = rewriteFile(
      source,
      filePath: '/path/to/lib/web_ui/lib/src/engine.dart',
      isUi: false,
      isEngine: true,
    );
    expect(result, expected);
  });

  test('complains about non-compliant engine.dart file', () {
    const String source = '''
library engine;

import 'dart:something';
export 'engine/file1.dart';
export 'engine/file3.dart';
''';

    Object? caught;
    try {
      rewriteFile(
        source,
        filePath: '/path/to/lib/web_ui/lib/src/engine.dart',
        isUi: false,
        isEngine: true,
      );
    } catch(error) {
      caught = error;
    }
    expect(caught, isA<Exception>());
    expect(
      '$caught',
      'Exception: on line 3: unexpected code in /path/to/lib/web_ui/lib/src/engine.dart. '
      'This file may only contain comments and exports. Found:\n'
      'import \'dart:something\';',
    );
  });


  test('removes imports/exports from engine files', () {
    const String source = '''
import 'package:some_package/some_package.dart';
import 'package:some_package/some_package/foo.dart';
import 'package:some_package/some_package' as some_package;

import 'file1.dart';
import'file2.dart';
import      'file3.dart';

export 'file4.dart';
export'file5.dart';
export      'file6.dart';

void printSomething() {
  print('something');
}
''';

    const String expected = '''
part of dart._engine;



void printSomething() {
  print('something');
}
''';

    final String result = rewriteFile(
      source,
      filePath: '/path/to/lib/web_ui/lib/src/engine/my_file.dart',
      isUi: false,
      isEngine: true,
    );
    expect(result, expected);
  });

  test('does not insert an extra part directive', () {
    const String source = '''
part of engine;

void printSomething() {
  print('something');
}
''';

    const String expected = '''
part of dart._engine;

void printSomething() {
  print('something');
}
''';

    final String result = rewriteFile(
      source,
      filePath: '/path/to/lib/web_ui/lib/src/engine/my_file.dart',
      isUi: false,
      isEngine: true,
    );
    expect(result, expected);
  });
}
