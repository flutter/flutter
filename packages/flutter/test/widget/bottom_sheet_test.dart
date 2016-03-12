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
      BuildContext context;
      bool showBottomSheetThenCalled = false;

      tester.pumpWidget(new MaterialApp(
          routes: <String, RouteBuilder>{
            '/': (RouteArguments args) {
              context = args.context;
              return new Container();
            }
          }
      ));

      tester.pump();
      expect(tester.findText('BottomSheet'), isNull);

      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) => new Text('BottomSheet')
      ).then((_) {
        showBottomSheetThenCalled = true;
      });

      tester.pump(); // bottom sheet show animation starts
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester.findText('BottomSheet'), isNotNull);
      expect(showBottomSheetThenCalled, isFalse);

      // Tap on the the bottom sheet itself to dismiss it
      tester.tap(tester.findText('BottomSheet'));
      tester.pump(); // bottom sheet dismiss animation starts
      expect(showBottomSheetThenCalled, isTrue);
      tester.pump(new Duration(seconds: 1)); // last frame of animation (sheet is entirely off-screen, but still present)
      tester.pump(new Duration(seconds: 1)); // frame after the animation (sheet has been removed)
      expect(tester.findText('BottomSheet'), isNull);

      showModalBottomSheet(context: context, builder: (BuildContext context) => new Text('BottomSheet'));
      tester.pump(); // bottom sheet show animation starts
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester.findText('BottomSheet'), isNotNull);

      // Tap above the the bottom sheet to dismiss it
      tester.tapAt(new Point(20.0, 20.0));
      tester.pump(); // bottom sheet dismiss animation starts
      tester.pump(new Duration(seconds: 1)); // animation done
      tester.pump(new Duration(seconds: 1)); // rebuild frame
      expect(tester.findText('BottomSheet'), isNull);
    });
  });

  test('Verify that a downwards fling dismisses a persistent BottomSheet', () {
    testWidgets((WidgetTester tester) {
      GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
      bool showBottomSheetThenCalled = false;

      tester.pumpWidget(new MaterialApp(
        routes: <String, RouteBuilder>{
          '/': (RouteArguments args) {
            return new Scaffold(
              key: scaffoldKey,
              body: new Center(child: new Text('body'))
            );
          }
        }
      ));

      expect(showBottomSheetThenCalled, isFalse);
      expect(tester.findText('BottomSheet'), isNull);

      scaffoldKey.currentState.showBottomSheet((BuildContext context) {
        return new Container(
          margin: new EdgeDims.all(40.0),
          child: new Text('BottomSheet')
        );
      }).closed.then((_) {
        showBottomSheetThenCalled = true;
      });

      expect(showBottomSheetThenCalled, isFalse);
      expect(tester.findText('BottomSheet'), isNull);

      tester.pump(); // bottom sheet show animation starts

      expect(showBottomSheetThenCalled, isFalse);
      expect(tester.findText('BottomSheet'), isNotNull);

      tester.pump(new Duration(seconds: 1)); // animation done

      expect(showBottomSheetThenCalled, isFalse);
      expect(tester.findText('BottomSheet'), isNotNull);

      tester.fling(tester.findText('BottomSheet'), const Offset(0.0, 20.0), 1000.0);
      tester.pump(); // drain the microtask queue (Future completion callback)

      expect(showBottomSheetThenCalled, isTrue);
      expect(tester.findText('BottomSheet'), isNotNull);

      tester.pump(); // bottom sheet dismiss animation starts

      expect(showBottomSheetThenCalled, isTrue);
      expect(tester.findText('BottomSheet'), isNotNull);

      tester.pump(new Duration(seconds: 1)); // animation done

      expect(showBottomSheetThenCalled, isTrue);
      expect(tester.findText('BottomSheet'), isNull);
    });
  });

}
