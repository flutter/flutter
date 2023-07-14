// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_canvas.dart';

void main() {
  testWidgets('Wrap overflow indicator', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: Wrap(
          textDirection: TextDirection.ltr,
          children: <Widget>[
            SizedBox(width: 200.0, height: 200.0),
          ],
        ),
      ),
    );

    expect(find.byType(Wrap), isNot(paints..rect()));

    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          height: 100.0,
          child: Wrap(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              SizedBox(width: 200.0, height: 200.0),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNotNull);

    expect(find.byType(Wrap), paints..rect());

    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          height: 0.0,
          child: Wrap(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              SizedBox(width: 200.0, height: 200.0),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Wrap), isNot(paints..rect()));
  });
}
