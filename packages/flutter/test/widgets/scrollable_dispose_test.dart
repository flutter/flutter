// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'test_widgets.dart';

void main() {
  testWidgets('simultaneously dispose a widget and end the scroll animation', (WidgetTester tester) async {
    final List<Widget> textWidgets = <Widget>[];
    for (int i = 0; i < 250; i++)
      textWidgets.add(Text('$i'));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FlipWidget(
          left: ListView(children: textWidgets),
          right: Container()
        ),
      ),
    );

    await tester.fling(find.byType(ListView), const Offset(0.0, -200.0), 1000.0);
    await tester.pump();

    tester.state<FlipWidgetState>(find.byType(FlipWidget)).flip();
    await tester.pump(const Duration(hours: 5));
  });
}
