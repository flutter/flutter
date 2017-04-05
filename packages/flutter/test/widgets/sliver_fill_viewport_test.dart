// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('SliverFillRemaining control test', (WidgetTester tester) async {
    final List<Widget> children = new List<Widget>.generate(20, (int i) {
      return new Container(child: new Text('$i'));
    });

    await tester.pumpWidget(
      new CustomScrollView(
        slivers: <Widget>[
          new SliverFillViewport(
            delegate: new SliverChildListDelegate(children),
          ),
        ],
      ),
    );

    final RenderBox box = tester.renderObject<RenderBox>(find.byType(Container).first);
    expect(box.size.height, equals(600.0));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);

    await tester.drag(find.byType(Scrollable), const Offset(0.0, -700.0));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsNothing);
    expect(find.text('4'), findsNothing);

    await tester.drag(find.byType(Scrollable), const Offset(0.0, 200.0));
    await tester.pump();

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);

    await tester.drag(find.byType(Scrollable), const Offset(0.0, 700.0));
    await tester.pump();

    final RenderBox box2 = tester.renderObject<RenderBox>(find.byType(Container).first);
    expect(box2.size.height, equals(600.0));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
  });
}
