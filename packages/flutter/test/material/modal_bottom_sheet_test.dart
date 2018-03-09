// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

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

    // Tap on the bottom sheet itself to dismiss it
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

    // Tap above the bottom sheet to dismiss it
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

    // The fling below must be such that the velocity estimation examines an
    // offset greater than the kTouchSlop. Too slow or too short a distance, and
    // it won't trigger. Also, it musn't be so much that it drags the bottom
    // sheet off the screen, or we won't see it after we pump!
    await tester.fling(find.text('BottomSheet'), const Offset(0.0, 50.0), 2000.0);
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

  testWidgets('modal BottomSheet has no top MediaQuery', (WidgetTester tester) async {
    BuildContext outerContext;
    BuildContext innerContext;

    await tester.pumpWidget(new Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: new Directionality(
        textDirection: TextDirection.ltr,
        child: new MediaQuery(
          data: const MediaQueryData(
            padding: const EdgeInsets.all(50.0),
          ),
          child: new Navigator(
            onGenerateRoute: (_) {
              return new PageRouteBuilder<Null>(
                pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
                  outerContext = context;
                  return new Container();
                },
              );
            },
          ),
        ),
      ),
    ));

    showModalBottomSheet<Null>(
      context: outerContext,
      builder: (BuildContext context) {
        innerContext = context;
        return new Container();
      },
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      MediaQuery.of(outerContext).padding,
      const EdgeInsets.all(50.0),
    );
    expect(
      MediaQuery.of(innerContext).padding,
      const EdgeInsets.only(left: 50.0, right: 50.0, bottom: 50.0),
    );
  });
}
