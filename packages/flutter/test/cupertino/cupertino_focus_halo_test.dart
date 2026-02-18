// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

ShapeBorder _getExpectedRectHaloBorder({required bool hasFocus}) =>
    RoundedRectangleBorder(side: _getExpectedBorderSide(hasFocus: hasFocus));

ShapeBorder _getExpectedRRectHaloBorder({
  required bool hasFocus,
  required BorderRadius borderRadius,
}) {
  return RoundedRectangleBorder(
    borderRadius: borderRadius,
    side: _getExpectedBorderSide(hasFocus: hasFocus),
  );
}

ShapeBorder _getExpectedSuperellipseHaloBorder({
  required bool hasFocus,
  required BorderRadius borderRadius,
}) {
  return RoundedSuperellipseBorder(
    borderRadius: borderRadius,
    side: _getExpectedBorderSide(hasFocus: hasFocus),
  );
}

BorderSide _getExpectedBorderSide({required bool hasFocus}) {
  if (!hasFocus) {
    return BorderSide.none;
  }

  return BorderSide(
    color: HSLColor.fromColor(CupertinoColors.activeBlue.withOpacity(kCupertinoFocusColorOpacity))
        .withLightness(kCupertinoFocusColorBrightness)
        .withSaturation(kCupertinoFocusColorSaturation)
        .toColor(),
    width: 3.5,
  );
}

ShapeBorder _findBorder(GlobalKey groupKey, WidgetTester tester) {
  final Finder groupDecoratedBoxFinder = find.descendant(
    of: find.byKey(groupKey),
    matching: find.byType(DecoratedBox),
  );

  final box = tester.widget(groupDecoratedBoxFinder) as DecoratedBox;
  final decoration = box.decoration as ShapeDecoration;

  return decoration.shape;
}

void main() {
  testWidgets(
    'CupertinoTraversalGroup appearance changes correctly with default focus color when focus is changed',
    (WidgetTester tester) async {
      final group1Child1FocusNode = FocusNode(debugLabel: 'group1Child1');
      final group1Child2FocusNode = FocusNode(debugLabel: 'group1Child2');
      final group2Child1FocusNode = FocusNode(debugLabel: 'group2Child1');

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

      expect(_findBorder(group1Key, tester), _getExpectedRectHaloBorder(hasFocus: false));
      expect(_findBorder(group2Key, tester), _getExpectedRectHaloBorder(hasFocus: false));

      group1Child1FocusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(_findBorder(group1Key, tester), _getExpectedRectHaloBorder(hasFocus: true));
      expect(_findBorder(group2Key, tester), _getExpectedRectHaloBorder(hasFocus: false));

      group1Child2FocusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(_findBorder(group1Key, tester), _getExpectedRectHaloBorder(hasFocus: true));
      expect(_findBorder(group2Key, tester), _getExpectedRectHaloBorder(hasFocus: false));

      group2Child1FocusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(_findBorder(group1Key, tester), _getExpectedRectHaloBorder(hasFocus: false));
      expect(_findBorder(group2Key, tester), _getExpectedRectHaloBorder(hasFocus: true));

      group2Child1FocusNode.unfocus();
      await tester.pumpAndSettle();

      expect(_findBorder(group1Key, tester), _getExpectedRectHaloBorder(hasFocus: false));
      expect(_findBorder(group2Key, tester), _getExpectedRectHaloBorder(hasFocus: false));
    },
  );

  testWidgets(
    'CupertinoTraversalGroup appearance changes correctly with default focus color when focus is traversed',
    (WidgetTester tester) async {
      final group1Child1FocusNode = FocusNode(debugLabel: 'group1Child1');
      final group1Child2FocusNode = FocusNode(debugLabel: 'group1Child2');
      final group2Child1FocusNode = FocusNode(debugLabel: 'group2Child1');

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

      expect(_findBorder(group1Key, tester), _getExpectedRectHaloBorder(hasFocus: false));
      expect(_findBorder(group2Key, tester), _getExpectedRectHaloBorder(hasFocus: false));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(_findBorder(group1Key, tester), _getExpectedRectHaloBorder(hasFocus: true));
      expect(_findBorder(group2Key, tester), _getExpectedRectHaloBorder(hasFocus: false));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(_findBorder(group1Key, tester), _getExpectedRectHaloBorder(hasFocus: true));
      expect(_findBorder(group2Key, tester), _getExpectedRectHaloBorder(hasFocus: false));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(_findBorder(group1Key, tester), _getExpectedRectHaloBorder(hasFocus: false));
      expect(_findBorder(group2Key, tester), _getExpectedRectHaloBorder(hasFocus: true));
    },
  );

  testWidgets('CupertinoFocusHalo.withRect draws a correct shape', (WidgetTester tester) async {
    final focusNode = FocusNode();
    final GlobalKey haloKey = GlobalKey();

    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoFocusHalo.withRect(
            key: haloKey,
            child: Focus(focusNode: focusNode, child: const SizedBox(width: 100, height: 50)),
          ),
        ),
      ),
    );

    expect(_findBorder(haloKey, tester), _getExpectedRectHaloBorder(hasFocus: false));

    focusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(_findBorder(haloKey, tester), _getExpectedRectHaloBorder(hasFocus: true));
  });

  testWidgets('CupertinoFocusHalo.withRRect draws a correct shape', (WidgetTester tester) async {
    final focusNode = FocusNode();
    final GlobalKey haloKey = GlobalKey();
    final borderRadius = BorderRadius.circular(12.0);

    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoFocusHalo.withRRect(
            key: haloKey,
            borderRadius: borderRadius,
            child: Focus(focusNode: focusNode, child: const SizedBox(width: 100, height: 50)),
          ),
        ),
      ),
    );

    expect(
      _findBorder(haloKey, tester),
      _getExpectedRRectHaloBorder(hasFocus: false, borderRadius: borderRadius),
    );

    focusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(
      _findBorder(haloKey, tester),
      _getExpectedRRectHaloBorder(hasFocus: true, borderRadius: borderRadius),
    );
  });

  testWidgets('CupertinoFocusHalo.withRoundedSuperellipse draws a correct shape', (
    WidgetTester tester,
  ) async {
    final focusNode = FocusNode();
    final GlobalKey haloKey = GlobalKey();
    final borderRadius = BorderRadius.circular(12.0);

    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoFocusHalo.withRoundedSuperellipse(
            key: haloKey,
            borderRadius: borderRadius,
            child: Focus(focusNode: focusNode, child: const SizedBox(width: 100, height: 50)),
          ),
        ),
      ),
    );

    expect(
      _findBorder(haloKey, tester),
      _getExpectedSuperellipseHaloBorder(hasFocus: false, borderRadius: borderRadius),
    );

    focusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(
      _findBorder(haloKey, tester),
      _getExpectedSuperellipseHaloBorder(hasFocus: true, borderRadius: borderRadius),
    );
  });

  testWidgets('CupertinoFocusHalo does not crash at zero area', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: SizedBox.shrink(
            child: CupertinoFocusHalo.withRect(
              child: Focus(focusNode: focusNode, child: const Text('X')),
            ),
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(CupertinoFocusHalo)), Size.zero);
  });
}
