// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('runApp inside onPressed does not throw', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: RaisedButton(
            onPressed: () {
              runApp(const Center(child: Text('Done', textDirection: TextDirection.ltr,)));
            },
            child: const Text('GO')
          )
        )
      )
    );
    await tester.tap(find.text('GO'));
    expect(find.text('Done'), findsOneWidget);
  });
}
