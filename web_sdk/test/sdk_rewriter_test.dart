// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import '../sdk_rewriter.dart';

void main() {
  test('handles imports/exports correctly in the engine library file', () {
    const String source = '''
library engine;

import '../ui.dart' as ui;
import 'package:ui/ui.dart' as ui;

import 'package:some_package/some_package.dart';

import 'engine/file1.dart';
export 'engine/file1.dart';

import'engine/file2.dart';
export'engine/file2.dart';

import      'engine/file3.dart';
export      'engine/file3.dart';
''';

    const String expected = '''
library dart._engine;

import 'dart:ui' as ui;
import 'dart:ui' as ui;

import 'package:some_package/some_package.dart';


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
