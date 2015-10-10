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
        routes: {
          '/': (RouteArguments args) {
            return new GestureDetector(
              onTap: () {
                showSnackBar(
                  navigator: args.navigator,
                  placeholderKey: placeholderKey,
                  content: new Text(helloSnackBar)
                );
              },
              child: new Center(
                key: tapTarget,
                child: new Placeholder(key: placeholderKey)
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
