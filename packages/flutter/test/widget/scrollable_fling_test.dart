// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('fling and tap', (WidgetTester tester) async {
    List<String> log = <String>[];

    List<Widget> textWidgets = <Widget>[];
    for (int i = 0; i < 250; i++)
      textWidgets.add(new GestureDetector(onTap: () { log.add('tap $i'); }, child: new Text('$i')));
    await tester.pumpWidget(new Block(children: textWidgets));

    expect(log, equals(<String>[]));
    await tester.tap(find.byType(Scrollable));
    await tester.pump(const Duration(milliseconds: 50));
    expect(log, equals(<String>['tap 18']));
    await tester.fling(find.byType(Scrollable), new Offset(0.0, -200.0), 1000.0);
    await tester.pump(const Duration(milliseconds: 50));
    expect(log, equals(<String>['tap 18']));
    await tester.tap(find.byType(Scrollable));
    await tester.pump(const Duration(milliseconds: 50));
    expect(log, equals(<String>['tap 18']));
  });
}
