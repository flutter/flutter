// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

class FirstComponent extends StatelessComponent {
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/second');
      },
      child: new Container(
        decoration: new BoxDecoration(
          backgroundColor: new Color(0xFFFFFF00)
        ),
        child: new Text('X')
      )
    );
  }
}

class SecondComponent extends StatefulComponent {
  SecondComponentState createState() => new SecondComponentState();
}

class SecondComponentState extends State<SecondComponent> {
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: () => Navigator.pop(context),
      child: new Container(
        decoration: new BoxDecoration(
          backgroundColor: new Color(0xFFFF00FF)
        ),
        child: new Text('Y')
      )
    );
  }
}

typedef void ExceptionCallback(exception);

class ThirdComponent extends StatelessComponent {
  ThirdComponent({ this.targetKey, this.onException });

  final Key targetKey;
  final ExceptionCallback onException;

  Widget build(BuildContext context) {
    return new GestureDetector(
      key: targetKey,
      onTap: () {
        try {
          Navigator.openTransaction(context, (_) { });
        } catch (e) {
          onException(e);
        }
      },
      behavior: HitTestBehavior.opaque
    );
  }
}

void main() {
  test('Can navigator navigate to and from a stateful component', () {
    testWidgets((WidgetTester tester) {
      final Map<String, RouteBuilder> routes = <String, RouteBuilder>{
        '/': (RouteArguments args) => new FirstComponent(),
        '/second': (RouteArguments args) => new SecondComponent(),
      };

      tester.pumpWidget(new MaterialApp(routes: routes));

      expect(tester.findText('X'), isNotNull);
      expect(tester.findText('Y'), isNull);

      tester.tap(tester.findText('X'));
      tester.pump(const Duration(milliseconds: 10));

      expect(tester.findText('X'), isNotNull);
      expect(tester.findText('Y'), isNotNull);

      tester.pump(const Duration(milliseconds: 10));
      tester.pump(const Duration(milliseconds: 10));
      tester.pump(const Duration(seconds: 1));

      tester.tap(tester.findText('Y'));
      tester.pump(const Duration(milliseconds: 10));
      tester.pump(const Duration(milliseconds: 10));
      tester.pump(const Duration(milliseconds: 10));
      tester.pump(const Duration(seconds: 1));

      expect(tester.findText('X'), isNotNull);
      expect(tester.findText('Y'), isNull);
    });
  });

  test('Navigator.openTransaction fails gracefully when not found in context', () {
    testWidgets((WidgetTester tester) {
      Key targetKey = new Key('foo');
      dynamic exception;
      Widget widget = new ThirdComponent(
        targetKey: targetKey,
        onException: (e) {
          exception = e;
        }
      );
      tester.pumpWidget(widget);
      tester.tap(tester.findElementByKey(targetKey));
      expect(exception, new isInstanceOf<WidgetError>());
      expect('$exception', startsWith('openTransaction called with a context'));
    });
  });
}
