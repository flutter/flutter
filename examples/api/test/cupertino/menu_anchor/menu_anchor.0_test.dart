import 'package:flutter/cupertino.dart';
// Import the sample app.
import 'package:flutter_api_samples/cupertino/menu_anchor/menu_anchor.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Opens menu and shows all items', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CupertinoMenuAnchorApp());

    await tester.tap(find.text('Open Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Regular Item'), findsOneWidget);
    expect(find.text('Colorful Item'), findsOneWidget);
    expect(find.text('Destructive Item'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.delete), findsOneWidget);
  });

  testWidgets('Selecting each item updates the pressed label', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CupertinoMenuAnchorApp());

    // Regular Item
    await tester.tap(find.text('Open Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Regular Item'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('You Pressed: Regular Item'), findsOneWidget);

    // Colorful Item
    await tester.tap(find.text('Open Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Colorful Item'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('You Pressed: Colorful Item'), findsOneWidget);

    // Destructive Item
    await tester.tap(find.text('Open Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Destructive Item'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('You Pressed: Destructive Item'), findsOneWidget);
  });

  testWidgets('Tapping the button toggles menu open/close', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CupertinoMenuAnchorApp());

    await tester.tap(find.text('Open Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Regular Item'), findsOneWidget);

    await tester.tap(find.text('Close Menu'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Regular Item'), findsNothing);
    expect(find.text('Colorful Item'), findsNothing);
    expect(find.text('Destructive Item'), findsNothing);
    expect(find.text('Open Menu'), findsOneWidget);
  });
}
