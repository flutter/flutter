import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BottomNavigationBar label color is taken from selectedLabelStyle',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(
              color: Colors.red,
            ),
            unselectedLabelStyle: const TextStyle(
              color: Colors.grey,
            ),
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );

    // Check if given color is in at least one of the DefaultTextStyle widgets.
    bool _hasColor(Iterable<DefaultTextStyle> defaultTextStyles, Color color) {
      return defaultTextStyles
          .where((DefaultTextStyle defaultTextStyle) => defaultTextStyle.style.color == color)
          .isNotEmpty;
    }

    final Iterable<DefaultTextStyle> defaultTextStyles =
        tester.widgetList<DefaultTextStyle>(find.widgetWithText(DefaultTextStyle, 'Home'));

    // There must be a red color in defaultTextStyles.
    expect(
      _hasColor(defaultTextStyles, Colors.red),
      true,
    );

    // There must not be a green color in defaultTextStyles.
    expect(
      _hasColor(defaultTextStyles, Colors.green),
      false,
    );
  });
}
