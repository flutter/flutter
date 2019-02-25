// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Sliver appbars - floating and pinned - second app bar stacks below', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en', 'us'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: CustomScrollView(
              controller: controller,
              slivers: const <Widget>[
                SliverAppBar(floating: true, pinned: true, expandedHeight: 200.0, title: Text('A')),
                SliverAppBar(primary: false, pinned: true, title: Text('B')),
                SliverList(
                  delegate: SliverChildListDelegate(
                    <Widget>[
                      Text('C'),
                      Text('D'),
                      SizedBox(height: 500.0),
                      Text('E'),
                      SizedBox(height: 500.0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    const Offset textPositionInAppBar = Offset(16.0, 18.0);
    expect(tester.getTopLeft(find.text('A')), textPositionInAppBar);
    // top app bar is 200.0 high at this point
    expect(tester.getTopLeft(find.text('B')), const Offset(0.0, 200.0) + textPositionInAppBar);
    // second app bar is 56.0 high
    expect(tester.getTopLeft(find.text('C')), const Offset(0.0, 200.0 + 56.0)); // height of both appbars
    final Size cSize = tester.getSize(find.text('C'));
    controller.jumpTo(200.0 - 56.0);
    await tester.pump();
    expect(tester.getTopLeft(find.text('A')), textPositionInAppBar);
    // top app bar is now only 56.0 high, same as second
    expect(tester.getTopLeft(find.text('B')), const Offset(0.0, 56.0) + textPositionInAppBar);
    expect(tester.getTopLeft(find.text('C')), const Offset(0.0, 56.0 * 2.0)); // height of both collapsed appbars
    expect(find.text('E'), findsNothing);
    controller.jumpTo(600.0);
    await tester.pump();
    expect(tester.getTopLeft(find.text('A')), textPositionInAppBar); // app bar is pinned at top
    expect(tester.getTopLeft(find.text('B')), const Offset(0.0, 56.0) + textPositionInAppBar); // second one too
    expect(find.text('C'), findsNothing); // contents are scrolled off though
    expect(find.text('D'), findsNothing);
    // we have scrolled 600.0 pixels
    // initial position of E was 200 + 56 + cSize.height + cSize.height + 500
    // we've scrolled that up by 600.0, meaning it's at that minus 600 now:
    expect(tester.getTopLeft(find.text('E')), Offset(0.0, 200.0 + 56.0 + cSize.height * 2.0 + 500.0 - 600.0));
  });

  testWidgets('Does not crash when there is less than minExtent remainingPaintExtent', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/21887.
    final ScrollController controller = ScrollController();
    const double availableHeight = 50.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Container(
            height: availableHeight,
            color: Colors.green,
            child: CustomScrollView(
              controller: controller,
              slivers: <Widget>[
                const SliverAppBar(
                  pinned: true,
                  floating: true,
                  expandedHeight: 120.0,
                ),
                SliverList(
                  delegate: SliverChildListDelegate(List<Widget>.generate(20, (int i) {
                    return Container(
                      child: Text('Tile $i'),
                      height: 100.0,
                    );
                  })),
                )
              ],
            ),
          ),
        ),
      ),
    );
    final RenderSliverFloatingPinnedPersistentHeader render = tester.renderObject(find.byType(SliverAppBar));
    expect(render.minExtent, greaterThan(availableHeight)); // Precondition
    expect(render.geometry.scrollExtent, 120.0);
    expect(render.geometry.paintExtent, availableHeight);
    expect(render.geometry.layoutExtent, availableHeight);

    controller.jumpTo(200.0);
    await tester.pumpAndSettle();
    expect(render.geometry.scrollExtent, 120.0);
    expect(render.geometry.paintExtent, availableHeight);
    expect(render.geometry.layoutExtent, 0.0);
  });

  testWidgets('Pinned and floating SliverAppBar sticks to top the content is scroll down', (WidgetTester tester) async {
    const Key anchor = Key('drag');
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Container(
            height: 300,
            color: Colors.green,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                const SliverAppBar(
                  pinned: true,
                  floating: true,
                  expandedHeight: 100.0,
                ),
                SliverToBoxAdapter(child: Container(key: anchor, color: Colors.red, height: 100)),
                SliverToBoxAdapter(child: Container(height: 600, color: Colors.green)),
              ],
            ),
          ),
        ),
      ),
    );
    final RenderSliverFloatingPinnedPersistentHeader render = tester.renderObject(find.byType(SliverAppBar));

    const double scrollDistance = 40;
    final TestGesture gesture = await tester.press(find.byKey(anchor));
    await gesture.moveBy(const Offset(0, scrollDistance));
    await tester.pump();

    expect(render.geometry.paintOrigin, -scrollDistance);
  });

  testWidgets('Floating SliverAppBar sticks to top the content is scroll down', (WidgetTester tester) async {
    const Key anchor = Key('drag');
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Container(
            height: 300,
            color: Colors.green,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                const SliverAppBar(
                  pinned: false,
                  floating: true,
                  expandedHeight: 100.0,
                ),
                SliverToBoxAdapter(child: Container(key: anchor, color: Colors.red, height: 100)),
                SliverToBoxAdapter(child: Container(height: 600, color: Colors.green)),
              ],
            ),
          ),
        ),
      ),
    );
    final RenderSliverFloatingPersistentHeader render = tester.renderObject(find.byType(SliverAppBar));

    const double scrollDistance = 40;
    final TestGesture gesture = await tester.press(find.byKey(anchor));
    await gesture.moveBy(const Offset(0, scrollDistance));
    await tester.pump();

    expect(render.geometry.paintOrigin, -scrollDistance);
  });

  testWidgets('Pinned SliverAppBar sticks to top the content is scroll down', (WidgetTester tester) async {
    const Key anchor = Key('drag');
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Container(
            height: 300,
            color: Colors.green,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                const SliverAppBar(
                  pinned: true,
                  floating: false,
                  expandedHeight: 100.0,
                ),
                SliverToBoxAdapter(child: Container(key: anchor, color: Colors.red, height: 100)),
                SliverToBoxAdapter(child: Container(height: 600, color: Colors.green)),
              ],
            ),
          ),
        ),
      ),
    );
    final RenderSliverPinnedPersistentHeader render = tester.renderObject(find.byType(SliverAppBar));

    const double scrollDistance = 40;
    final TestGesture gesture = await tester.press(find.byKey(anchor));
    await gesture.moveBy(const Offset(0, scrollDistance));
    await tester.pump();

    expect(render.geometry.paintOrigin, -scrollDistance);
  });
}
