// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('AbsorbPointers do not block siblings', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      new Column(
        children: <Widget>[
          new Expanded(
            child: new GestureDetector(
              onTap: () => tapped = true,
            ),
          ),
          const Expanded(
            child: const AbsorbPointer(
              absorbing: true,
            ),
          ),
        ],
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    expect(tapped, true);
  });
}