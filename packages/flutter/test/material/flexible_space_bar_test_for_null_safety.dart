import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlexibleSpaceBar', () {
    testWidgets('handles null color in titleStyle without throwing exception', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  expandedHeight: 200.0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text('Test Title'),
                    centerTitle: true,
                    collapseMode: CollapseMode.pin,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Initial state
      expect(find.text('Test Title'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Scroll to collapse the app bar
      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, -200.0));
      await tester.pump();

      // Check after scrolling
      expect(find.text('Test Title'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Scroll back to expand the app bar
      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, 200.0));
      await tester.pump();

      // Check after scrolling back
      expect(find.text('Test Title'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('applies opacity to title color correctly', (WidgetTester tester) async {
      final Key titleKey = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  expandedHeight: 200.0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text('Test Title', key: titleKey),
                    centerTitle: true,
                    collapseMode: CollapseMode.pin,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      Text getText() => tester.widget<Text>(find.byKey(titleKey));

      // Initial state (fully expanded)
      expect(getText().style!.color!.opacity, equals(1.0));

      // Scroll to partially collapse the app bar
      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, -100.0));
      await tester.pump();

      // Check that opacity has changed
      expect(getText().style!.color!.opacity, lessThan(1.0));
      expect(getText().style!.color!.opacity, greaterThan(0.0));

      // Scroll to fully collapse the app bar
      await tester.drag(find.byType(CustomScrollView), const Offset(0.0, -100.0));
      await tester.pump();

      // Check that opacity is at its minimum
      expect(getText().style!.color!.opacity, equals(1.0));
    });
  });
}
