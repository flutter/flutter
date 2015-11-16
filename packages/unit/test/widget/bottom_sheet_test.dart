// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

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

      showModalBottomSheet(context: context, child: new Text('BottomSheet')).then((_) {
        showBottomSheetThenCalled = true;
      });

      tester.pump(); // bottom sheet show animation starts
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester.findText('BottomSheet'), isNotNull);

      // Tap on the the bottom sheet itself to dismiss it
      tester.tap(tester.findText('BottomSheet'));
      tester.pump(); // bottom sheet dismiss animation starts
      tester.pump(new Duration(seconds: 1)); // animation done
      tester.pump(new Duration(seconds: 1)); // rebuild frame
      expect(showBottomSheetThenCalled, isTrue);
      expect(tester.findText('BottomSheet'), isNull);

      showModalBottomSheet(context: context, child: new Text('BottomSheet'));
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
      GlobalKey<PlaceholderState> _bottomSheetPlaceholderKey = new GlobalKey<PlaceholderState>();
      BuildContext context;
      bool showBottomSheetThenCalled = false;

      tester.pumpWidget(new MaterialApp(
          routes: <String, RouteBuilder>{
            '/': (RouteArguments args) {
              context = args.context;
              return new Scaffold(
                bottomSheet: new Placeholder(key: _bottomSheetPlaceholderKey),
                body: new Center(child: new Text('body'))
              );
            }
          }
      ));

      tester.pump();
      expect(tester.findText('BottomSheet'), isNull);

      showBottomSheet(
        context: context,
        child: new Container(child: new Text('BottomSheet'), margin: new EdgeDims.all(40.0)),
        placeholderKey: _bottomSheetPlaceholderKey
      ).then((_) {
        showBottomSheetThenCalled = true;
      });

      expect(_bottomSheetPlaceholderKey.currentState.child, isNotNull);
      tester.pump(); // bottom sheet show animation starts
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester.findText('BottomSheet'), isNotNull);

      tester.fling(tester.findText('BottomSheet'), const Offset(0.0, 20.0), 1000.0);
      tester.pump(); // bottom sheet dismiss animation starts
      tester.pump(new Duration(seconds: 1)); // animation done
      tester.pump(new Duration(seconds: 1)); // rebuild frame without the bottom sheet
      expect(showBottomSheetThenCalled, isTrue);
      expect(tester.findText('BottomSheet'), isNull);
      expect(_bottomSheetPlaceholderKey.currentState.child, isNull);
    });
  });

}
