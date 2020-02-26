import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NavigationRail renders at the correct default width', (WidgetTester tester) async {
    await _pumpDefaultNavigationRail(tester);

    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
    expect(renderBox.size.width, 72);
  });

//  testWidgets('NavigationRail renders icons and labels', (WidgetTester tester) async {
//    await _pumpDefaultNavigationRail(tester);
//
//    expect(find.byIcon(Icons.favorite), findsOneWidget);
//    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
//    expect(find.byIcon(Icons.star_border), findsOneWidget);
//    expect(find.byIcon(Icons.hotel), findsOneWidget);
//    expect(find.byIcon(Icons.remove_circle), findsOneWidget);
//
//    expect(find.text('First'), findsOneWidget);
//    expect(find.text('Second'), findsOneWidget);
//    expect(find.text('Third'), findsOneWidget);
//    expect(find.text('Fourth'), findsOneWidget);
//    expect(find.text('Fifth'), findsOneWidget);
//  });

//  testWidgets('NavigationRail onDestinationSelected is called', (WidgetTester tester) async {
//    int mutatedIndex;
//
//    await _pumpDefaultNavigationRail(
//      tester,
//      onDestinationSelected: (int index) {
//        mutatedIndex = index;
//      }
//    );
//
//    await tester.tap(find.text('Second'));
//    expect(mutatedIndex, 1);
//
//    await tester.tap(find.text('Third'));
//    expect(mutatedIndex, 2);
//  });
}

Future<void> _pumpDefaultNavigationRail(
  WidgetTester tester, {
  ValueChanged<int> onDestinationSelected,
}) async {
  await _pumpNavigationRail(
    tester,
    navigationRail: NavigationRail(
      currentIndex: 0,
      destinations: const <NavigationRailDestination>[
        NavigationRailDestination(
          icon: Icon(Icons.favorite_border),
          activeIcon: Icon(Icons.favorite),
          label: Text('First'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.bookmark_border),
          activeIcon: Icon(Icons.bookmark),
          label: Text('Second'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.star_border),
          activeIcon: Icon(Icons.star),
          label: Text('Third'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.hotel),
          activeIcon: Icon(Icons.home),
          label: Text('Fourth'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.remove_circle),
          activeIcon: Icon(Icons.add_circle),
          label: Text('Fifth'),
        ),
      ],
      onDestinationSelected: onDestinationSelected,
    ),
  );
}

Future<void> _pumpNavigationRail(WidgetTester tester, {NavigationRail navigationRail}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Row(
          children: <Widget>[
            navigationRail,
            const Expanded(
              child: Text('body'),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump();
  await tester.pump();
  await tester.pump();
  await tester.pump
}