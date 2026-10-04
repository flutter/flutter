// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CustomScrollView respects scrollCacheExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(scrollCacheExtent: ScrollCacheExtent.viewport(1.0)),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.scrollCacheExtent, const ScrollCacheExtent.viewport(1.0));
  });

  testWidgets('ListView respects scrollCacheExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(scrollCacheExtent: const ScrollCacheExtent.viewport(1.0)),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.scrollCacheExtent, const ScrollCacheExtent.viewport(1.0));
  });

  testWidgets('ListView.builder respects scrollCacheExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.builder(
          scrollCacheExtent: const ScrollCacheExtent.viewport(1.0),
          itemBuilder: (BuildContext context, int index) => const Text(''),
          itemCount: 0,
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.scrollCacheExtent, const ScrollCacheExtent.viewport(1.0));
  });

  testWidgets('ListView.separated respects scrollCacheExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.separated(
          scrollCacheExtent: const ScrollCacheExtent.viewport(1.0),
          itemBuilder: (BuildContext context, int index) => const Text(''),
          separatorBuilder: (BuildContext context, int index) => const Text(''),
          itemCount: 0,
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.scrollCacheExtent, const ScrollCacheExtent.viewport(1.0));
  });

  testWidgets('ListView.custom respects scrollCacheExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.custom(
          scrollCacheExtent: const ScrollCacheExtent.viewport(1.0),
          childrenDelegate: SliverChildListDelegate(const <Widget>[]),
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.scrollCacheExtent, const ScrollCacheExtent.viewport(1.0));
  });

  testWidgets('GridView respects scrollCacheExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView(
          scrollCacheExtent: const ScrollCacheExtent.viewport(1.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1),
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.scrollCacheExtent, const ScrollCacheExtent.viewport(1.0));
  });

  testWidgets('GridView.builder respects scrollCacheExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.builder(
          scrollCacheExtent: const ScrollCacheExtent.viewport(1.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1),
          itemBuilder: (BuildContext context, int index) => const Text(''),
          itemCount: 0,
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.scrollCacheExtent, const ScrollCacheExtent.viewport(1.0));
  });

  testWidgets('GridView.custom respects scrollCacheExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.custom(
          scrollCacheExtent: const ScrollCacheExtent.viewport(1.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1),
          childrenDelegate: SliverChildListDelegate(const <Widget>[]),
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.scrollCacheExtent, const ScrollCacheExtent.viewport(1.0));
  });

  testWidgets('GridView.count respects scrollCacheExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.count(
          scrollCacheExtent: const ScrollCacheExtent.viewport(1.0),
          crossAxisCount: 1,
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.scrollCacheExtent, const ScrollCacheExtent.viewport(1.0));
  });

  testWidgets('GridView.extent respects scrollCacheExtent', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.extent(
          scrollCacheExtent: const ScrollCacheExtent.viewport(1.0),
          maxCrossAxisExtent: 100,
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.scrollCacheExtent, const ScrollCacheExtent.viewport(1.0));
  });

  testWidgets('shrinkWrap in unbounded context with scrollCacheExtent style viewport', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          child: ListView.builder(
            scrollCacheExtent: const ScrollCacheExtent.viewport(0.5),
            shrinkWrap: true,
            itemCount: 20,
            itemBuilder: (BuildContext context, int index) {
              return Text('$index');
            },
          ),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    expect(find.text('19'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ScrollView respects scrollCacheExtent (pixels)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(scrollCacheExtent: ScrollCacheExtent.pixels(100)),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.scrollCacheExtent, const ScrollCacheExtent.pixels(100));
    // The deprecated getter should still return the value.
    expect(viewport.cacheExtent, 100);
    expect(viewport.cacheExtentStyle, CacheExtentStyle.pixel);
  });

  testWidgets('ScrollView respects scrollCacheExtent (viewport)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(scrollCacheExtent: ScrollCacheExtent.viewport(2.0)),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.scrollCacheExtent, const ScrollCacheExtent.viewport(2.0));
    // The deprecated getter should still return the value.
    expect(viewport.cacheExtent, 2.0);
    expect(viewport.cacheExtentStyle, CacheExtentStyle.viewport);
  });

  testWidgets('Semantics nodes in cache extent are marked as hidden', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.builder(
          scrollCacheExtent: const ScrollCacheExtent.pixels(100.0),
          itemCount: 20,
          itemBuilder: (BuildContext context, int index) {
            return SizedBox(height: 100, child: Text('Item $index'));
          },
        ),
      ),
    );

    // Viewport height is 600 by default.
    // Items 0-5 are visible (0-600).
    // Item 6 is in cache extent (600-700).
    // Item 7 is outside (700-800).

    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 5'), findsOneWidget);
    expect(find.text('Item 6', skipOffstage: false), findsOneWidget);
    expect(find.text('Item 7', skipOffstage: false), findsNothing);

    // Check semantics
    expect(tester.getSemantics(find.text('Item 5')), matchesSemantics(label: 'Item 5'));

    expect(
      tester.getSemantics(find.text('Item 6', skipOffstage: false)),
      matchesSemantics(label: 'Item 6', isHidden: true),
    );

    handle.dispose();
  });

  testWidgets('Semantics nodes in cache extent (viewport) are marked as hidden', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.builder(
          scrollCacheExtent: const ScrollCacheExtent.viewport(2.0),
          itemCount: 20,
          itemBuilder: (BuildContext context, int index) {
            return SizedBox(height: 100, child: Text('Item $index'));
          },
        ),
      ),
    );

    // Viewport height is 600 by default.
    // Cache extent is 2.0 * 600 = 1200.
    // Items 0-5 are visible (0-600).
    // Items 6-17 are in cache extent (600-1800).
    // Item 18 starts at 1800, so it is just outside.

    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Item 5'), findsOneWidget);
    expect(find.text('Item 6', skipOffstage: false), findsOneWidget);
    expect(find.text('Item 17', skipOffstage: false), findsOneWidget);
    expect(find.text('Item 18', skipOffstage: false), findsNothing);

    // Check semantics
    expect(tester.getSemantics(find.text('Item 5')), matchesSemantics(label: 'Item 5'));

    expect(
      tester.getSemantics(find.text('Item 6', skipOffstage: false)),
      matchesSemantics(label: 'Item 6', isHidden: true),
    );
    expect(
      tester.getSemantics(find.text('Item 17', skipOffstage: false)),
      matchesSemantics(label: 'Item 17', isHidden: true),
    );

    handle.dispose();
  });
}
