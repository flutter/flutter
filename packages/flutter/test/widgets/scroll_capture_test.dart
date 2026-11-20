// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Object?> _sendScrollCapture(
  WidgetTester tester,
  String method, [
  Map<String, Object?>? arguments,
]) async {
  const MethodCodec codec = JSONMethodCodec();
  ByteData? response;
  var responded = false;
  // Not awaited: some requests wait for the next frame before responding.
  unawaited(
    tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.scrollCapture.name,
      codec.encodeMethodCall(MethodCall(method, arguments)),
      (ByteData? data) {
        response = data;
        responded = true;
      },
    ),
  );
  await tester.idle();
  for (var i = 0; i < 5 && !responded; i++) {
    await tester.pump();
  }
  expect(responded, isTrue, reason: '$method did not respond');
  return codec.decodeEnvelope(response!);
}

Widget _buildList({
  int itemCount = 100,
  ScrollController? controller,
  bool reverse = false,
  PreferredSizeWidget? appBar,
}) {
  return MaterialApp(
    home: Scaffold(
      appBar: appBar,
      body: ListView.builder(
        controller: controller,
        reverse: reverse,
        itemExtent: 50,
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) => Text('Item $index'),
      ),
    ),
  );
}

const double dpr = 3.0;

void main() {
  testWidgets('search returns null when there is no scrollable content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Hello'))));
    expect(await _sendScrollCapture(tester, 'ScrollCapture.search'), isNull);
  });

  testWidgets('search returns null when the content fits in the viewport', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildList(itemCount: 3));
    expect(await _sendScrollCapture(tester, 'ScrollCapture.search'), isNull);
  });

  testWidgets('search returns the physical bounds of the scrollable', (WidgetTester tester) async {
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_buildList(appBar: AppBar(title: const Text('Title'))));

    final Rect bounds = tester.getRect(find.byType(Scrollable));
    expect(await _sendScrollCapture(tester, 'ScrollCapture.search'), <String, Object?>{
      'left': (bounds.left * dpr).round(),
      'top': (bounds.top * dpr).round(),
      'right': (bounds.right * dpr).round(),
      'bottom': (bounds.bottom * dpr).round(),
    });
  });

  testWidgets('search ignores horizontal scrollables', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemExtent: 50,
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) => Text('Item $index'),
        ),
      ),
    );
    expect(await _sendScrollCapture(tester, 'ScrollCapture.search'), isNull);
  });

  testWidgets('search picks the largest visible vertical scrollable', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget list(Key key) => ListView.builder(
      key: key,
      itemExtent: 50,
      itemCount: 100,
      itemBuilder: (BuildContext context, int index) => Text('Item $index'),
    );
    const smallKey = Key('small');
    const largeKey = Key('large');
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: <Widget>[
            SizedBox(height: 100, child: list(smallKey)),
            Expanded(child: list(largeKey)),
          ],
        ),
      ),
    );

    final Rect bounds = tester.getRect(find.byKey(largeKey));
    expect(await _sendScrollCapture(tester, 'ScrollCapture.search'), <String, Object?>{
      'left': bounds.left.round(),
      'top': bounds.top.round(),
      'right': bounds.right.round(),
      'bottom': bounds.bottom.round(),
    });
  });

  testWidgets('search ignores scrollables covered by another route', (WidgetTester tester) async {
    await tester.pumpWidget(_buildList());
    expect(await _sendScrollCapture(tester, 'ScrollCapture.search'), isNotNull);

    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(builder: (BuildContext context) => const Scaffold(body: Text('Top'))),
    );
    await tester.pumpAndSettle();

    // The list is still mounted, but is not visible.
    expect(find.byType(ListView, skipOffstage: false), findsOneWidget);
    expect(await _sendScrollCapture(tester, 'ScrollCapture.search'), isNull);
  });

  testWidgets('scrollTo scrolls the requested area into view and end restores the offset', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ScrollController(initialScrollOffset: 500);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_buildList(controller: controller));

    final double viewportHeight = tester.getSize(find.byType(Scrollable)).height;
    expect(await _sendScrollCapture(tester, 'ScrollCapture.start'), isNotNull);

    // Already visible: no scrolling.
    expect(
      await _sendScrollCapture(tester, 'ScrollCapture.scrollTo', <String, Object?>{
        'top': 0,
        'bottom': (100 * dpr).round(),
      }),
      <String, Object?>{'scrollDelta': 0},
    );
    expect(controller.offset, 500);

    // Below the viewport: scroll down just enough to show it.
    expect(
      await _sendScrollCapture(tester, 'ScrollCapture.scrollTo', <String, Object?>{
        'top': (viewportHeight * dpr).round(),
        'bottom': ((viewportHeight + 200) * dpr).round(),
      }),
      <String, Object?>{'scrollDelta': (200 * dpr).round()},
    );
    expect(controller.offset, 700);

    // Above the viewport: scroll up.
    expect(
      await _sendScrollCapture(tester, 'ScrollCapture.scrollTo', <String, Object?>{
        'top': (-300 * dpr).round(),
        'bottom': (-100 * dpr).round(),
      }),
      <String, Object?>{'scrollDelta': (-300 * dpr).round()},
    );
    expect(controller.offset, 200);

    // Beyond the start of the content: clamped.
    expect(
      await _sendScrollCapture(tester, 'ScrollCapture.scrollTo', <String, Object?>{
        'top': (-1000 * dpr).round(),
        'bottom': (-800 * dpr).round(),
      }),
      <String, Object?>{'scrollDelta': (-500 * dpr).round()},
    );
    expect(controller.offset, 0);

    await _sendScrollCapture(tester, 'ScrollCapture.end');
    expect(controller.offset, 500);
  });

  testWidgets('scrollTo is clamped to the end of the content', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_buildList(controller: controller));

    final double maxScrollExtent = controller.position.maxScrollExtent;
    expect(await _sendScrollCapture(tester, 'ScrollCapture.start'), isNotNull);
    expect(
      await _sendScrollCapture(tester, 'ScrollCapture.scrollTo', <String, Object?>{
        'top': 50000,
        'bottom': 50500,
      }),
      <String, Object?>{'scrollDelta': maxScrollExtent.round()},
    );
    expect(controller.offset, maxScrollExtent);
    await _sendScrollCapture(tester, 'ScrollCapture.end');
    expect(controller.offset, 0);
  });

  testWidgets('scrollTo handles reversed scrollables', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ScrollController(initialScrollOffset: 500);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_buildList(controller: controller, reverse: true));

    final double viewportHeight = tester.getSize(find.byType(Scrollable)).height;
    expect(await _sendScrollCapture(tester, 'ScrollCapture.start'), isNotNull);

    // Content below the viewport is at lower scroll offsets in a reversed list.
    expect(
      await _sendScrollCapture(tester, 'ScrollCapture.scrollTo', <String, Object?>{
        'top': viewportHeight.round(),
        'bottom': (viewportHeight + 200).round(),
      }),
      <String, Object?>{'scrollDelta': 200},
    );
    expect(controller.offset, 300);

    await _sendScrollCapture(tester, 'ScrollCapture.end');
    expect(controller.offset, 500);
  });

  testWidgets('scrollTo returns null without a session', (WidgetTester tester) async {
    await tester.pumpWidget(_buildList());
    expect(
      await _sendScrollCapture(tester, 'ScrollCapture.scrollTo', <String, Object?>{
        'top': 0,
        'bottom': 100,
      }),
      isNull,
    );
  });

  testWidgets('scrollTo returns null after the scrollable is disposed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildList());
    expect(await _sendScrollCapture(tester, 'ScrollCapture.start'), isNotNull);

    await tester.pumpWidget(const MaterialApp(home: Text('Gone')));
    expect(
      await _sendScrollCapture(tester, 'ScrollCapture.scrollTo', <String, Object?>{
        'top': 0,
        'bottom': 100,
      }),
      isNull,
    );
    expect(await _sendScrollCapture(tester, 'ScrollCapture.end'), isNull);
  });

  testWidgets('scrollTo uses the rounded bounds at fractional device pixel ratios', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _buildList(controller: controller, appBar: AppBar(toolbarHeight: 55.3)),
    );

    final bounds =
        (await _sendScrollCapture(tester, 'ScrollCapture.start'))! as Map<String, Object?>;
    final int height = (bounds['bottom']! as int) - (bounds['top']! as int);
    // The area just below the visible area must become exactly visible.
    expect(
      await _sendScrollCapture(tester, 'ScrollCapture.scrollTo', <String, Object?>{
        'top': height,
        'bottom': 2 * height,
      }),
      <String, Object?>{'scrollDelta': height},
    );
    await _sendScrollCapture(tester, 'ScrollCapture.end');
    expect(controller.offset, 0);
  });

  testWidgets('search excludes pinned content at the leading edge', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              const SliverAppBar(pinned: true, title: Text('Pinned')),
              SliverList.builder(
                itemCount: 100,
                itemBuilder: (BuildContext context, int index) =>
                    SizedBox(height: 50, child: Text('Item $index')),
              ),
            ],
          ),
        ),
      ),
    );

    final Rect scrollable = tester.getRect(find.byType(Scrollable));
    final double pinnedHeight = tester.getSize(find.byType(AppBar)).height;
    expect(await _sendScrollCapture(tester, 'ScrollCapture.search'), <String, Object?>{
      'left': scrollable.left.round(),
      'top': (scrollable.top + pinnedHeight).round(),
      'right': scrollable.right.round(),
      'bottom': scrollable.bottom.round(),
    });
  });

  testWidgets('search ignores page views and list wheels', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: 10,
          itemBuilder: (BuildContext context, int index) => Text('Page $index'),
        ),
      ),
    );
    expect(await _sendScrollCapture(tester, 'ScrollCapture.search'), isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: ListWheelScrollView(
          itemExtent: 50,
          children: List<Widget>.generate(100, (int index) => Text('Item $index')),
        ),
      ),
    );
    expect(await _sendScrollCapture(tester, 'ScrollCapture.search'), isNull);
  });

  testWidgets('search ignores the scrollables of a NestedScrollView', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) => <Widget>[
            const SliverAppBar(expandedHeight: 200, title: Text('Header')),
          ],
          body: ListView.builder(
            itemExtent: 50,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) => Text('Item $index'),
          ),
        ),
      ),
    );
    expect(await _sendScrollCapture(tester, 'ScrollCapture.search'), isNull);
  });

  testWidgets('search ignores transformed scrollables', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Transform.scale(scale: 0.5, child: _buildList())));
    expect(await _sendScrollCapture(tester, 'ScrollCapture.search'), isNull);
  });

  testWidgets('start restores the scroll offset of a session that was not ended', (
    WidgetTester tester,
  ) async {
    final controller = ScrollController(initialScrollOffset: 500);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_buildList(controller: controller));

    expect(await _sendScrollCapture(tester, 'ScrollCapture.start'), isNotNull);
    await _sendScrollCapture(tester, 'ScrollCapture.scrollTo', <String, Object?>{
      'top': 2000,
      'bottom': 2500,
    });
    expect(controller.offset, isNot(500));

    expect(await _sendScrollCapture(tester, 'ScrollCapture.start'), isNotNull);
    expect(controller.offset, 500);
    await _sendScrollCapture(tester, 'ScrollCapture.end');
    expect(controller.offset, 500);
  });

  testWidgets('scrollTo returns null and end restores when frames are disabled', (
    WidgetTester tester,
  ) async {
    final controller = ScrollController(initialScrollOffset: 500);
    addTearDown(controller.dispose);
    await tester.pumpWidget(_buildList(controller: controller));
    expect(await _sendScrollCapture(tester, 'ScrollCapture.start'), isNotNull);
    await _sendScrollCapture(tester, 'ScrollCapture.scrollTo', <String, Object?>{
      'top': 2000,
      'bottom': 2500,
    });

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    addTearDown(() => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    expect(tester.binding.framesEnabled, isFalse);
    expect(
      await _sendScrollCapture(tester, 'ScrollCapture.scrollTo', <String, Object?>{
        'top': 0,
        'bottom': 100,
      }),
      isNull,
    );
    await _sendScrollCapture(tester, 'ScrollCapture.end');
    expect(controller.offset, 500);
  });
}
