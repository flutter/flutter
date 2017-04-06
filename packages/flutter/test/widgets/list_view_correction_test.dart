// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('ListView can handle shrinking top elements', (WidgetTester tester) async {
    final ScrollController controller = new ScrollController();
    await tester.pumpWidget(new ListView(
      controller: controller,
      children: <Widget>[
        new Container(height: 400.0, child: const Text('1')),
        new Container(height: 400.0, child: const Text('2')),
        new Container(height: 400.0, child: const Text('3')),
        new Container(height: 400.0, child: const Text('4')),
        new Container(height: 400.0, child: const Text('5')),
        new Container(height: 400.0, child: const Text('6')),
      ],
    ));

    controller.jumpTo(1000.0);
    await tester.pump();

    expect(tester.getTopLeft(find.text('4')).y, equals(200.0));

    await tester.pumpWidget(new ListView(
      controller: controller,
      children: <Widget>[
        new Container(height: 200.0, child: const Text('1')),
        new Container(height: 400.0, child: const Text('2')),
        new Container(height: 400.0, child: const Text('3')),
        new Container(height: 400.0, child: const Text('4')),
        new Container(height: 400.0, child: const Text('5')),
        new Container(height: 400.0, child: const Text('6')),
      ],
    ));

    expect(controller.offset, equals(1000.0));
    expect(tester.getTopLeft(find.text('4')).y, equals(200.0));

    controller.jumpTo(300.0);
    await tester.pump();

    expect(tester.getTopLeft(find.text('2')).y, equals(100.0));

    controller.jumpTo(50.0);

    await tester.pump();

    expect(controller.offset, equals(0.0));
    expect(tester.getTopLeft(find.text('2')).y, equals(200.0));
  });

}
