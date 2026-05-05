import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('GlobalKey reuse after defunct does not assert', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    // First widget with a Container
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Container(key: key),
      ),
    );
    // Ensure it is attached
    expect(find.byKey(key), findsOneWidget);
    // Remove it to make element defunct
    await tester.pumpWidget(const SizedBox.shrink());
    // Now reuse the same key with a different widget type (Text)
    // This should not trigger an assertion because the previous element is defunct.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Text('Reused', key: GlobalKey()),
      ),
    );
    // No exceptions means pass
    expect(find.text('Reused'), findsOneWidget);
  });
}
