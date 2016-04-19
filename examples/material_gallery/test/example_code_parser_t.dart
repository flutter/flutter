// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:test/test.dart';
import '../lib/gallery/example_code_parser.dart';

void main() {
  print('starting!');
  test('Material Gallery example code parser test', () {
    print('start test');
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new TestParsingWidget());
    });
    print('end test');
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
    getExampleCode('test', DefaultAssetBundle.of(context)).then((String code) {
      print('Loaded: $code');
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
