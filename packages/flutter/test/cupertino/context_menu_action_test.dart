// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Constants taken from _ContextMenuActionState.
  const kBackgroundColor = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFF1F1F1),
    darkColor: Color(0xFF212122),
  );
  const kBackgroundColorPressed = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFDDDDDD),
    darkColor: Color(0xFF3F3F40),
  );
  const Color kDestructiveActionColor = CupertinoColors.destructiveRed;
  const FontWeight kDefaultActionWeight = FontWeight.w600;

  Widget getApp({
    VoidCallback? onPressed,
    bool isDestructiveAction = false,
    bool isDefaultAction = false,
    Brightness? brightness,
    FocusNode? actionFocusNode,
    Color? actionFocusColor,
  }) {
    final actionKey = UniqueKey();
    final action = CupertinoContextMenuAction(
      key: actionKey,
      onPressed: onPressed,
      trailingIcon: CupertinoIcons.home,
      isDestructiveAction: isDestructiveAction,
      isDefaultAction: isDefaultAction,
      focusNode: actionFocusNode,
      focusColor: actionFocusColor,
      child: const Text('I am a CupertinoContextMenuAction'),
    );

    return CupertinoApp(
      theme: CupertinoThemeData(brightness: brightness ?? Brightness.light),
      home: CupertinoPageScaffold(child: Center(child: action)),
    );
  }

  TextStyle getTextStyle(WidgetTester tester) {
    final Finder finder = find.descendant(
      of: find.byType(CupertinoContextMenuAction),
      matching: find.byType(DefaultTextStyle),
    );
    expect(finder, findsOneWidget);
    final DefaultTextStyle defaultStyle = tester.widget(finder);
    return defaultStyle.style;
  }

  Icon getIcon(WidgetTester tester) {
    final Finder finder = find.descendant(
      of: find.byType(CupertinoContextMenuAction),
      matching: find.byType(Icon),
    );
    expect(finder, findsOneWidget);
    final Icon icon = tester.widget(finder);
    return icon;
  }

  testWidgets('responds to taps', (WidgetTester tester) async {
    var wasPressed = false;
    await tester.pumpWidget(
      getApp(
        onPressed: () {
          wasPressed = true;
        },
      ),
    );

    expect(wasPressed, false);
    await tester.tap(find.byType(CupertinoContextMenuAction));
    expect(wasPressed, true);
  });

  testWidgets('turns grey when pressed and held', (WidgetTester tester) async {
    await tester.pumpWidget(getApp());
    expect(find.byType(CupertinoContextMenuAction), paints..rect(color: kBackgroundColor.color));

    final Offset actionCenterLight = tester.getCenter(find.byType(CupertinoContextMenuAction));
    final TestGesture gestureLight = await tester.startGesture(actionCenterLight);
    await tester.pump();
    expect(
      find.byType(CupertinoContextMenuAction),
      paints..rect(color: kBackgroundColorPressed.color),
    );

    await gestureLight.up();
    await tester.pump();
    expect(find.byType(CupertinoContextMenuAction), paints..rect(color: kBackgroundColor.color));

    await tester.pumpWidget(getApp(brightness: Brightness.dark));
    expect(
      find.byType(CupertinoContextMenuAction),
      paints..rect(color: kBackgroundColor.darkColor),
    );

    final Offset actionCenterDark = tester.getCenter(find.byType(CupertinoContextMenuAction));
    final TestGesture gestureDark = await tester.startGesture(actionCenterDark);
    await tester.pump();
    expect(
      find.byType(CupertinoContextMenuAction),
      paints..rect(color: kBackgroundColorPressed.darkColor),
    );

    await gestureDark.up();
    await tester.pump();
    expect(
      find.byType(CupertinoContextMenuAction),
      paints..rect(color: kBackgroundColor.darkColor),
    );
  });

  testWidgets('changes color when focused', (WidgetTester tester) async {
    final lightDefaultFocusNode = FocusNode();
    final darkDefaultFocusNode = FocusNode();
    final lightCustomFocusNode = FocusNode();
    final darkCustomFocusNode = FocusNode();

    addTearDown(lightDefaultFocusNode.dispose);
    addTearDown(darkDefaultFocusNode.dispose);
    addTearDown(lightCustomFocusNode.dispose);
    addTearDown(darkCustomFocusNode.dispose);

    const Color customFocusColor = Colors.orange;

    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    // Default focus color, light theme
    await tester.pumpWidget(getApp(actionFocusNode: lightDefaultFocusNode, onPressed: () {}));

    expect(find.byType(CupertinoContextMenuAction), paints..rect(color: kBackgroundColor.color));

    lightDefaultFocusNode.requestFocus();
    await tester.pump();

    final Color defaultFocusBackgroundLight = CupertinoColors.activeBlue.withValues(
      alpha: kCupertinoButtonTintedOpacityLight,
    );

    expect(
      find.byType(CupertinoContextMenuAction),
      paints..rect(color: defaultFocusBackgroundLight),
    );

    // Default focus color, dark theme
    await tester.pumpWidget(
      getApp(actionFocusNode: darkDefaultFocusNode, onPressed: () {}, brightness: Brightness.dark),
    );

    expect(
      find.byType(CupertinoContextMenuAction),
      paints..rect(color: kBackgroundColor.darkColor),
    );

    darkDefaultFocusNode.requestFocus();
    await tester.pump();

    final Color defaultFocusBackgroundDark = CupertinoColors.activeBlue.withValues(
      alpha: kCupertinoButtonTintedOpacityDark,
    );

    expect(
      find.byType(CupertinoContextMenuAction),
      paints..rect(color: defaultFocusBackgroundDark),
    );

    // Custom focus color, light theme
    await tester.pumpWidget(
      getApp(
        actionFocusNode: lightCustomFocusNode,
        actionFocusColor: customFocusColor,
        onPressed: () {},
      ),
    );

    expect(find.byType(CupertinoContextMenuAction), paints..rect(color: kBackgroundColor.color));

    lightCustomFocusNode.requestFocus();
    await tester.pump();

    final Color customFocusBackgroundLight = customFocusColor.withValues(
      alpha: kCupertinoButtonTintedOpacityLight,
    );

    expect(
      find.byType(CupertinoContextMenuAction),
      paints..rect(color: customFocusBackgroundLight),
    );

    // Custom focus color, dark theme
    await tester.pumpWidget(
      getApp(
        actionFocusNode: darkCustomFocusNode,
        onPressed: () {},
        actionFocusColor: customFocusColor,
        brightness: Brightness.dark,
      ),
    );

    expect(
      find.byType(CupertinoContextMenuAction),
      paints..rect(color: kBackgroundColor.darkColor),
    );

    darkCustomFocusNode.requestFocus();
    await tester.pump();

    final Color customFocusBackgroundDark = customFocusColor.withValues(
      alpha: kCupertinoButtonTintedOpacityDark,
    );

    expect(find.byType(CupertinoContextMenuAction), paints..rect(color: customFocusBackgroundDark));
  });

  testWidgets('can be traversed and responds to focus action when onPressed is not null', (
    WidgetTester tester,
  ) async {
    final focusNode = FocusNode();

    addTearDown(focusNode.dispose);

    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    var pressed = false;

    await tester.pumpWidget(getApp(actionFocusNode: focusNode, onPressed: () => pressed = true));

    expect(pressed, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(pressed, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(focusNode.hasPrimaryFocus, isTrue);
    expect(pressed, isTrue);
  });

  testWidgets('cannot be traversed when onPressed is null', (WidgetTester tester) async {
    final focusNode = FocusNode();

    addTearDown(focusNode.dispose);

    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    await tester.pumpWidget(getApp(actionFocusNode: focusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(focusNode.hasPrimaryFocus, isFalse);
  });

  testWidgets('cannot be focused when onPressed is null', (WidgetTester tester) async {
    final focusNode = FocusNode();

    addTearDown(focusNode.dispose);

    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;

    await tester.pumpWidget(getApp(actionFocusNode: focusNode));

    focusNode.requestFocus();
    await tester.pump();

    expect(focusNode.hasPrimaryFocus, isFalse);
  });

  testWidgets('icon and textStyle colors are correct out of the box', (WidgetTester tester) async {
    await tester.pumpWidget(getApp());
    expect(getTextStyle(tester).color, CupertinoColors.label);
    expect(getIcon(tester).color, CupertinoColors.label);
  });

  testWidgets('icon and textStyle colors are correct for destructive actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(getApp(isDestructiveAction: true));
    expect(getTextStyle(tester).color, kDestructiveActionColor);
    expect(getIcon(tester).color, kDestructiveActionColor);
  });

  testWidgets('textStyle is correct for defaultAction for Brightness.light', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(getApp(isDefaultAction: true));
    expect(getTextStyle(tester).fontWeight, kDefaultActionWeight);
    final Element context = tester.element(find.byType(CupertinoContextMenuAction));
    // The dynamic color should have been resolved.
    expect(getTextStyle(tester).color, CupertinoColors.label.resolveFrom(context));
  });

  testWidgets('textStyle is correct for defaultAction for Brightness.dark', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/144492.
    await tester.pumpWidget(getApp(isDefaultAction: true, brightness: Brightness.dark));
    expect(getTextStyle(tester).fontWeight, kDefaultActionWeight);
    final Element context = tester.element(find.byType(CupertinoContextMenuAction));
    // The dynamic color should have been resolved.
    expect(getTextStyle(tester).color, CupertinoColors.label.resolveFrom(context));
  });

  testWidgets('Hovering over Cupertino context menu action updates cursor to clickable on Web', (
    WidgetTester tester,
  ) async {
    /// Cupertino context menu action without "onPressed" callback.
    await tester.pumpWidget(getApp());
    final Offset contextMenuAction = tester.getCenter(
      find.text('I am a CupertinoContextMenuAction'),
    );
    final TestGesture gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await gesture.addPointer(location: contextMenuAction);
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.basic,
    );

    // / Cupertino context menu action with "onPressed" callback.
    await tester.pumpWidget(getApp(onPressed: () {}));
    await gesture.moveTo(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.basic,
    );

    await gesture.moveTo(contextMenuAction);
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      kIsWeb ? SystemMouseCursors.click : SystemMouseCursors.basic,
    );
  });
}
