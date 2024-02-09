// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ValueKey<String> buildKey(String text) => ValueKey<String>(text);
  Text buildText(String text) => Text(text, key: buildKey(text));

  testWidgets('PinnedHeaderSliver basics', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              PinnedHeaderSliver(
                child: buildText('PinnedHeaderSliver'),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) => buildText('Item $index'),
                  childCount: 100,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Rect getHeaderRect() => tester.getRect(find.byKey(buildKey('PinnedHeaderSliver')));
    Rect getItemRect(int index) => tester.getRect(find.byKey(buildKey('Item $index')));

    // The test viewport is 800 x 600 (width x height).
    // The header's child is at the top of the scroll view and all items are the same height.
    expect(getHeaderRect().top, 0);
    expect(getHeaderRect().width, 800);
    expect(getHeaderRect().height, getItemRect(0).height);

    // First and last visible items
    final double itemHeight = getItemRect(0).height;
    final int visibleItemCount = (600 ~/ itemHeight) - 1; // less 1 for the header
    expect(find.byKey(buildKey('Item 0')), findsOneWidget);
    expect(find.byKey(buildKey('Item ${visibleItemCount - 1}')), findsOneWidget);

    // Scrolling up and down leaves the header at the top.
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    position.moveTo(itemHeight * 5);
    await tester.pumpAndSettle();
    expect(getHeaderRect().top, 0);
    expect(getHeaderRect().width, 800);
    position.moveTo(itemHeight * -5);
    expect(getHeaderRect().top, 0);
    expect(getHeaderRect().width, 800);
  });

  testWidgets('PinnedHeaderSliver: multiple headers layout one after the other', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              PinnedHeaderSliver(
                child: buildText('PinnedHeaderSliver 0'),
              ),
              PinnedHeaderSliver(
                child: buildText('PinnedHeaderSliver 1'),
              ),
              PinnedHeaderSliver(
                child: buildText('PinnedHeaderSliver 2'),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) => buildText('Item $index'),
                  childCount: 100,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final Rect rect0 = tester.getRect(find.byKey(buildKey('PinnedHeaderSliver 0')));
    expect(rect0.top, 0);
    expect(rect0.width, 800);

    final Rect rect1 = tester.getRect(find.byKey(buildKey('PinnedHeaderSliver 1')));
    expect(rect1.top, rect0.bottom);
    expect(rect1.width, 800);

    final Rect rect2 = tester.getRect(find.byKey(buildKey('PinnedHeaderSliver 2')));
    expect(rect2.top, rect1.bottom);
    expect(rect2.width, 800);
  });
}
