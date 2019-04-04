// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_gallery/gallery/example_code_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter gallery example code parser test', () async {
    final TestAssetBundle bundle = TestAssetBundle();

    final String codeSnippet0 = await getExampleCode('test_0', bundle);
    expect(codeSnippet0, 'test 0 0\ntest 0 1');

    final String codeSnippet1 = await getExampleCode('test_1', bundle);
    expect(codeSnippet1, 'test 1 0\ntest 1 1');

    final String codeSnippet3 = await getExampleCode('test_2_windows_breaks', bundle);
    expect(codeSnippet3, 'windows test 2 0\nwindows test 2 1');
  });
}

const String testCodeFile = '''// A fake test file
// START test_0
test 0 0
test 0 1
// END

// Some comments
// START test_1
test 1 0
test 1 1
// END

// START test_2_windows_breaks\r\nwindows test 2 0\r\nwindows test 2 1\r\n// END
''';

class TestAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async => null;

  @override
  Future<String> loadString(String key, { bool cache = true }) async {
    if (key == 'lib/gallery/example_code.dart')
      return testCodeFile;
    return null;
  }

  @override
  Future<T> loadStructuredData<T>(String key, Future<T> parser(String value)) async {
    return parser(await loadString(key));
  }

  @override
  String toString() => '$runtimeType@$hashCode()';
}
