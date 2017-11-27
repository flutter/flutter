// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FlatButton implements debugFillDescription', (WidgetTester tester) async {
    final List<String> description = <String>[];
    new FlatButton(
        onPressed: () {},
        textColor: const Color(0xFF00FF00),
        disabledTextColor: const Color(0xFFFF0000),
        color: const Color(0xFF000000),
        highlightColor: const Color(0xFF1565C0),
        splashColor: const Color(0xFF9E9E9E),
        child: const Text('Hello'),
    ).debugFillDescription(description);
    expect(description, <String>[
      'onPressed: Closure: () => dynamic',
      'textColor: Color(0xff00ff00)',
      'disabledTextColor: Color(0xffff0000)',
      'color: Color(0xff000000)',
      'highlightColor: Color(0xff1565c0)',
      'splashColor: Color(0xff9e9e9e)',
      'child: Text("Hello")',
    ]);
  });
}
