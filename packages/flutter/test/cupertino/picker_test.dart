// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('layout', () {
    testWidgets('selected item is in the middle', (WidgetTester tester) async {
      final FixedExtentScrollController controller =
          new FixedExtentScrollController(initialItem: 1);

      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new Align(
            alignment: Alignment.topLeft,
            child: new SizedBox(
              height: 300.0,
              width: 300.0,
              child: new CupertinoPicker(
                scrollController: controller,
                itemExtent: 50.0,
                onSelectedItemChanged: (_) {},
                children: new List<Widget>.generate(3, (int index) {
                  return new Container(
                    height: 50.0,
                    width: 300.0,
                    child: new Text(index.toString()),
                  );
                }),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1')),
        const Offset(0.0, 125.0),
      );

      controller.jumpToItem(0);
      await tester.pump();

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '1')),
        const Offset(0.0, 175.0),
      );
      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')),
        const Offset(0.0, 125.0),
      );
    });
  });

  group('scroll', () {
    testWidgets(
      'scrolling calls onSelectedItemChanged and triggers haptic feedback',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final List<int> selectedItems = <int>[];
        final List<MethodCall> systemCalls = <MethodCall>[];

        SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
          systemCalls.add(methodCall);
        });

        await tester.pumpWidget(
          new Directionality(
            textDirection: TextDirection.ltr,
            child: new CupertinoPicker(
              itemExtent: 100.0,
              onSelectedItemChanged: (int index) { selectedItems.add(index); },
              children: new List<Widget>.generate(100, (int index) {
                return new Center(
                  child: new Container(
                    width: 400.0,
                    height: 100.0,
                    child: new Text(index.toString()),
                  ),
                );
              }),
            ),
          ),
        );

        await tester.drag(find.text('0'), const Offset(0.0, -100.0));
        expect(selectedItems, <int>[1]);
        expect(
          systemCalls.single,
          isMethodCall(
            'HapticFeedback.vibrate',
            arguments: 'HapticFeedbackType.selectionClick',
          ),
        );

        await tester.drag(find.text('0'), const Offset(0.0, 100.0));
        expect(selectedItems, <int>[1, 0]);
        expect(systemCalls, hasLength(2));
        expect(
          systemCalls.last,
          isMethodCall(
            'HapticFeedback.vibrate',
            arguments: 'HapticFeedbackType.selectionClick',
          ),
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'do not trigger haptic effects on non-iOS devices',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final List<int> selectedItems = <int>[];
        final List<MethodCall> systemCalls = <MethodCall>[];

        SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
          systemCalls.add(methodCall);
        });

        await tester.pumpWidget(
          new Directionality(
            textDirection: TextDirection.ltr,
            child: new CupertinoPicker(
              itemExtent: 100.0,
              onSelectedItemChanged: (int index) { selectedItems.add(index); },
              children: new List<Widget>.generate(100, (int index) {
                return new Center(
                  child: new Container(
                    width: 400.0,
                    height: 100.0,
                    child: new Text(index.toString()),
                  ),
                );
              }),
            ),
          ),
        );

        await tester.drag(find.text('0'), const Offset(0.0, -100.0));
        expect(selectedItems, <int>[1]);
        expect(systemCalls, isEmpty);

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('a drag in between items settles back', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final FixedExtentScrollController controller =
          new FixedExtentScrollController(initialItem: 10);
      final List<int> selectedItems = <int>[];

      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new CupertinoPicker(
            scrollController: controller,
            itemExtent: 100.0,
            onSelectedItemChanged: (int index) { selectedItems.add(index); },
            children: new List<Widget>.generate(100, (int index) {
              return new Center(
                child: new Container(
                  width: 400.0,
                  height: 100.0,
                  child: new Text(index.toString()),
                ),
              );
            }),
          ),
        ),
      );

      // Drag it by a bit but not enough to move to the next item.
      await tester.drag(find.text('10'), const Offset(0.0, 30.0));

      // The item that was in the center now moved a bit.
      expect(
        tester.getTopLeft(find.widgetWithText(Container, '10')),
        const Offset(200.0, 280.0),
      );

      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '10')).dy,
        moreOrLessEquals(250.0, epsilon: 0.5),
      );
      expect(selectedItems.isEmpty, true);

      // Drag it by enough to move to the next item.
      await tester.drag(find.text('10'), const Offset(0.0, 70.0));

      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '10')).dy,
        // It's down by 100.0 now.
        moreOrLessEquals(350.0, epsilon: 0.5),
      );
      expect(selectedItems, <int>[9]);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a big fling that overscrolls springs back', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final FixedExtentScrollController controller =
          new FixedExtentScrollController(initialItem: 10);
      final List<int> selectedItems = <int>[];

      await tester.pumpWidget(
        new Directionality(
          textDirection: TextDirection.ltr,
          child: new CupertinoPicker(
            scrollController: controller,
            itemExtent: 100.0,
            onSelectedItemChanged: (int index) { selectedItems.add(index); },
            children: new List<Widget>.generate(100, (int index) {
              return new Center(
                child: new Container(
                  width: 400.0,
                  height: 100.0,
                  child: new Text(index.toString()),
                ),
              );
            }),
          ),
        ),
      );

      // A wild throw appears.
      await tester.fling(
        find.text('10'),
        const Offset(0.0, 10000.0),
        1000.0,
      );

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')).dy,
        // Should have been flung far enough to go off screen.
        greaterThan(600.0),
      );
      expect(
        selectedItems,
        // This specific throw was fast enough that each scroll update landed
        // on every second item.
        <int>[8, 6, 4, 2, 0],
      );

      // Let it spring back.
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.widgetWithText(Container, '0')).dy,
        // Should have sprung back to the middle now.
        moreOrLessEquals(250.0),
      );
      expect(
        selectedItems,
        // Falling back to 0 shouldn't produce more callbacks.
        <int>[8, 6, 4, 2, 0],
      );

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
