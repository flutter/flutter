// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {

  test('Drawer control test', () {
    testWidgets((WidgetTester tester) {
      BuildContext context;
      tester.pumpWidget(
        new MaterialApp(
          routes: <String, RouteBuilder>{
            '/': (RouteArguments args) {
              context = args.context;
              return new Container();
            }
          }
        )
      );
      tester.pump(); // no effect
      expect(tester.findText('drawer'), isNull);
      showDrawer(context: context, child: new Text('drawer'));
      tester.pump(); // drawer should be starting to animate in
      expect(tester.findText('drawer'), isNotNull);
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester.findText('drawer'), isNotNull);
      Navigator.pop(context);
      tester.pump(); // drawer should be starting to animate away
      expect(tester.findText('drawer'), isNotNull);
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester.findText('drawer'), isNull);
    });
  });

  test('Drawer tap test', () {
    testWidgets((WidgetTester tester) {
      BuildContext context;
      tester.pumpWidget(new Container()); // throw away the old App and its Navigator
      tester.pumpWidget(
        new MaterialApp(
          routes: <String, RouteBuilder>{
            '/': (RouteArguments args) {
              context = args.context;
              return new Container();
            }
          }
        )
      );
      tester.pump(); // no effect
      expect(tester.findText('drawer'), isNull);
      showDrawer(context: context, child: new Text('drawer'));
      tester.pump(); // drawer should be starting to animate in
      expect(tester.findText('drawer'), isNotNull);
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester.findText('drawer'), isNotNull);
      tester.tap(tester.findText('drawer'));
      tester.pump(); // nothing should have happened
      expect(tester.findText('drawer'), isNotNull);
      tester.pump(new Duration(seconds: 1)); // ditto
      expect(tester.findText('drawer'), isNotNull);
      tester.tapAt(const Point(750.0, 100.0)); // on the mask
      tester.pump(); // drawer should be starting to animate away
      expect(tester.findText('drawer'), isNotNull);
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester.findText('drawer'), isNull);
    });
  });

}
