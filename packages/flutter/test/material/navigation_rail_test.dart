import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
//  testWidgets('NavigationRail renders at the correct default width', (WidgetTester tester) async {
//    await _pumpDefaultNavigationRail(tester);
//
//    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
//    expect(renderBox.size.width, 72);
//  });
//
//  testWidgets('NavigationRail with labelType none renders icons', (WidgetTester tester) async {
//    await _pumpDefaultNavigationRail(tester);
//
//    expect(find.byIcon(Icons.favorite), findsOneWidget);
//    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
//    expect(find.byIcon(Icons.star_border), findsOneWidget);
//    expect(find.byIcon(Icons.hotel), findsOneWidget);
//    expect(find.byIcon(Icons.remove_circle), findsOneWidget);
//  });
//
//  testWidgets('NavigationRail with labelType all renders icons and labels', (WidgetTester tester) async {
//    await _pumpDefaultNavigationRail(
//      tester,
//      labelType: NavigationRailLabelType.all,
//    );
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
//
//  testWidgets('NavigationRail with labelType selected renders icons and selected label', (WidgetTester tester) async {
//    await _pumpDefaultNavigationRail(
//      tester,
//      labelType: NavigationRailLabelType.selected,
//    );
//
//    expect(find.byIcon(Icons.favorite), findsOneWidget);
//    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
//    expect(find.byIcon(Icons.star_border), findsOneWidget);
//    expect(find.byIcon(Icons.hotel), findsOneWidget);
//    expect(find.byIcon(Icons.remove_circle), findsOneWidget);
//
//    expect(find.text('First'), findsOneWidget);
//    expect(find.text('Second'), findsNothing);
//    expect(find.text('Third'), findsNothing);
//    expect(find.text('Fourth'), findsNothing);
//    expect(find.text('Fifth'), findsNothing);
//  });
//
//  testWidgets('NavigationRail onDestinationSelected is called', (WidgetTester tester) async {
//    int mutatedIndex;
//
//    await _pumpDefaultNavigationRail(
//      tester,
//      onDestinationSelected: (int index) {
//        mutatedIndex = index;
//      },
//      labelType: NavigationRailLabelType.all,
//    );
//
//    await tester.tap(find.text('Second'));
//    expect(mutatedIndex, 1);
//
//    await tester.tap(find.text('Third'));
//    expect(mutatedIndex, 2);
//  });
//
//  testWidgets('NavigationRail destination spacing is correct - labelType none, textScaleFactor 1', (WidgetTester tester) async {
//    await _pumpDefaultNavigationRail(
//      tester,
//      textScaleFactor: 1,
//      labelType: NavigationRailLabelType.none,
//    );
//
//    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
//    expect(renderBox.size.width, 72);
//
//    final RenderBox firstIcon = tester.renderObject(find.byType(RichText).at(0));
//    final RenderBox secondIcon = tester.renderObject(find.byType(RichText).at(1));
//    final RenderBox thirdIcon = tester.renderObject(find.byType(RichText).at(2));
//    final RenderBox fourthIcon = tester.renderObject(find.byType(RichText).at(3));
//    final RenderBox fifthIcon = tester.renderObject(find.byType(RichText).at(4));
//
//    // The destination padding is 24, but the top has additional padding of 8.
//    expect(firstIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 32.0)));
//    expect(secondIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 104.0)));
//    expect(thirdIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 176.0)));
//    expect(fourthIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 248.0)));
//    expect(fifthIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 320.0)));
//  });
//
//  testWidgets('NavigationRail destination spacing is correct - labelType none, textScaleFactor 3', (WidgetTester tester) async {
//    // Since the rail is icon only, its destinations should not be affected by
//    // textScaleFactor.
//    await _pumpDefaultNavigationRail(
//      tester,
//      textScaleFactor: 3,
//      labelType: NavigationRailLabelType.none,
//    );
//
//    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
//    expect(renderBox.size.width, 72);
//
//    final RenderBox firstIcon = tester.renderObject(find.byType(RichText).at(0));
//    final RenderBox secondIcon = tester.renderObject(find.byType(RichText).at(1));
//    final RenderBox thirdIcon = tester.renderObject(find.byType(RichText).at(2));
//    final RenderBox fourthIcon = tester.renderObject(find.byType(RichText).at(3));
//    final RenderBox fifthIcon = tester.renderObject(find.byType(RichText).at(4));
//
//    // The destination padding is 24, but the top has additional padding of 8.
//    expect(firstIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 32.0)));
//    expect(secondIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 104.0)));
//    expect(thirdIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 176.0)));
//    expect(fourthIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 248.0)));
//    expect(fifthIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 320.0)));
//  });
//
//  testWidgets('NavigationRail destination size and spacing is correct - labelType none, textScaleFactor 0.75', (WidgetTester tester) async {
//    // Since the rail is icon only, its destinations should not be affected by
//    // textScaleFactor.
//    await _pumpDefaultNavigationRail(
//      tester,
//      textScaleFactor: 0.75,
//      labelType: NavigationRailLabelType.none,
//    );
//
//    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
//    expect(renderBox.size.width, 72);
//
//    final RenderBox firstIcon = tester.renderObject(find.byType(RichText).at(0));
//    final RenderBox secondIcon = tester.renderObject(find.byType(RichText).at(1));
//    final RenderBox thirdIcon = tester.renderObject(find.byType(RichText).at(2));
//    final RenderBox fourthIcon = tester.renderObject(find.byType(RichText).at(3));
//    final RenderBox fifthIcon = tester.renderObject(find.byType(RichText).at(4));
//
//    // The destination padding is 24, but the top has additional padding of 8.
//    expect(firstIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 32.0)));
//    expect(secondIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 104.0)));
//    expect(thirdIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 176.0)));
//    expect(fourthIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 248.0)));
//    expect(fifthIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 320.0)));
//  });

  testWidgets('NavigationRail destination size and spacing is correct - labelType selected, textScaleFactor 1', (WidgetTester tester) async {
    // textScaleFactor.
    await _pumpDefaultNavigationRail(
      tester,
      textScaleFactor: 1.0,
      labelType: NavigationRailLabelType.selected,
    );

//    final RenderBox renderBox = tester.renderObject(find.byType(NavigationRail));
//    expect(renderBox.size.width, 72);

    final RenderBox firstIcon = tester.renderObject(find.byType(RichText).at(0));
    final RenderBox firstLabel = tester.renderObject(find.byType(RichText).at(1));
    final RenderBox secondIcon = tester.renderObject(find.byType(RichText).at(2));
    final RenderBox thirdIcon = tester.renderObject(find.byType(RichText).at(3));
    final RenderBox fourthIcon = tester.renderObject(find.byType(RichText).at(4));
    final RenderBox fifthIcon = tester.renderObject(find.byType(RichText).at(5));

    // The destination padding is 24, but the top has additional padding of 8.
    expect(tester.widget(find.byType(RichText).at(1)).toString(), '');
    expect(firstIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 24.0)));
