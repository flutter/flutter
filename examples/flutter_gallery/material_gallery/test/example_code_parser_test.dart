// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_gallery/gallery/example_code_parser.dart';
import 'package:mojo/core.dart' as core;
import 'package:test/test.dart';

void main() {
  test('Flutter gallery example code parser test', () async {
    TestAssetBundle bundle = new TestAssetBundle();

    String codeSnippet0 = await getExampleCode('test_0', bundle);
    expect(codeSnippet0, 'test 0 0\ntest 0 1');

    String codeSnippet1 = await getExampleCode('test_1', bundle);
    expect(codeSnippet1, 'test 1 0\ntest 1 1');
  });
}

const String testCodeFile = """// A fake test file
// START test_0
test 0 0
test 0 1
// END

// Some comments
// START test_1
test 1 0
test 1 1
// END
""";

class TestAssetBundle extends AssetBundle {
  @override
  ImageResource loadImage(String key) => null;

  @override
  Future<String> loadString(String key) {
    if (key == 'lib/gallery/example_code.dart')
      return new Future<String>.value(testCodeFile);
    return null;
  }

  @override
  Future<core.MojoDataPipeConsumer> load(String key) => null;

  @override
  String toString() => '$runtimeType@$hashCode()';
}
