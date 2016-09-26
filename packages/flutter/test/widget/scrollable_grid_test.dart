// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

void main() {
  // Tests https://github.com/flutter/flutter/issues/5522
  testWidgets('ScrollableGrid displays correct children with nonzero padding', (WidgetTester tester) async {
    GlobalKey<ScrollableState> scrollableKey = new GlobalKey<ScrollableState>();
    final EdgeInsets padding = new EdgeInsets.fromLTRB(0.0, 100.0, 0.0, 0.0);

    Widget testWidget = new Align(
      child: new SizedBox(
        height: 800.0,
        width: 300.0,  // forces the grid children to be 300..300
        child: new ScrollableGrid(
          scrollableKey: scrollableKey,
          delegate: new FixedColumnCountGridDelegate(
            columnCount: 1,
            padding: padding
          ),
          children: new List<Widget>.generate(10, (int index) {
            return new Text('$index', key: new ValueKey<int>(index));
          })
        )
      )
    );

    await tester.pumpWidget(testWidget);

    // screen is 600px high, and has the following items:
    //   100..400 = 0
    //   400..700 = 1
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);

    await tester.scroll(find.text('1'), const Offset(0.0, -500.0));
    await tester.pump();
    //  -100..300 = 1
    //   300..600 = 2
    //   600..600 = 3
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsNothing);

    await tester.scroll(find.text('1'), const Offset(0.0, 150.0));
    await tester.pump();
    // Child '0' is now back onscreen, but by less than `padding.top`.
    //  -250..050 = 0
    //   050..450 = 1
    //   450..750 = 2
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);
  });
}
