// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Chip control test', (WidgetTester tester) async {
    bool didDeleteChip = false;
    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Center(
            child: new Chip(
              avatar: new CircleAvatar(
                child: const Text('C')
              ),
              label: const Text('Chip'),
              onDeleted: () {
                didDeleteChip = true;
              }
            )
          )
        )
      )
    );

    expect(didDeleteChip, isFalse);
    await tester.tap(find.byType(Tooltip));
    expect(didDeleteChip, isTrue);
  });
}
