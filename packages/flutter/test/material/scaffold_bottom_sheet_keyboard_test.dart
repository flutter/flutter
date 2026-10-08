// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The Scaffold's persistent bottom sheet is _StandardBottomSheet -> BottomSheet
  // -> Material. This finds that Material.
  Finder sheetMaterial() =>
      find.descendant(of: find.byType(BottomSheet), matching: find.byType(Material)).first;

  Widget buildApp({
    required double keyboardHeight,
    bool resizeToAvoidBottomInset = true,
    Widget? bottomNavigationBar,
    Widget? floatingActionButton,
    FloatingActionButtonLocation? floatingActionButtonLocation,
    Widget? bottomSheet,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: keyboardHeight)),
        child: Scaffold(
          backgroundColor: Colors.blue,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          bottomSheet:
              bottomSheet ??
              const SizedBox(
                key: Key('content'),
                width: double.infinity,
                height: 100.0,
                child: Text('sheet'),
              ),
        ),
      ),
    );
  }

  testWidgets('persistent sheet Material extends behind the keyboard, content stays above', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp(keyboardHeight: 0.0));
    expect(tester.getRect(find.byKey(const Key('content'))).top, 500);
    expect(tester.getRect(find.byKey(const Key('content'))).bottom, 600);
    expect(tester.getRect(sheetMaterial()).top, 500);
    expect(tester.getRect(sheetMaterial()).bottom, 600);

    await tester.pumpWidget(buildApp(keyboardHeight: 200.0));
    // Content avoids the keyboard exactly as before.
    expect(tester.getRect(find.byKey(const Key('content'))).top, 300);
    expect(tester.getRect(find.byKey(const Key('content'))).bottom, 400);
    // The sheet's own Material now continues to the bottom of the screen.
    expect(tester.getRect(sheetMaterial()).top, 300);
    expect(tester.getRect(sheetMaterial()).bottom, 600);
  });

  testWidgets('resizeToAvoidBottomInset: false is unchanged', (WidgetTester tester) async {
    await tester.pumpWidget(buildApp(keyboardHeight: 200.0, resizeToAvoidBottomInset: false));
    expect(tester.getRect(find.byKey(const Key('content'))).top, 500);
    expect(tester.getRect(find.byKey(const Key('content'))).bottom, 600);
    expect(tester.getRect(sheetMaterial()).top, 500);
    expect(tester.getRect(sheetMaterial()).bottom, 600);
  });

  testWidgets('sheet Material stops above a bottomNavigationBar', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildApp(keyboardHeight: 200.0, bottomNavigationBar: const SizedBox(height: 50.0)),
    );
    expect(tester.getRect(find.byKey(const Key('content'))).top, 300);
    expect(tester.getRect(find.byKey(const Key('content'))).bottom, 400);
    // Extends down to the top of the bottom navigation bar, not past it.
    expect(tester.getRect(sheetMaterial()).top, 300);
    expect(tester.getRect(sheetMaterial()).bottom, 550);
  });

  testWidgets('docked FAB still straddles the top edge of the sheet content', (
    WidgetTester tester,
  ) async {
    Future<double> fabCenterY() async => tester.getCenter(find.byType(FloatingActionButton)).dy;

    await tester.pumpWidget(
      buildApp(
        keyboardHeight: 0.0,
        floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
    expect(await fabCenterY(), 500.0);

    await tester.pumpWidget(
      buildApp(
        keyboardHeight: 200.0,
        floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
    await tester.pumpAndSettle();
    // Top of the content (300), not the top of the extended Material.
    expect(await fabCenterY(), 300.0);
  });

  testWidgets('keyboard appearing preserves the sheet content state and focus', (
    WidgetTester tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final Widget sheet = SizedBox(height: 100.0, child: TextField(focusNode: focusNode));
    await tester.pumpWidget(buildApp(keyboardHeight: 0.0, bottomSheet: sheet));
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    final State before = tester.state(find.byType(EditableText));

    await tester.pumpWidget(buildApp(keyboardHeight: 200.0, bottomSheet: sheet));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    expect(tester.state(find.byType(EditableText)), same(before));
  });

  testWidgets('showBottomSheet sheet can still be flung closed with the keyboard up', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 200.0)),
          child: Scaffold(key: scaffoldKey, body: const SizedBox.expand()),
        ),
      ),
    );
    scaffoldKey.currentState!.showBottomSheet(
      (BuildContext context) => const SizedBox(height: 100.0, child: Text('sheet')),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('sheet')).bottom, 400.0);
    expect(tester.getRect(sheetMaterial()).bottom, 600.0);

    await tester.fling(find.text('sheet'), const Offset(0.0, 300.0), 2000.0);
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);
  });

  testWidgets('showBottomSheet drag-to-close threshold is measured against the content, '
      'not the Material behind the keyboard', (WidgetTester tester) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 200.0)),
          child: Scaffold(key: scaffoldKey, body: const SizedBox.expand()),
        ),
      ),
    );
    scaffoldKey.currentState!.showBottomSheet(
      (BuildContext context) => const SizedBox(height: 200.0, child: Text('sheet')),
    );
    await tester.pumpAndSettle();
    // Content is 200 tall; the Material behind it is 400 tall.
    expect(tester.getRect(find.text('sheet')).top, 200.0);
    expect(tester.getRect(sheetMaterial()).height, 400.0);

    // Less than half of the content height: springs back open.
    await tester.drag(find.text('sheet'), const Offset(0.0, 60.0));
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget);
    expect(tester.getRect(find.text('sheet')).top, 200.0);

    // More than half of the content height (but less than half of the
    // Material's height): closes, exactly as it does without a keyboard.
    await tester.drag(find.text('sheet'), const Offset(0.0, 150.0));
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);
  });

  testWidgets('constraints.maxHeight bounds the content, not the Material behind the keyboard', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 200.0)),
          child: Scaffold(key: scaffoldKey, body: const SizedBox.expand()),
        ),
      ),
    );
    scaffoldKey.currentState!.showBottomSheet(
      (BuildContext context) => const SizedBox(height: 400.0, child: Text('sheet')),
      constraints: const BoxConstraints(maxHeight: 250.0),
    );
    await tester.pumpAndSettle();
    // The content gets the full 250 it is allowed, above the keyboard.
    expect(tester.getRect(find.text('sheet')).top, 150.0);
    expect(tester.getRect(find.text('sheet')).bottom, 400.0);
    // The Material is 250 + 200.
    expect(tester.getRect(sheetMaterial()).top, 150.0);
    expect(tester.getRect(sheetMaterial()).bottom, 600.0);
  });

  testWidgets('BottomSheet.bottomInset extends the Material below the content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.bottomCenter,
          child: BottomSheet(
            bottomInset: 100.0,
            enableDrag: false,
            onClosing: () {},
            builder: (BuildContext context) =>
                const SizedBox(width: double.infinity, height: 150.0, child: Text('content')),
          ),
        ),
      ),
    );
    expect(tester.getRect(find.text('content')).top, 350.0);
    expect(tester.getRect(find.text('content')).bottom, 500.0);
    expect(tester.getRect(sheetMaterial()).top, 350.0);
    expect(tester.getRect(sheetMaterial()).bottom, 600.0);

    expect(
      () => BottomSheet(
        bottomInset: -1.0,
        onClosing: () {},
        builder: (BuildContext context) => const SizedBox(),
      ),
      throwsAssertionError,
    );
  });

  testWidgets('taps in the Material behind the keyboard do not reach the content', (
    WidgetTester tester,
  ) async {
    var tapCount = 0;
    await tester.pumpWidget(
      buildApp(
        keyboardHeight: 200.0,
        bottomSheet: SizedBox(
          height: 100.0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => tapCount += 1,
            child: const Text('sheet'),
          ),
        ),
      ),
    );
    expect(tester.getRect(find.text('sheet')).bottom, 400.0);
    expect(tester.getRect(sheetMaterial()).bottom, 600.0);

    // Inside the content.
    await tester.tapAt(const Offset(400.0, 350.0));
    expect(tapCount, 1);

    // In the inset region, which only the keyboard can reach: the sheet's
    // Material absorbs the tap (as the Scaffold's own Material did before it
    // was covered), and the content is not hit.
    await tester.tapAt(const Offset(400.0, 500.0));
    expect(tapCount, 1);
  });

  testWidgets('a Scaffold shorter than the keyboard inset keeps the sheet inside its bounds', (
    WidgetTester tester,
  ) async {
    // A 250px tall Scaffold centered on the 600px screen, so it spans y 175..425.
    Widget buildNested(double keyboardHeight) {
      return MaterialApp(
        theme: ThemeData(
          bottomSheetTheme: const BottomSheetThemeData(
            constraints: BoxConstraints.tightFor(height: 150.0),
          ),
        ),
        home: MediaQuery(
          data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: keyboardHeight)),
          child: const Center(
            child: SizedBox(
              width: 320.0,
              height: 250.0,
              child: Scaffold(
                body: SizedBox.expand(),
                bottomSheet: SizedBox.expand(key: Key('content')),
              ),
            ),
          ),
        ),
      );
    }

    for (final keyboardHeight in <double>[0.0, 200.0, 400.0, 0.0]) {
      await tester.pumpWidget(buildNested(keyboardHeight));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // The content gets whatever is left above the keyboard, at most the
      // theme's 150, exactly as before.
      expect(
        tester.getSize(find.byKey(const Key('content'))).height,
        math.min(150.0, math.max(0.0, 250.0 - keyboardHeight)),
      );
      // The Material always ends at the Scaffold's bottom edge and never
      // leaves the Scaffold, without any clipping.
      expect(tester.getRect(sheetMaterial()).bottom, 425.0);
      expect(tester.getRect(sheetMaterial()).top, greaterThanOrEqualTo(175.0));
    }
  });

  testWidgets('showModalBottomSheet is unaffected', (WidgetTester tester) async {
    // A 200 logical pixel keyboard, visible to the modal route as well.
    tester.view.viewInsets = FakeViewPadding(bottom: 200.0 * tester.view.devicePixelRatio);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) =>
                        const SizedBox(height: 100.0, child: Text('modal')),
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Modal sheets manage their own keyboard avoidance; they get no inset.
    expect(tester.widget<BottomSheet>(find.byType(BottomSheet)).bottomInset, 0.0);
    expect(tester.getRect(sheetMaterial()).height, 100.0);
    expect(tester.getRect(sheetMaterial()).bottom, 600.0);
  });

  testWidgets('a BottomSheet passed as Scaffold.bottomSheet is not extended twice', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        keyboardHeight: 200.0,
        bottomSheet: BottomSheet(
          enableDrag: false,
          onClosing: () {},
          builder: (BuildContext context) =>
              const SizedBox(key: Key('content'), width: double.infinity, height: 100.0),
        ),
      ),
    );
    final Finder sheets = find.byType(BottomSheet);
    expect(sheets, findsNWidgets(2));
    Finder materialOf(Finder sheet) =>
        find.descendant(of: sheet, matching: find.byType(Material)).first;

    // Only the Scaffold's own sheet carries the inset. The user's sheet, and
    // its Material, end with the content.
    expect(tester.widget<BottomSheet>(sheets.first).bottomInset, 200.0);
    expect(tester.widget<BottomSheet>(sheets.last).bottomInset, 0.0);
    expect(tester.getRect(find.byKey(const Key('content'))).bottom, 400.0);
    expect(tester.getRect(materialOf(sheets.first)).bottom, 600.0);
    expect(tester.getRect(materialOf(sheets.last)).bottom, 400.0);
  });
}
