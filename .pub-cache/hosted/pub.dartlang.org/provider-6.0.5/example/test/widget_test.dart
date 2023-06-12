// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:example/main.dart' as example;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (tester) async {
    // Build our app and trigger a frame.

    example.main();

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
  test('Counter toString()', () {
    final counter = example.Counter();

    expect(counter.toString(), '${describeIdentity(counter)}(count: 0)');

    counter.increment();

    expect(counter.toString(), '${describeIdentity(counter)}(count: 1)');
  });
  test('test coverage', () {
    // remove when https://github.com/dart-lang/sdk/issues/38934 is closed
    const example.Count();
    const example.MyHomePage();
  });
}
