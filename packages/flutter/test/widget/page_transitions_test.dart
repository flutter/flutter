// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

import 'test_matchers.dart';

class TestOverlayRoute extends OverlayRoute {
  List<WidgetBuilder> get builders => <WidgetBuilder>[ _build ];
  Widget _build(BuildContext context) => new Text('Overlay');
}

void main() {
  test('Check onstage/offstage handling around transitions', () {
    testWidgets((WidgetTester tester) {
      GlobalKey containerKey1 = new GlobalKey();
      GlobalKey containerKey2 = new GlobalKey();
      final Map<String, RouteBuilder> routes = <String, RouteBuilder>{
        '/': (_) => new Container(key: containerKey1, child: new Text('Home')),
        '/settings': (_) => new Container(key: containerKey2, child: new Text('Settings')),
      };

      tester.pumpWidget(new MaterialApp(routes: routes));

      expect(tester.findText('Home'), isOnStage);
      expect(tester.findText('Settings'), isNull);
      expect(tester.findText('Overlay'), isNull);

      expect(Navigator.canPop(containerKey1.currentContext), isFalse);
      Navigator.pushNamed(containerKey1.currentContext, '/settings');
      expect(Navigator.canPop(containerKey1.currentContext), isTrue);

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

      Navigator.push(containerKey2.currentContext, new TestOverlayRoute());

      tester.pump();

      expect(tester.findText('Home'), isNull);
      expect(tester.findText('Settings'), isOnStage);
      expect(tester.findText('Overlay'), isOnStage);

      tester.pump(const Duration(seconds: 1));

      expect(tester.findText('Home'), isNull);
      expect(tester.findText('Settings'), isOnStage);
      expect(tester.findText('Overlay'), isOnStage);

      expect(Navigator.canPop(containerKey2.currentContext), isTrue);
      Navigator.pop(containerKey2.currentContext);
      tester.pump();

      expect(tester.findText('Home'), isNull);
      expect(tester.findText('Settings'), isOnStage);
      expect(tester.findText('Overlay'), isNull);

      tester.pump(const Duration(seconds: 1));

      expect(tester.findText('Home'), isNull);
      expect(tester.findText('Settings'), isOnStage);
      expect(tester.findText('Overlay'), isNull);

      expect(Navigator.canPop(containerKey2.currentContext), isTrue);
      Navigator.pop(containerKey2.currentContext);
      tester.pump();

      expect(tester.findText('Home'), isOnStage);
      expect(tester.findText('Settings'), isOnStage);
      expect(tester.findText('Overlay'), isNull);

      tester.pump(const Duration(seconds: 1));

      expect(tester.findText('Home'), isOnStage);
      expect(tester.findText('Settings'), isNull);
      expect(tester.findText('Overlay'), isNull);

      expect(Navigator.canPop(containerKey1.currentContext), isFalse);

    });
  });
}
