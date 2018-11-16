import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WidgetsApp with builder only', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      WidgetsApp(
        key: key,
        builder: (BuildContext context, Widget child) {
          return const Placeholder();
        },
        color: const Color(0xFF123456),
      ),
    );
    expect(find.byKey(key), findsOneWidget);
  });

  testWidgets('WidgetsApp can be notified of setInitialRoute changes', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    String initialRouteName = '/';
    await tester.pumpWidget(
      WidgetsApp(
        key: key,
        builder: (BuildContext context, Widget child) {
          return const Placeholder();
        },
        onSetInitialRoute: (String name) => initialRouteName = name,
        color: const Color(0xFF123456),
      ),
    );
    expect(find.byKey(key), findsOneWidget);
    expect(initialRouteName, equals('/'));

    tester.binding.handleSetInitialRoute('/another');
    expect(initialRouteName, equals('/another'));
  });
}