//    expect(firstLabel.localToGlobal(Offset.zero), equals(const Offset(9.5, 48.0)));
//    expect(secondIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 120.0)));
//    expect(fourthIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 248.0)));
//    expect(fifthIcon.localToGlobal(Offset.zero), equals(const Offset(24.0, 320.0)));
  });

  testWidgets('NavigationRail destination size and spacing is correct - labelType selected, textScaleFactor 3', (WidgetTester tester) async {

  });

  testWidgets('NavigationRail destination size and spacing is correct - labelType selected, textScaleFactor 0.75', (WidgetTester tester) async {

  });

  testWidgets('NavigationRail destination size and spacing is correct - labelType all, textScaleFactor 1', (WidgetTester tester) async {

  });

  testWidgets('NavigationRail destination size and spacing is correct - labelType all, textScaleFactor 3', (WidgetTester tester) async {

  });

  testWidgets('NavigationRail destination size and spacing is correct - labelType all, textScaleFactor 0.75', (WidgetTester tester) async {

  });
}

Future<void> _pumpDefaultNavigationRail(
  WidgetTester tester, {
  double textScaleFactor,
  int currentIndex,
  ValueChanged<int> onDestinationSelected,
  NavigationRailLabelType labelType,
}) async {
  await _pumpNavigationRail(
    tester,
    textScaleFactor: textScaleFactor,
    navigationRail: NavigationRail(
      currentIndex: currentIndex ?? 0,
      labelType: labelType ?? NavigationRailLabelType.none,
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

Future<void> _pumpNavigationRail(
  WidgetTester tester, {
  double textScaleFactor,
  NavigationRail navigationRail,
}) async {
  textScaleFactor ??= 1;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
            child: Scaffold(
              body: Row(
                children: <Widget>[
                  navigationRail,
                  const Expanded(
                    child: Text('body'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}