import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    WidgetsBinding.instance!.focusManager.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });

  testWidgets('Navigation bar updates destinations when tapped', (WidgetTester tester) async {
    int mutatedIndex = 0;
    final Widget widget = _buildWidget(
      UniqueKey(),
      NavigationBar(
        destinations: const <Widget>[
          NavigationBarDestination(
            icon: Icons.ac_unit,
            label: 'AC',
          ),
          NavigationBarDestination(
            icon: Icons.access_alarm,
            label: 'Alarm',
          ),
        ],
        onTap: (int i) {
          mutatedIndex = i;
        },
      ),
    );

    await tester.pumpWidget(widget);
    await tester.tap(find.text('Alarm'));

    expect(mutatedIndex, 1);
  });

  testWidgets('Navigation bar semantics', (WidgetTester tester) async {
    final Key painterKey = UniqueKey();
    Widget _widget({int selectedIndex = 0}) {
      return _buildWidget(
        painterKey,
        NavigationBar(
          selectedIndex: selectedIndex,
          destinations: const <Widget>[
            NavigationBarDestination(
              icon: Icons.ac_unit,
              label: 'AC',
            ),
            NavigationBarDestination(
              icon: Icons.access_alarm,
              label: 'Alarm',
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(_widget(selectedIndex: 0));

    expect(
      tester.getSemantics(find.text('AC')),
      matchesSemantics(
        label: 'AC\nTab 1 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Alarm')),
      matchesSemantics(
        label: 'Alarm\nTab 2 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );

    await tester.pumpWidget(_widget(selectedIndex: 1));

    expect(
      tester.getSemantics(find.text('AC')),
      matchesSemantics(
        label: 'AC\nTab 1 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Alarm')),
      matchesSemantics(
        label: 'Alarm\nTab 2 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('Navigation bar semantics with some labels hidden', (WidgetTester tester) async {
    final Key painterKey = UniqueKey();
    Widget _widget({int selectedIndex = 0}) {
      return _buildWidget(
        painterKey,
        NavigationBar(
          labelBehavior: NavigationBarDestinationLabelBehavior.onlyShowSelected,
          selectedIndex: selectedIndex,
          destinations: const <Widget>[
            NavigationBarDestination(
              icon: Icons.ac_unit,
              label: 'AC',
            ),
            NavigationBarDestination(
              icon: Icons.access_alarm,
              label: 'Alarm',
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(_widget(selectedIndex: 0));

    expect(
      tester.getSemantics(find.text('AC')),
      matchesSemantics(
        label: 'AC\nTab 1 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Alarm')),
      matchesSemantics(
        label: 'Alarm\nTab 2 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );

    await tester.pumpWidget(_widget(selectedIndex: 1));

    expect(
      tester.getSemantics(find.text('AC')),
      matchesSemantics(
        label: 'AC\nTab 1 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Alarm')),
      matchesSemantics(
        label: 'Alarm\nTab 2 of 2',
        textDirection: TextDirection.ltr,
        isFocusable: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('Navigation bar animates when new destination is selected', (WidgetTester tester) async {
    final Key painterKey = UniqueKey();
    const int _animationMilliseconds = 500;

    Widget _widget({int selectedIndex = 0}) {
      return _buildWidget(
        painterKey,
        NavigationBar(
          animationDuration: const Duration(milliseconds: _animationMilliseconds),
          selectedIndex: selectedIndex,
          destinations: const <Widget>[
            NavigationBarDestination(
              icon: Icons.bookmark,
              unselectedIcon: Icons.bookmark_border,
              label: 'Saved',
            ),
            NavigationBarDestination(
              icon: Icons.add_circle,
              unselectedIcon: Icons.add_circle_outline,
              label: 'Contribute',
            ),
            NavigationBarDestination(
              icon: Icons.notifications,
              unselectedIcon: Icons.notifications_none,
              label: 'Updates',
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(_widget(selectedIndex: 0));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_0_0_millis_initial'),
    );

    // Start animation by selecting new destination.
    await tester.pumpWidget(_widget(selectedIndex: 2));
    await tester.pump(const Duration(milliseconds: 25));
    // Indicator is fading out and in.
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_1_25_millis'),
    );

    await tester.pump(const Duration(milliseconds: 50));
    // Indicator is still fading out and in.
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_2_75_millis'),
    );

    await tester.pump(const Duration(milliseconds: 125));
    // Unselected indicator is faded out, selected indicator is faded in and
    // scaling.
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_3_200_millis'),
    );

    await tester.pump(const Duration(milliseconds: 200));
    // Selected indicator is still fading in.
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_4_400_millis'),
    );

    await tester.pump(const Duration(milliseconds: 100));
    // Animation is complete.
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_5_500_millis_final'),
    );
  });

  testWidgets('Navigation bar can animate with shifting labels', (WidgetTester tester) async {
    final Key painterKey = UniqueKey();
    const int _animationMilliseconds = 500;

    Widget _widget({int selectedIndex = 0}) {
      return _buildWidget(
        painterKey,
        NavigationBar(
          animationDuration: const Duration(milliseconds: _animationMilliseconds),
          selectedIndex: selectedIndex,
          labelBehavior: NavigationBarDestinationLabelBehavior.onlyShowSelected,
          destinations: const <Widget>[
            NavigationBarDestination(
              icon: Icons.bookmark,
              unselectedIcon: Icons.bookmark_border,
              label: 'Saved',
            ),
            NavigationBarDestination(
              icon: Icons.add_circle,
              unselectedIcon: Icons.add_circle_outline,
              label: 'Contribute',
            ),
            NavigationBarDestination(
              icon: Icons.notifications,
              unselectedIcon: Icons.notifications_none,
              label: 'Updates',
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(_widget(selectedIndex: 0));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_shifting_labels_0_0_millis_initial'),
    );

    // Start animation by selecting new destination.
    await tester.pumpWidget(_widget(selectedIndex: 2));
    await tester.pump(const Duration(milliseconds: 25));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_shifting_labels_1_25_millis'),
    );

    await tester.pump(const Duration(milliseconds: 50));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_shifting_labels_2_75_millis'),
    );

    await tester.pump(const Duration(milliseconds: 125));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_shifting_labels_3_200_millis'),
    );

    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_shifting_labels_4_400_millis'),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_shifting_labels_5_500_millis_final'),
    );
  });

  testWidgets(
      'Navigation bar animates properly in reverse when new item selected mid'
      ' animation', (WidgetTester tester) async {
    final Key painterKey = UniqueKey();
    const int _animationMilliseconds = 500;

    Widget _widget({int selectedIndex = 0}) {
      return _buildWidget(
        painterKey,
        NavigationBar(
          animationDuration: const Duration(milliseconds: _animationMilliseconds),
          selectedIndex: selectedIndex,
          labelBehavior: NavigationBarDestinationLabelBehavior.onlyShowSelected,
          destinations: const <Widget>[
            NavigationBarDestination(
              icon: Icons.bookmark,
              unselectedIcon: Icons.bookmark_border,
              label: 'Saved',
            ),
            NavigationBarDestination(
              icon: Icons.add_circle,
              unselectedIcon: Icons.add_circle_outline,
              label: 'Contribute',
            ),
            NavigationBarDestination(
              icon: Icons.notifications,
              unselectedIcon: Icons.notifications_none,
              label: 'Updates',
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(_widget(selectedIndex: 0));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_shifting_labels_0_0_millis_initial'),
    );

    // Start animation by selecting new destination.
    await tester.pumpWidget(_widget(selectedIndex: 2));
    await tester.pump(const Duration(milliseconds: 25));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_shifting_labels_1_25_millis'),
    );

    await tester.pump(const Duration(milliseconds: 50));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_shifting_labels_2_75_millis'),
    );

    await tester.pump(const Duration(milliseconds: 125));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_shifting_labels_3_200_millis'),
    );

    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_shifting_labels_4_400_millis'),
    );

    // Cut the animation short and have it reverse the animation.
    await tester.pumpWidget(_widget(selectedIndex: 0));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_shifting_labels_5_400_millis'),
    );

    await tester.pump(const Duration(milliseconds: 50));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_shifting_labels_6_350_millis'),
    );

    await tester.pump(const Duration(milliseconds: 150));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_shifting_labels_7_200_millis'),
    );

    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(
      find.byKey(painterKey),
      matchesGoldenFile('navigation_bar_shifting_labels_0_0_millis_initial'),
    );
  });

  testWidgets('Navigation bar does not grow with text scale factor', (WidgetTester tester) async {
    final Key painterKey = UniqueKey();
    const int _animationMilliseconds = 800;

    Widget _widget({double textScaleFactor = 1}) {
      return _buildWidget(
        painterKey,
        MediaQuery(
          data: MediaQueryData(textScaleFactor: textScaleFactor),
          child: const NavigationBar(
            animationDuration: Duration(milliseconds: _animationMilliseconds),
            destinations: <Widget>[
              NavigationBarDestination(
                icon: Icons.ac_unit,
                label: 'AC',
              ),
              NavigationBarDestination(
                icon: Icons.access_alarm,
                label: 'Alarm',
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(_widget());
    final double initialHeight =
        tester.renderObject<RenderBox>(find.byType(NavigationBar)).size.height;

    await tester.pumpWidget(_widget(textScaleFactor: 2));
    final double newHeight =
        tester.renderObject<RenderBox>(find.byType(NavigationBar)).size.height;

    expect(newHeight, equals(initialHeight));
  });
}

Widget _buildWidget(Key key, Widget child) {
  return MaterialApp(
    theme: ThemeData.light(),
    home: Scaffold(
      bottomNavigationBar: Center(
        child: RepaintBoundary(
          key: key,
          child: child,
        ),
      ),
    ),
  );
}
