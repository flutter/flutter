// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  test('Verify that a tap dismisses a modal BottomSheet', () {
    testWidgets((WidgetTester tester) {
      BuildContext savedContext;
      bool showBottomSheetThenCalled = false;

      tester.pumpWidget(new MaterialApp(
        home: new Builder(
          builder: (BuildContext context) {
            savedContext = context;
            return new Container();
          }
        )
      ));

      tester.pump();
      expect(tester, doesNotHaveWidget(find.text('BottomSheet')));

      showModalBottomSheet/*<Null>*/(
        context: savedContext,
        builder: (BuildContext context) => new Text('BottomSheet')
      ).then((Null result) {
        expect(result, isNull);
        showBottomSheetThenCalled = true;
      });

      tester.pump(); // bottom sheet show animation starts
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester, hasWidget(find.text('BottomSheet')));
      expect(showBottomSheetThenCalled, isFalse);

      // Tap on the the bottom sheet itself to dismiss it
      tester.tap(find.text('BottomSheet'));
      tester.pump(); // bottom sheet dismiss animation starts
      expect(showBottomSheetThenCalled, isTrue);
      tester.pump(new Duration(seconds: 1)); // last frame of animation (sheet is entirely off-screen, but still present)
      tester.pump(new Duration(seconds: 1)); // frame after the animation (sheet has been removed)
      expect(tester, doesNotHaveWidget(find.text('BottomSheet')));

      showModalBottomSheet/*<Null>*/(context: savedContext, builder: (BuildContext context) => new Text('BottomSheet'));
      tester.pump(); // bottom sheet show animation starts
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester, hasWidget(find.text('BottomSheet')));

      // Tap above the the bottom sheet to dismiss it
      tester.tapAt(new Point(20.0, 20.0));
      tester.pump(); // bottom sheet dismiss animation starts
      tester.pump(new Duration(seconds: 1)); // animation done
      tester.pump(new Duration(seconds: 1)); // rebuild frame
      expect(tester, doesNotHaveWidget(find.text('BottomSheet')));
    });
  });

  test('Verify that a downwards fling dismisses a persistent BottomSheet', () {
    testWidgets((WidgetTester tester) {
      GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
      bool showBottomSheetThenCalled = false;

      tester.pumpWidget(new MaterialApp(
        home: new Scaffold(
          key: scaffoldKey,
          body: new Center(child: new Text('body'))
        )
      ));

      expect(showBottomSheetThenCalled, isFalse);
      expect(tester, doesNotHaveWidget(find.text('BottomSheet')));

      scaffoldKey.currentState.showBottomSheet((BuildContext context) {
        return new Container(
          margin: new EdgeInsets.all(40.0),
          child: new Text('BottomSheet')
        );
      }).closed.then((_) {
        showBottomSheetThenCalled = true;
      });

      expect(showBottomSheetThenCalled, isFalse);
      expect(tester, doesNotHaveWidget(find.text('BottomSheet')));

      tester.pump(); // bottom sheet show animation starts

      expect(showBottomSheetThenCalled, isFalse);
      expect(tester, hasWidget(find.text('BottomSheet')));

      tester.pump(new Duration(seconds: 1)); // animation done

      expect(showBottomSheetThenCalled, isFalse);
      expect(tester, hasWidget(find.text('BottomSheet')));

      tester.fling(find.text('BottomSheet'), const Offset(0.0, 20.0), 1000.0);
      tester.pump(); // drain the microtask queue (Future completion callback)

      expect(showBottomSheetThenCalled, isTrue);
      expect(tester, hasWidget(find.text('BottomSheet')));

      tester.pump(); // bottom sheet dismiss animation starts

      expect(showBottomSheetThenCalled, isTrue);
      expect(tester, hasWidget(find.text('BottomSheet')));

      tester.pump(new Duration(seconds: 1)); // animation done

      expect(showBottomSheetThenCalled, isTrue);
      expect(tester, doesNotHaveWidget(find.text('BottomSheet')));
    });
  });

}
