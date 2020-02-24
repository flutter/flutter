import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NavigationRail callback test', (WidgetTester tester) async {
    int mutatedIndex;

    await _pumpRail(
      tester,
      onDestinationSelected: (int index) {
        mutatedIndex = index;
      }
    );

    await tester.tap(find.text('Second'));

    expect(mutatedIndex, 1);
  });
}

void _pumpRail(WidgetTester tester, {ValueChanged<int> onDestinationSelected}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Row(
          children: <Widget>[
            NavigationRail(
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.favorite_border),
                  activeIcon: Icon(Icons.forward),
                  label: Text('First'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite_border),
                  activeIcon: Icon(Icons.forward),
                  label: Text('Second'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite_border),
                  activeIcon: Icon(Icons.forward),
                  label: Text('Third'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite_border),
                  activeIcon: Icon(Icons.forward),
                  label: Text('Fourth'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.favorite_border),
                  activeIcon: Icon(Icons.forward),
                  label: Text('Fifth'),
                ),
              ],
              onDestinationSelected: onDestinationSelected,
            )
          ],
        ),
      ),
    ),
  );
}