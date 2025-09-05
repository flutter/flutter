// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Border getExpectedHaloBorder() => Border.fromBorderSide(
    BorderSide(
      color: HSLColor.fromColor(CupertinoColors.activeBlue.withOpacity(kCupertinoFocusColorOpacity))
          .withLightness(kCupertinoFocusColorBrightness)
          .withSaturation(kCupertinoFocusColorSaturation)
          .toColor(),
      width: 3.5,
    ),
  );

  BoxBorder? findBorder(GlobalKey groupKey, WidgetTester tester) {
    final Finder groupDecoratedBoxFinder = find.descendant(
      of: find.byKey(groupKey),
      matching: find.byType(DecoratedBox),
    );

    final DecoratedBox box = tester.widget(groupDecoratedBoxFinder) as DecoratedBox;
    final BoxDecoration decoration = box.decoration as BoxDecoration;

    return decoration.border;
  }

  testWidgets(
    'CupertinoTraversalGroup appearance changes correctly with default focus color when focus is changed',
    (WidgetTester tester) async {
      final FocusNode group1Child1FocusNode = FocusNode(debugLabel: 'group1Child1');
      final FocusNode group1Child2FocusNode = FocusNode(debugLabel: 'group1Child2');
      final FocusNode group2Child1FocusNode = FocusNode(debugLabel: 'group2Child1');

      final GlobalKey group1Key = GlobalKey();
      final GlobalKey group2Key = GlobalKey();

      addTearDown(group1Child1FocusNode.dispose);
      addTearDown(group1Child2FocusNode.dispose);
      addTearDown(group2Child1FocusNode.dispose);

      await tester.pumpWidget(
        CupertinoApp(
          home: Column(
            children: <Widget>[
              CupertinoFocusHalo.withRect(
                key: group1Key,
                child: Column(
                  children: <Widget>[
                    Focus(
                      focusNode: group1Child1FocusNode,
                      child: const SizedBox(height: 100, width: 100),
                    ),
                    Focus(
                      focusNode: group1Child2FocusNode,
                      child: const SizedBox(height: 100, width: 100),
                    ),
                  ],
                ),
              ),
              CupertinoFocusHalo.withRect(
                key: group2Key,
                child: Focus(
                  focusNode: group2Child1FocusNode,
                  child: const SizedBox(height: 100, width: 100),
                ),
              ),
            ],
          ),
        ),
      );

      expect(findBorder(group1Key, tester), isNull);
      expect(findBorder(group2Key, tester), isNull);

      group1Child1FocusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(findBorder(group1Key, tester), getExpectedHaloBorder());
      expect(findBorder(group2Key, tester), isNull);

      group1Child2FocusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(findBorder(group1Key, tester), getExpectedHaloBorder());
      expect(findBorder(group2Key, tester), isNull);

      group2Child1FocusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(findBorder(group1Key, tester), isNull);
      expect(findBorder(group2Key, tester), getExpectedHaloBorder());

      group2Child1FocusNode.unfocus();
      await tester.pumpAndSettle();

      expect(findBorder(group1Key, tester), isNull);
      expect(findBorder(group2Key, tester), isNull);
    },
  );

  testWidgets(
    'CupertinoTraversalGroup appearance changes correctly with default focus color when focus is traversed',
    (WidgetTester tester) async {
      final FocusNode group1Child1FocusNode = FocusNode(debugLabel: 'group1Child1');
      final FocusNode group1Child2FocusNode = FocusNode(debugLabel: 'group1Child2');
      final FocusNode group2Child1FocusNode = FocusNode(debugLabel: 'group2Child1');

      final GlobalKey group1Key = GlobalKey();
      final GlobalKey group2Key = GlobalKey();

      addTearDown(group1Child1FocusNode.dispose);
      addTearDown(group1Child2FocusNode.dispose);
      addTearDown(group2Child1FocusNode.dispose);

      tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

      await tester.pumpWidget(
        CupertinoApp(
          home: Column(
            children: <Widget>[
              CupertinoFocusHalo.withRect(
                key: group1Key,
                child: Column(
                  children: <Widget>[
                    Focus(
                      focusNode: group1Child1FocusNode,
                      child: const SizedBox(height: 100, width: 100),
                    ),
                    Focus(
                      focusNode: group1Child2FocusNode,
                      child: const SizedBox(height: 100, width: 100),
                    ),
                  ],
                ),
              ),
              CupertinoFocusHalo.withRect(
                key: group2Key,
                child: Focus(
                  focusNode: group2Child1FocusNode,
                  child: const SizedBox(height: 100, width: 100),
                ),
              ),
            ],
          ),
        ),
      );

      expect(findBorder(group1Key, tester), isNull);
      expect(findBorder(group2Key, tester), isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(findBorder(group1Key, tester), getExpectedHaloBorder());
      expect(findBorder(group2Key, tester), isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(findBorder(group1Key, tester), getExpectedHaloBorder());
      expect(findBorder(group2Key, tester), isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(findBorder(group1Key, tester), isNull);
      expect(findBorder(group2Key, tester), getExpectedHaloBorder());
    },
  );
}
