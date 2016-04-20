// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mojo/core.dart' as core;

import 'package:test/test.dart';

import '../lib/gallery/example_code_parser.dart';

void main() {
  test('Material Gallery example code parser test', () {
    testWidgets((WidgetTester tester) {
      TestParsingWidget testWidget = new TestParsingWidget();
      tester.pumpWidget(testWidget);
    });
  });
}

class TestParsingWidget extends StatefulWidget {
  @override
  TestParsingWidgetState createState() => new TestParsingWidgetState();
}

class TestParsingWidgetState extends State<TestParsingWidget> {
  @override
  void initState() {
    super.initState();
    getExampleCode('test_0', new TestAssetBundle()).then((String codeSnippet) {
      expect(codeSnippet, 'test 0 0\ntest 0 1');
    });
    getExampleCode('test_1', new TestAssetBundle()).then((String codeSnippet) {
      expect(codeSnippet, 'test 1 0\ntest 1 1');
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Container();
  }
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
  Future<String> loadString(String key) {if (key == 'lib/gallery/example_code.dart')
      return (new Completer<String>()..complete(testCodeFile)).future;
    return null;
  }

  @override
  Future<core.MojoDataPipeConsumer> load(String key) => null;

  @override
  String toString() => '$runtimeType@$hashCode()';
}
