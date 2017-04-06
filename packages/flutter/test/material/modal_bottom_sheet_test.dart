// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Verify that a tap dismisses a modal BottomSheet', (WidgetTester tester) async {
    BuildContext savedContext;

    await tester.pumpWidget(new MaterialApp(
      home: new Builder(
        builder: (BuildContext context) {
          savedContext = context;
          return new Container();
        }
      )
    ));

    await tester.pump();
    expect(find.text('BottomSheet'), findsNothing);

    bool showBottomSheetThenCalled = false;
    showModalBottomSheet<Null>(
      context: savedContext,
      builder: (BuildContext context) => const Text('BottomSheet')
    ).then<Null>((Null result) {
      expectSync(result, isNull);
      showBottomSheetThenCalled = true;
    });

    await tester.pump(); // bottom sheet show animation starts
    await tester.pump(const Duration(seconds: 1)); // animation done
    expect(find.text('BottomSheet'), findsOneWidget);
    expect(showBottomSheetThenCalled, isFalse);

    // Tap on the the bottom sheet itself to dismiss it
    await tester.tap(find.text('BottomSheet'));
    await tester.pump(); // bottom sheet dismiss animation starts
    expect(showBottomSheetThenCalled, isTrue);
    await tester.pump(const Duration(seconds: 1)); // last frame of animation (sheet is entirely off-screen, but still present)
    await tester.pump(const Duration(seconds: 1)); // frame after the animation (sheet has been removed)
    expect(find.text('BottomSheet'), findsNothing);

    showBottomSheetThenCalled = false;
    showModalBottomSheet<Null>(
      context: savedContext,
      builder: (BuildContext context) => const Text('BottomSheet'),
    ).then<Null>((Null result) {
      expectSync(result, isNull);
      showBottomSheetThenCalled = true;
    });
    await tester.pump(); // bottom sheet show animation starts
    await tester.pump(const Duration(seconds: 1)); // animation done
    expect(find.text('BottomSheet'), findsOneWidget);
    expect(showBottomSheetThenCalled, isFalse);

    // Tap above the the bottom sheet to dismiss it
    await tester.tapAt(const Offset(20.0, 20.0));
    await tester.pump(); // bottom sheet dismiss animation starts
    expect(showBottomSheetThenCalled, isTrue);
    await tester.pump(const Duration(seconds: 1)); // animation done
    await tester.pump(const Duration(seconds: 1)); // rebuild frame
    expect(find.text('BottomSheet'), findsNothing);
  });

  testWidgets('Verify that a downwards fling dismisses a persistent BottomSheet', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
    bool showBottomSheetThenCalled = false;

    await tester.pumpWidget(new MaterialApp(
      home: new Scaffold(
        key: scaffoldKey,
        body: const Center(child: const Text('body'))
      )
    ));

    expect(showBottomSheetThenCalled, isFalse);
    expect(find.text('BottomSheet'), findsNothing);

    scaffoldKey.currentState.showBottomSheet<Null>((BuildContext context) {
      return new Container(
        margin: const EdgeInsets.all(40.0),
        child: const Text('BottomSheet')
      );
    }).closed.whenComplete(() {
      showBottomSheetThenCalled = true;
    });

    expect(showBottomSheetThenCalled, isFalse);
    expect(find.text('BottomSheet'), findsNothing);

    await tester.pump(); // bottom sheet show animation starts

    expect(showBottomSheetThenCalled, isFalse);
    expect(find.text('BottomSheet'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1)); // animation done

    expect(showBottomSheetThenCalled, isFalse);
    expect(find.text('BottomSheet'), findsOneWidget);

    await tester.fling(find.text('BottomSheet'), const Offset(0.0, 30.0), 1000.0);
    await tester.pump(); // drain the microtask queue (Future completion callback)

    expect(showBottomSheetThenCalled, isTrue);
    expect(find.text('BottomSheet'), findsOneWidget);

    await tester.pump(); // bottom sheet dismiss animation starts

    expect(showBottomSheetThenCalled, isTrue);
    expect(find.text('BottomSheet'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1)); // animation done

    expect(showBottomSheetThenCalled, isTrue);
    expect(find.text('BottomSheet'), findsNothing);
  });

  testWidgets('Verify that dragging past the bottom dismisses a persistent BottomSheet', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/5528
    final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

    await tester.pumpWidget(new MaterialApp(
      home: new Scaffold(
        key: scaffoldKey,
        body: const Center(child: const Text('body'))
      )
    ));

    scaffoldKey.currentState.showBottomSheet<Null>((BuildContext context) {
      return new Container(
        margin: const EdgeInsets.all(40.0),
        child: const Text('BottomSheet')
      );
    });

    await tester.pump(); // bottom sheet show animation starts
    await tester.pump(const Duration(seconds: 1)); // animation done
    expect(find.text('BottomSheet'), findsOneWidget);

    await tester.fling(find.text('BottomSheet'), const Offset(0.0, 400.0), 1000.0);
    await tester.pump(); // drain the microtask queue (Future completion callback)
    await tester.pump(); // bottom sheet dismiss animation starts
    await tester.pump(const Duration(seconds: 1)); // animation done

    expect(find.text('BottomSheet'), findsNothing);
  });
}
