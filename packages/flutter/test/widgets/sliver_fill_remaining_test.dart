// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'test_widgets.dart';

void main() {
  testWidgets('SliverFillRemaining control test', (WidgetTester tester) async {
    List<Widget> children = new List<Widget>.generate(20, (int i) {
      return new Container(child: new Text('$i'));
    });

    await tester.pumpWidget(
      new TestScrollable(
        slivers: <Widget>[
          new SliverFill(
            delegate: new SliverChildListDelegate(children),
          ),
        ],
      ),
    );

    RenderBox box = tester.renderObject<RenderBox>(find.byType(Container).first);
    expect(box.size.height, equals(600.0));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);

    await tester.scroll(find.byType(Scrollable2), const Offset(0.0, -700.0));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);

    await tester.scroll(find.byType(Scrollable2), const Offset(0.0, 200.0));
    await tester.pump();

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
  });
}
