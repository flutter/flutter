import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('Verify that a tap dismisses the BottomSheet', () {
    testWidgets((WidgetTester tester) {
      BuildContext context;
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

      showModalBottomSheet(context: context, child: new Text('BottomSheet'));
      tester.pump(); // bottom sheet show animation starts
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester.findText('BottomSheet'), isNotNull);

      // Tap on the the bottom sheet itself to dismiss it
      tester.tap(tester.findText('BottomSheet'));
      tester.pump(); // bottom sheet dismiss animation starts
      tester.pump(new Duration(seconds: 1)); // animation done
      tester.pump(new Duration(seconds: 2)); // rebuild frame
      expect(tester.findText('BottomSheet'), isNull);

      showModalBottomSheet(context: context, child: new Text('BottomSheet'));
      tester.pump(); // bottom sheet show animation starts
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester.findText('BottomSheet'), isNotNull);

      // Tap above the the bottom sheet to dismiss it
      tester.tapAt(new Point(20.0, 20.0));
      tester.pump(); // bottom sheet dismiss animation starts
      tester.pump(new Duration(seconds: 1)); // animation done
      tester.pump(new Duration(seconds: 2)); // rebuild frame
      expect(tester.findText('BottomSheet'), isNull);
    });
  });

}
