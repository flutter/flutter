// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_api_samples/widgets/raw_menu_anchor/raw_menu_anchor.3.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

T findMenuPanelDescendent<T extends Widget>(WidgetTester tester) {
  return tester.firstWidget<T>(
    find.descendant(
      of: findMenuPanel(),
      matching: find.byType(T),
    ),
  );
}

Finder findMenuPanel() {
  return find.byType(RawMenuAnchor.debugMenuOverlayPanelType);
}

void main() {
  testWidgets(
      'Initializes with correct number of menu items in expected position',
      (WidgetTester tester) async {
    await tester.pumpWidget(const example.MenuNodeApp());

    expect(find.byType(RawMenuAnchor).evaluate().length, 5);
    expect(
      tester.getRect(find.byType(RawMenuAnchor).first),
      const Rect.fromLTRB(233.0, 284.0, 567.0, 316.0),
    );
  });

  testWidgets('Menu can be traversed', (WidgetTester tester) async {
    await tester.pumpWidget(const example.MenuNodeApp());

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(primaryFocus?.debugLabel, equals('MenuItemButton(Text("File"))'));
    expect(find.text('New'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();

    expect(primaryFocus?.debugLabel, equals('MenuItemButton(Text("File"))'));
    expect(find.text('New'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);

    expect(primaryFocus?.debugLabel, equals('MenuItemButton(Text("Share"))'));
    expect(find.text('Email'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(primaryFocus?.debugLabel, equals('MenuItemButton(Text("Email"))'));
    expect(find.text('Email'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

    expect(
        primaryFocus?.debugLabel, equals('MenuItemButton(Text("Copy Link"))'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();

    expect(primaryFocus?.debugLabel, equals('MenuItemButton(Text("Share"))'));
    expect(find.text('Email'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(primaryFocus?.debugLabel, equals('MenuItemButton(Text("File"))'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(primaryFocus?.debugLabel, equals('MenuItemButton(Text("Tools"))'));

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

    expect(
        primaryFocus?.debugLabel, equals('MenuItemButton(Text("Spelling"))'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

    expect(primaryFocus?.debugLabel, equals('MenuItemButton(Text("Grammar"))'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

    expect(
        primaryFocus?.debugLabel, equals('MenuItemButton(Text("Thesaurus"))'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

    expect(
        primaryFocus?.debugLabel, equals('MenuItemButton(Text("Dictionary"))'));

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();

    expect(find.text('Selected: Dictionary'), findsOneWidget);
  });

  testWidgets('Platform Brightness does not affect menu appearance',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(platformBrightness: Brightness.dark),
        child: example.MenuNodeApp(),
      ),
    );

    await tester.tap(find.text('File'));
    await tester.pump();
    await tester.pump();

    expect(find.text('New'), findsOneWidget);
    expect(
      findMenuPanelDescendent<Container>(tester).decoration,
      RawMenuAnchor.defaultLightOverlayDecoration,
    );
  });
}
