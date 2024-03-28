import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('drags container in MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Draggable<int>(
          data: 42,
          feedback: Container(
            width: 100,
            height: 100,
            color: Colors.blue,
          ),
          child: Container(
            width: 100,
            height: 100,
            color: Colors.red,
          ),
        ),
      ),
    ));

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(Container)));
    await gesture.moveBy(const Offset(100, 100));
    await tester.pump();
    final Finder feedbackFinder = find.byType(Container);
    expect(feedbackFinder, findsNWidgets(2));
    expect(tester.widget<Container>(feedbackFinder.at(1)).color, Colors.blue);
    expect(tester.getTopLeft(feedbackFinder.at(0)), Offset.zero);
    expect(tester.getTopLeft(feedbackFinder.at(1)), const Offset(100, 100));
  });
}
