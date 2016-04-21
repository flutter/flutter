// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

class FirstWidget extends StatelessWidget {
  @override
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

class SecondWidget extends StatefulWidget {
  @override
  SecondWidgetState createState() => new SecondWidgetState();
}

class SecondWidgetState extends State<SecondWidget> {
  @override
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

typedef void ExceptionCallback(dynamic exception);

class ThirdWidget extends StatelessWidget {
  ThirdWidget({ this.targetKey, this.onException });

  final Key targetKey;
  final ExceptionCallback onException;

  @override
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
  testWidgets('Can navigator navigate to and from a stateful widget', (WidgetTester tester) {
      final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
        '/': (BuildContext context) => new FirstWidget(),
        '/second': (BuildContext context) => new SecondWidget(),
      };

      tester.pumpWidget(new MaterialApp(routes: routes));

      expect(find.text('X'), findsOneWidget);
      expect(find.text('Y'), findsNothing);

      tester.tap(find.text('X'));
      tester.pump(const Duration(milliseconds: 10));

      expect(find.text('X'), findsOneWidget);
      expect(find.text('Y'), findsOneWidget);

      tester.pump(const Duration(milliseconds: 10));
      tester.pump(const Duration(milliseconds: 10));
      tester.pump(const Duration(seconds: 1));

      tester.tap(find.text('Y'));
      tester.pump(const Duration(milliseconds: 10));
      tester.pump(const Duration(milliseconds: 10));
      tester.pump(const Duration(milliseconds: 10));
      tester.pump(const Duration(seconds: 1));

      expect(find.text('X'), findsOneWidget);
      expect(find.text('Y'), findsNothing);
  });

  testWidgets('Navigator.openTransaction fails gracefully when not found in context', (WidgetTester tester) {
      Key targetKey = new Key('foo');
      dynamic exception;
      Widget widget = new ThirdWidget(
        targetKey: targetKey,
        onException: (dynamic e) {
          exception = e;
        }
      );
      tester.pumpWidget(widget);
      tester.tap(find.byKey(targetKey));
      expect(exception, new isInstanceOf<FlutterError>());
      expect('$exception', startsWith('openTransaction called with a context'));
  });
}
