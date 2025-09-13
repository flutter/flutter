import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AM/PM buttons are live regions', (WidgetTester tester) async {
    // Build a simple TimePicker via showTimePicker
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          return TextButton(
            onPressed: () { showTimePicker(context: context, initialTime: const TimeOfDay(hour: 7, minute: 0)); },
            child: const Text('Open'),
          );
        },
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final SemanticsTester semantics = SemanticsTester(tester);
    // Expect AM node has live region flag (12-hour mode)
    expect(
      semantics,
      includesNodeWith(label: 'AM', flags: <SemanticsFlag>[SemanticsFlag.isLiveRegion, SemanticsFlag.isButton]),
    );
    semantics.dispose();
  });
}
