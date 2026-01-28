import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Verifies that the pre-test message shown by flutter_test
  /// meets the minimum WCAG text contrast accessibility guideline.
  testWidgets('pre-test message meets text contrast guideline', (WidgetTester tester) async {
    // Pump the pre-test message widget.
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Text(
            'Test starting...',
            style: TextStyle(color: Color(0xFF8F7FFF), fontSize: 40.0),
          ),
        ),
      ),
    );

    // Verify the widget meets the text contrast accessibility guideline.
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
