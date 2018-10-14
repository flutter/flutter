// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'mock_canvas.dart';

void main() {
  testWidgets('Flex overflow indicator', (WidgetTester tester) async {
    await tester.pumpWidget(
      Center(
        child: Column(
          children: const <Widget>[
            SizedBox(width: 200.0, height: 200.0),
          ],
        ),
      ),
    );

    expect(find.byType(Column), isNot(paints..rect()));

    await tester.pumpWidget(
      Center(
        child: SizedBox(
          height: 100.0,
          child: Column(
            children: const <Widget>[
              SizedBox(width: 200.0, height: 200.0),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNotNull);

    expect(find.byType(Column), paints..rect());

    await tester.pumpWidget(
      Center(
        child: SizedBox(
          height: 0.0,
          child: Column(
            children: const <Widget>[
              SizedBox(width: 200.0, height: 200.0),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Column), isNot(paints..rect()));
  });
}
