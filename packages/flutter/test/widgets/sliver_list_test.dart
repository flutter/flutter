import 'package:flutter/foundation.dart';
// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('SliverList changes children (with keys)', (WidgetTester tester) async {
    final List<int> items = new List<int>.generate(20, (int i) => i);
    const double itemHeight = 300.0;
    const double viewportHeight = 500.0;

    final double scrollPosition = 18 * itemHeight;
    final ScrollController controller = new ScrollController(initialScrollOffset: scrollPosition);

    Widget _buildSliverList(List<int> items) {
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Container(
            height: viewportHeight,
            child: new CustomScrollView(
              controller: controller,
              slivers: <Widget>[
                new SliverList(
                  delegate: new SliverChildBuilderDelegate(
                    (BuildContext context, int i) {
                      return new Container(
                        key: new ValueKey<int>(items[i]),
                        height: itemHeight,
                        child: new Text('Tile ${items[i]}'),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(_buildSliverList(items));
    await tester.pumpAndSettle();

    expect(controller.offset, scrollPosition);
    expect(find.text('Tile 0'), findsNothing);
    expect(find.text('Tile 1'), findsNothing);
    expect(find.text('Tile 18'), findsOneWidget);
    expect(find.text('Tile 19'), findsOneWidget);

    await tester.pumpWidget(_buildSliverList(items.reversed.toList()));
    await tester.pumpAndSettle();

    expect(controller.offset, scrollPosition);
    expect(find.text('Tile 19'), findsNothing);
    expect(find.text('Tile 18'), findsNothing);
    expect(find.text('Tile 1'), findsOneWidget);
    expect(find.text('Tile 0'), findsOneWidget);

    controller.jumpTo(0.0);
    await tester.pumpAndSettle();

    expect(controller.offset, 0.0);
    expect(find.text('Tile 19'), findsOneWidget);
    expect(find.text('Tile 18'), findsOneWidget);
    expect(find.text('Tile 1'), findsNothing);
    expect(find.text('Tile 0'), findsNothing);
  });
}
