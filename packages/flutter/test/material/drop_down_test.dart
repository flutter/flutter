// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Drop down screen edges', (WidgetTester tester) async {
    int value = 4;
    List<DropdownMenuItem<int>> items = <DropdownMenuItem<int>>[];
    for (int i = 0; i < 20; ++i)
      items.add(new DropdownMenuItem<int>(value: i, child: new Text('$i')));

    void handleChanged(int newValue) {
      value = newValue;
    }

    DropdownButton<int> button = new DropdownButton<int>(
      value: value,
      onChanged: handleChanged,
      items: items
    );

    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Align(
            alignment: FractionalOffset.topCenter,
            child: button
          )
        )
      )
    );

    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    // We should have two copies of item 5, one in the menu and one in the
    // button itself.
    expect(tester.elementList(find.text('5')), hasLength(2));

    // We should only have one copy of item 19, which is in the button itself.
    // The copy in the menu shouldn't be in the tree because it's off-screen.
    expect(tester.elementList(find.text('19')), hasLength(1));

    expect(value, 4);
    await tester.tap(find.byConfig(button));
    expect(value, 4);
    await tester.idle(); // this waits for the route's completer to complete, which calls handleChanged
    expect(value, 4);

    // TODO(abarth): Remove these calls to pump once navigator cleans up its
    // pop transitions.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

  });
}
