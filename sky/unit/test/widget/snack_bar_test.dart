import 'package:flutter/material.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('SnackBar control test', () {
    testWidgets((WidgetTester tester) {
      String helloSnackBar = 'Hello SnackBar';
      GlobalKey<PlaceholderState> placeholderKey = new GlobalKey<PlaceholderState>();
      Key tapTarget = new Key('tap-target');

      tester.pumpWidget(new MaterialApp(
        routes: <String, RouteBuilder>{
          '/': (RouteArguments args) {
            return new GestureDetector(
              onTap: () {
                showSnackBar(
                  context: args.context,
                  placeholderKey: placeholderKey,
                  content: new Text(helloSnackBar)
                );
              },
              child: new Container(
                decoration: const BoxDecoration(
                  backgroundColor: const Color(0xFF00FF00)
                ),
                child: new Center(
                  key: tapTarget,
                  child: new Placeholder(key: placeholderKey)
                )
              )
            );
          }
        }
      ));

      tester.tap(tester.findElementByKey(tapTarget));

      expect(tester.findText(helloSnackBar), isNull);
      tester.pump();
      expect(tester.findText(helloSnackBar), isNotNull);
    });
  });
}
