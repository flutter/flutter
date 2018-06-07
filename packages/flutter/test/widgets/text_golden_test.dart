// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Centered text', (WidgetTester tester) async {
    await tester.pumpWidget(
      new RepaintBoundary(
        child: new Center(
          child: new Container(
            width: 200.0,
            height: 100.0,
            decoration: const BoxDecoration(
              color: const Color(0xff00ff00),
            ),
            child: const Text('Hello',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: const Color(0xffff0000)),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Container),
      matchesGoldenFile('text_golden.Centered.png'),
      skip: !Platform.isLinux,
    );

    await tester.pumpWidget(
      new RepaintBoundary(
        child: new Center(
          child: new Container(
            width: 200.0,
            height: 100.0,
            decoration: const BoxDecoration(
              color: const Color(0xff00ff00),
            ),
            child: const Text('Hello world how are you today',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: const Color(0xffff0000)),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(Container),
      matchesGoldenFile('text_golden.Centered.wrap.png'),
      skip: !Platform.isLinux,
    );
  });
}
