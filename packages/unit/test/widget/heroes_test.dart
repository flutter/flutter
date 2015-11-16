// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

class TestOverlayRoute extends OverlayRoute {
  List<WidgetBuilder> get builders => <WidgetBuilder>[ _build ];
  Widget _build(BuildContext context) => new Text('Overlay');
}

bool _isOnStage(Element element) {
  expect(element, isNotNull);
  bool result = true;
  element.visitAncestorElements((Element ancestor) {
    if (ancestor.widget is OffStage) {
      result = false;
      return false;
    }
    return true;
  });
  return result;
}

class _IsOnStage extends Matcher {
  const _IsOnStage();
  bool matches(item, Map matchState) => _isOnStage(item);
  Description describe(Description description) => description.add('onstage');
}

class _IsOffStage extends Matcher {
  const _IsOffStage();
  bool matches(item, Map matchState) => !_isOnStage(item);
  Description describe(Description description) => description.add('offstage');
}

const Matcher isOnStage = const _IsOnStage();
const Matcher isOffStage = const _IsOffStage();

void main() {
  test('Can pop ephemeral route without black flash', () {
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
