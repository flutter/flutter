import '../rendering/mock_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/src/widget_tester.dart';

void main() {
  testWidgets('Does the ink widget render a border radius', (WidgetTester tester) async {
    final Color highlightColor = new Color(0xAAFF0000);
    final Color splashColor = new Color(0xAA0000FF);

    final Key materialKey = new UniqueKey();
    final Key inkKey = new UniqueKey();
    final BorderRadius borderRadius = new BorderRadius.circular(6.0);

    await tester.pumpWidget(
      new Material(
        key: materialKey,
        child: new Center(
          child: new Container(
            width: 200.0,
            height: 60.0,
            child: new InkWell(
              key: inkKey,
              borderRadius: borderRadius,
              highlightColor: highlightColor,
              splashColor: splashColor,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final Point center = tester.getCenter(find.byKey(materialKey));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(new Duration(milliseconds: 200));

    // TODO(ianh) - stub. needs to be completed.

    await gesture.up();
  });
}