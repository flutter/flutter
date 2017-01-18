// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('InkWell gestures control test', (WidgetTester tester) async {
    List<String> log = <String>[];

    await tester.pumpWidget(new Material(
      child: new Center(
        child: new InkWell(
          onTap: () {
            log.add('tap');
          },
          onDoubleTap: () {
            log.add('double-tap');
          },
          onLongPress: () {
            log.add('long-press');
          },
        ),
      ),
    ));

    await tester.tap(find.byType(InkWell), pointer: 1);

    expect(log, isEmpty);

    await tester.pump(const Duration(seconds: 1));

    expect(log, equals(<String>['tap']));
    log.clear();

    await tester.tap(find.byType(InkWell), pointer: 2);
    await tester.tap(find.byType(InkWell), pointer: 3);

    expect(log, equals(<String>['double-tap']));
    log.clear();

    await tester.longPress(find.byType(InkWell), pointer: 4);

    expect(log, equals(<String>['long-press']));
  });
}
