// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CustomScrollView respects cacheExtentStyle', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          cacheExtent: 1.0,
          cacheExtentStyle: CacheExtentStyle.viewport,
          slivers: <Widget>[],
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.cacheExtentStyle, CacheExtentStyle.viewport);
    expect(viewport.cacheExtent, 1.0);
  });

  testWidgets('ListView respects cacheExtentStyle', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView(
          cacheExtent: 1.0,
          cacheExtentStyle: CacheExtentStyle.viewport,
          children: const <Widget>[],
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.cacheExtentStyle, CacheExtentStyle.viewport);
    expect(viewport.cacheExtent, 1.0);
  });

  testWidgets('ListView.builder respects cacheExtentStyle', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.builder(
          cacheExtent: 1.0,
          cacheExtentStyle: CacheExtentStyle.viewport,
          itemBuilder: (BuildContext context, int index) => const Text(''),
          itemCount: 0,
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.cacheExtentStyle, CacheExtentStyle.viewport);
    expect(viewport.cacheExtent, 1.0);
  });

  testWidgets('ListView.separated respects cacheExtentStyle', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.separated(
          cacheExtent: 1.0,
          cacheExtentStyle: CacheExtentStyle.viewport,
          itemBuilder: (BuildContext context, int index) => const Text(''),
          separatorBuilder: (BuildContext context, int index) => const Text(''),
          itemCount: 0,
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.cacheExtentStyle, CacheExtentStyle.viewport);
    expect(viewport.cacheExtent, 1.0);
  });

  testWidgets('ListView.custom respects cacheExtentStyle', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.custom(
          cacheExtent: 1.0,
          cacheExtentStyle: CacheExtentStyle.viewport,
          childrenDelegate: SliverChildListDelegate(const <Widget>[]),
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.cacheExtentStyle, CacheExtentStyle.viewport);
    expect(viewport.cacheExtent, 1.0);
  });

  testWidgets('GridView respects cacheExtentStyle', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView(
          cacheExtent: 1.0,
          cacheExtentStyle: CacheExtentStyle.viewport,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1),
          children: const <Widget>[],
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.cacheExtentStyle, CacheExtentStyle.viewport);
    expect(viewport.cacheExtent, 1.0);
  });

  testWidgets('GridView.builder respects cacheExtentStyle', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.builder(
          cacheExtent: 1.0,
          cacheExtentStyle: CacheExtentStyle.viewport,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1),
          itemBuilder: (BuildContext context, int index) => const Text(''),
          itemCount: 0,
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.cacheExtentStyle, CacheExtentStyle.viewport);
    expect(viewport.cacheExtent, 1.0);
  });

  testWidgets('GridView.custom respects cacheExtentStyle', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.custom(
          cacheExtent: 1.0,
          cacheExtentStyle: CacheExtentStyle.viewport,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1),
          childrenDelegate: SliverChildListDelegate(const <Widget>[]),
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.cacheExtentStyle, CacheExtentStyle.viewport);
    expect(viewport.cacheExtent, 1.0);
  });

  testWidgets('GridView.count respects cacheExtentStyle', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.count(
          cacheExtent: 1.0,
          cacheExtentStyle: CacheExtentStyle.viewport,
          crossAxisCount: 1,
          children: const <Widget>[],
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.cacheExtentStyle, CacheExtentStyle.viewport);
    expect(viewport.cacheExtent, 1.0);
  });

  testWidgets('GridView.extent respects cacheExtentStyle', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GridView.extent(
          cacheExtent: 1.0,
          cacheExtentStyle: CacheExtentStyle.viewport,
          maxCrossAxisExtent: 100,
          children: const <Widget>[],
        ),
      ),
    );
    final RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.cacheExtentStyle, CacheExtentStyle.viewport);
    expect(viewport.cacheExtent, 1.0);
  });

  testWidgets('shrinkWrap in unbounded context with cacheExtent style viewport', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          child: ListView.builder(
            cacheExtent: 0.5,
            cacheExtentStyle: CacheExtentStyle.viewport,
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
}
