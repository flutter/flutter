// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('ErrorWidget.builder', (WidgetTester tester) async {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return const Text('oopsie!', textDirection: TextDirection.ltr);
    };
    await tester.pumpWidget(
      SizedBox(
        child: Builder(
          builder: (BuildContext context) {
            throw 'test';
          },
        ),
      ),
    );
    expect(tester.takeException().toString(), 'test');
    expect(find.text('oopsie!'), findsOneWidget);
  });
}
