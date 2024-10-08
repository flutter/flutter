import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/bottom_app_bar/bottom_app_bar.1.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BottomAppBarDemo toggles FAB, notch, and FAB location', (WidgetTester tester) async {
    await tester.pumpWidget(const BottomAppBarDemo());

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(BottomAppBar), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget); // FAB icon

    BottomAppBar bottomAppBar = tester.widget(find.byType(BottomAppBar));
    expect(bottomAppBar.shape, isA<CircularNotchedRectangle>());

    Scaffold scaffold = tester.widget(find.byType(Scaffold));
    expect(scaffold.floatingActionButtonLocation, equals(FloatingActionButtonLocation.endDocked));

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsNothing);

    // Toggle the FAB switch back on
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pump();

    // Verify that the FAB is displayed again
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Toggle the notch off
    await tester.tap(find.byType(SwitchListTile).at(1));
    await tester.pump();

    // Verify that the BottomAppBar no longer has a notch
    bottomAppBar = tester.widget(find.byType(BottomAppBar));
    expect(bottomAppBar.shape, isNull);

    // Toggle the notch back on
    await tester.tap(find.byType(SwitchListTile).at(1));
    await tester.pump();

    // Verify that the BottomAppBar has the notch again
    bottomAppBar = tester.widget(find.byType(BottomAppBar));
    expect(bottomAppBar.shape, isA<CircularNotchedRectangle>());

    // Verify FAB location change to centerDocked
    await tester.tap(find.byType(RadioListTile<FloatingActionButtonLocation>).at(1));
    await tester.pump();

    // Verify that the FAB location is now centerDocked
    scaffold = tester.widget(find.byType(Scaffold));
    expect(scaffold.floatingActionButtonLocation, equals(FloatingActionButtonLocation.centerDocked));

    // Verify FAB location change to endFloat
    await tester.tap(find.byType(RadioListTile<FloatingActionButtonLocation>).at(2));
    await tester.pump();

    // Verify that the FAB location is now endFloat
    scaffold = tester.widget(find.byType(Scaffold));
    expect(scaffold.floatingActionButtonLocation, equals(FloatingActionButtonLocation.endFloat));
  });
}
