import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/raw_tooltip/raw_tooltip.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RawTooltip is visible when tapping button', (
    WidgetTester tester,
  ) async {
    const String rawTooltipText = 'I am a RawToolTip message';

    await tester.pumpWidget(const example.RawTooltipExampleApp());

    // RawTooltip is not visible before tapping the button.
    expect(find.text(rawTooltipText), findsNothing);
    // Tap on the button and wait for the rawTooltip to appear.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(rawTooltipText), findsOneWidget);
    // Tap anywhere and wait for the rawTooltip to disappear.
    await tester.tap(find.byType(Scaffold));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(rawTooltipText), findsNothing);
  });
}