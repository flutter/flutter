// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:test/test.dart';

import 'test_matchers.dart';
import 'widget_tester.dart';

class TestOverlayRoute extends OverlayRoute {
  List<WidgetBuilder> get builders => <WidgetBuilder>[ _build ];
  Widget _build(BuildContext context) => new Text('Overlay');
}

void main() {
  test('Check onstage/offstage handling around transitions', () {
    testWidgets((WidgetTester tester) {
      GlobalKey containerKey = new GlobalKey();
      final Map<String, RouteBuilder> routes = <String, RouteBuilder>{
        '/': (_) => new Container(key: containerKey, child: new Text('Home')),
        '/settings': (_) => new Container(child: new Text('Settings')),
      };

      tester.pumpWidget(new MaterialApp(routes: routes));

      expect(tester.findText('Home'), isOnStage);
      expect(tester.findText('Settings'), isNull);
      expect(tester.findText('Overlay'), isNull);

      NavigatorState navigator = Navigator.of(containerKey.currentContext);

      navigator.pushNamed('/settings');

      tester.pump();

      expect(tester.findText('Home'), isOnStage);
      expect(tester.findText('Settings'), isOffStage);
      expect(tester.findText('Overlay'), isNull);

      tester.pump(const Duration(milliseconds: 16));

      expect(tester.findText('Home'), isOnStage);
      expect(tester.findText('Settings'), isOnStage);
      expect(tester.findText('Overlay'), isNull);

      tester.pump(const Duration(seconds: 1));

      expect(tester.findText('Home'), isNull);
      expect(tester.findText('Settings'), isOnStage);
      expect(tester.findText('Overlay'), isNull);

      navigator.push(new TestOverlayRoute());

      tester.pump();

      expect(tester.findText('Home'), isNull);
      expect(tester.findText('Settings'), isOnStage);
      expect(tester.findText('Overlay'), isOnStage);

      tester.pump(const Duration(seconds: 1));

      expect(tester.findText('Home'), isNull);
      expect(tester.findText('Settings'), isOnStage);
      expect(tester.findText('Overlay'), isOnStage);

      navigator.pop();
      tester.pump();

      expect(tester.findText('Home'), isNull);
      expect(tester.findText('Settings'), isOnStage);
      expect(tester.findText('Overlay'), isNull);

      tester.pump(const Duration(seconds: 1));

      expect(tester.findText('Home'), isNull);
      expect(tester.findText('Settings'), isOnStage);
      expect(tester.findText('Overlay'), isNull);

      navigator.pop();
      tester.pump();

      expect(tester.findText('Home'), isOnStage);
      expect(tester.findText('Settings'), isOnStage);
      expect(tester.findText('Overlay'), isNull);

      tester.pump(const Duration(seconds: 1));

      expect(tester.findText('Home'), isOnStage);
      expect(tester.findText('Settings'), isNull);
      expect(tester.findText('Overlay'), isNull);

    });
  });
}
