// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Radio control test', (WidgetTester tester) async {
    Key key = new UniqueKey();
    List<int> log = <int>[];

    await tester.pumpWidget(new Material(
      child: new Center(
        child: new Radio<int>(
          key: key,
          value: 1,
          groupValue: 2,
          onChanged: (int value) {
            log.add(value);
          },
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, equals(<int>[1]));
    log.clear();

    await tester.pumpWidget(new Material(
      child: new Center(
        child: new Radio<int>(
          key: key,
          value: 1,
          groupValue: 1,
          onChanged: (int value) {
            log.add(value);
          },
          activeColor: Colors.green[500],
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, isEmpty);

    await tester.pumpWidget(new Material(
      child: new Center(
        child: new Radio<int>(
          key: key,
          value: 1,
          groupValue: 2,
          onChanged: null,
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, isEmpty);
  });
}
