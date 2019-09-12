// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show window;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

const List<String> menuItems = <String>['one', 'two', 'three', 'four'];
final ValueChanged<String> onChanged = (_) { };

final Type dropdownButtonType = DropdownButton<String>(
  onChanged: (_) { },
  items: const <DropdownMenuItem<String>>[],
).runtimeType;

Finder _iconRichText(Key iconKey) {
  return find.descendant(
    of: find.byKey(iconKey),
    matching: find.byType(RichText),
  );
}

Widget buildFrame({
  Key buttonKey,
  String value = 'two',
  ValueChanged<String> onChanged,
  Widget icon,
  Color iconDisabledColor,
  Color iconEnabledColor,
  double iconSize = 24.0,
  bool isDense = false,
  bool isExpanded = false,
  Widget hint,
  Widget disabledHint,
  Widget underline,
  List<String> items = menuItems,
  Alignment alignment = Alignment.center,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return TestApp(
    textDirection: textDirection,
    child: Material(
      child: Align(
        alignment: alignment,
        child: RepaintBoundary(
          child: DropdownButton<String>(
            key: buttonKey,
            value: value,
            hint: hint,
            disabledHint: disabledHint,
            onChanged: onChanged,
            icon: icon,
            iconSize: iconSize,
            iconDisabledColor: iconDisabledColor,
            iconEnabledColor: iconEnabledColor,
            isDense: isDense,
            isExpanded: isExpanded,
            underline: underline,
            items: items == null ? null : items.map<DropdownMenuItem<String>>((String item) {
              return DropdownMenuItem<String>(
                key: ValueKey<String>(item),
                value: item,
                child: Text(item, key: ValueKey<String>(item + 'Text')),
              );
            }).toList(),
          ),
        ),
      ),
    ),
  );
}

Widget buildFormFrame({
  Key buttonKey,
  bool autovalidate = false,
  int elevation = 8,
  String value = 'two',
  ValueChanged<String> onChanged,
  Widget icon,
  Color iconDisabledColor,
  Color iconEnabledColor,
  double iconSize = 24.0,
  bool isDense = false,
  bool isExpanded = false,
  Widget hint,
  Widget disabledHint,
  Widget underline,
  List<String> items = menuItems,
  Alignment alignment = Alignment.center,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return TestApp(
    textDirection: textDirection,
    child: Material(
      child: Align(
        alignment: alignment,
        child: RepaintBoundary(
          child: DropdownButtonFormField<String>(
            key: buttonKey,
            autovalidate: autovalidate,
            elevation: elevation,
            value: value,
            hint: hint,
            disabledHint: disabledHint,
            onChanged: onChanged,
            icon: icon,
            iconSize: iconSize,
            iconDisabledColor: iconDisabledColor,
            iconEnabledColor: iconEnabledColor,
            isDense: isDense,
            isExpanded: isExpanded,
            items: items == null ? null : items.map<DropdownMenuItem<String>>((String item) {
              return DropdownMenuItem<String>(
                key: ValueKey<String>(item),
                value: item,
                child: Text(item, key: ValueKey<String>(item + 'Text')),
              );
            }).toList(),
          ),
        ),
      ),
    ),
  );
}

class TestApp extends StatefulWidget {
  const TestApp({ this.textDirection, this.child });
  final TextDirection textDirection;
  final Widget child;
  @override
  _TestAppState createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: MediaQuery(
        data: MediaQueryData.fromWindow(window),
        child: Directionality(
          textDirection: widget.textDirection,
          child: Navigator(
            onGenerateRoute: (RouteSettings settings) {
              assert(settings.name == '/');
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (BuildContext context) => widget.child,
              );
            },
          ),
        ),
      ),
    );
  }
}

// When the dropdown's menu is popped up, a RenderParagraph for the selected
// menu's text item will appear both in the dropdown button and in the menu.
// The RenderParagraphs should be aligned, i.e. they should have the same
// size and location.
void checkSelectedItemTextGeometry(WidgetTester tester, String value) {
  final List<RenderBox> boxes = tester.renderObjectList<RenderBox>(find.byKey(ValueKey<String>(value + 'Text'))).toList();
  expect(boxes.length, equals(2));
  final RenderBox box0 = boxes[0];
  final RenderBox box1 = boxes[1];
  expect(box0.localToGlobal(Offset.zero), equals(box1.localToGlobal(Offset.zero)));
  expect(box0.size, equals(box1.size));
}

void verifyPaintedShadow(Finder customPaint, int elevation) {
  const Rect originalRectangle = Rect.fromLTRB(0.0, 0.0, 800, 208.0);

  final List<BoxShadow> boxShadows = List<BoxShadow>.generate(3, (int index) => kElevationToShadow[elevation][index]);
  final List<RRect> rrects = List<RRect>.generate(3, (int index) {
    return RRect.fromRectAndRadius(
      originalRectangle.shift(
        boxShadows[index].offset
      ).inflate(boxShadows[index].spreadRadius),
      const Radius.circular(2.0),
    );
  });

  expect(
    customPaint,
    paints
      ..save()
      ..rrect(rrect: rrects[0], color: boxShadows[0].color, hasMaskFilter: true)
      ..rrect(rrect: rrects[1], color: boxShadows[1].color, hasMaskFilter: true)
      ..rrect(rrect: rrects[2], color: boxShadows[2].color, hasMaskFilter: true),
  );
}

bool sameGeometry(RenderBox box1, RenderBox box2) {
  expect(box1.localToGlobal(Offset.zero), equals(box2.localToGlobal(Offset.zero)));
  expect(box1.size.height, equals(box2.size.height));
  return true;
}

void main() {
  testWidgets('Default dropdown golden', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();
    Widget build() => buildFrame(buttonKey: buttonKey, value: 'two', onChanged: onChanged);
    await tester.pumpWidget(build());
    final Finder buttonFinder = find.byKey(buttonKey);
    assert(tester.renderObject(buttonFinder).attached);
    await expectLater(
      find.ancestor(of: buttonFinder, matching: find.byType(RepaintBoundary)).first,
      matchesGoldenFile(
        'dropdown_test.default.png',
        version: 0,
      ),
    );
  }, skip: isBrowser);

  testWidgets('Expanded dropdown golden', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();
    Widget build() => buildFrame(buttonKey: buttonKey, value: 'two', isExpanded: true, onChanged: onChanged);
    await tester.pumpWidget(build());
    final Finder buttonFinder = find.byKey(buttonKey);
    assert(tester.renderObject(buttonFinder).attached);
    await expectLater(
      find.ancestor(of: buttonFinder, matching: find.byType(RepaintBoundary)).first,
      matchesGoldenFile(
        'dropdown_test.expanded.png',
        version: 0,
      ),
    );
  }, skip: isBrowser);

  testWidgets('Dropdown button control test', (WidgetTester tester) async {
    String value = 'one';
    void didChangeValue(String newValue) {
      value = newValue;
    }

    Widget build() => buildFrame(value: value, onChanged: didChangeValue);

    await tester.pumpWidget(build());

    await tester.tap(find.text('one'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('one'));

    await tester.tap(find.text('three').last);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('three'));

    await tester.tap(find.text('three'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('three'));

    await tester.pumpWidget(build());

    await tester.tap(find.text('two').last);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('two'));
  });

  testWidgets('Dropdown button with no app', (WidgetTester tester) async {
    String value = 'one';
    void didChangeValue(String newValue) {
      value = newValue;
    }

    Widget build() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          initialRoute: '/',
          onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (BuildContext context) {
                return Material(
                  child: buildFrame(value: 'one', onChanged: didChangeValue),
                );
              },
            );
          },
        ),
      );
    }

    await tester.pumpWidget(build());

    await tester.tap(find.text('one'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('one'));

    await tester.tap(find.text('three').last);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('three'));

    await tester.tap(find.text('three'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('three'));

    await tester.pumpWidget(build());

    await tester.tap(find.text('two').last);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('two'));
  });

  testWidgets('Dropdown in ListView', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/12053
    // Positions a DropdownButton at the left and right edges of the screen,
    // forcing it to be sized down to the viewport width
    const String value = 'foo';
    final UniqueKey itemKey = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              DropdownButton<String>(
                value: value,
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    key: itemKey,
                    value: value,
                    child: const Text(value),
                  ),
                ],
                onChanged: (_) { },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text(value));
    await tester.pump();
    final List<RenderBox> itemBoxes = tester.renderObjectList<RenderBox>(find.byKey(itemKey)).toList();
    expect(itemBoxes[0].localToGlobal(Offset.zero).dx, equals(0.0));
    expect(itemBoxes[1].localToGlobal(Offset.zero).dx, equals(16.0));
    expect(itemBoxes[1].size.width, equals(800.0 - 16.0 * 2));
  });

  testWidgets('Dropdown screen edges', (WidgetTester tester) async {
    int value = 4;
    final List<DropdownMenuItem<int>> items = <DropdownMenuItem<int>>[];
    for (int i = 0; i < 20; ++i)
      items.add(DropdownMenuItem<int>(value: i, child: Text('$i')));

    void handleChanged(int newValue) {
      value = newValue;
    }

    final DropdownButton<int> button = DropdownButton<int>(
      value: value,
      onChanged: handleChanged,
      items: items,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Align(
            alignment: Alignment.topCenter,
            child: button,
          ),
        ),
      ),
    );

    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    // We should have two copies of item 5, one in the menu and one in the
    // button itself.
    expect(tester.elementList(find.text('5')), hasLength(2));

    // We should only have one copy of item 19, which is in the button itself.
    // The copy in the menu shouldn't be in the tree because it's off-screen.
    expect(tester.elementList(find.text('19')), hasLength(1));

    expect(value, 4);
    await tester.tap(find.byWidget(button));
    expect(value, 4);
    // this waits for the route's completer to complete, which calls handleChanged
    await tester.idle();
    expect(value, 4);

    // TODO(abarth): Remove these calls to pump once navigator cleans up its
    // pop transitions.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation
  });

  for (TextDirection textDirection in TextDirection.values) {
    testWidgets('Dropdown button aligns selected menu item ($textDirection)', (WidgetTester tester) async {
      final Key buttonKey = UniqueKey();
      const String value = 'two';

      Widget build() => buildFrame(buttonKey: buttonKey, value: value, textDirection: textDirection, onChanged: onChanged);

      await tester.pumpWidget(build());
      final RenderBox buttonBox = tester.renderObject<RenderBox>(find.byKey(buttonKey));
      assert(buttonBox.attached);
      final Offset buttonOriginBeforeTap = buttonBox.localToGlobal(Offset.zero);

      await tester.tap(find.text('two'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // finish the menu animation

      // Tapping the dropdown button should not cause it to move.
      expect(buttonBox.localToGlobal(Offset.zero), equals(buttonOriginBeforeTap));

      // The selected dropdown item is both in menu we just popped up, and in
      // the IndexedStack contained by the dropdown button. Both of them should
      // have the same origin and height as the dropdown button.
      final List<RenderObject> itemBoxes = tester.renderObjectList<RenderBox>(find.byKey(const ValueKey<String>('two'))).toList();
      expect(itemBoxes.length, equals(2));
      for (RenderBox itemBox in itemBoxes) {
        assert(itemBox.attached);
        assert(textDirection != null);
        switch (textDirection) {
          case TextDirection.rtl:
            expect(buttonBox.localToGlobal(buttonBox.size.bottomRight(Offset.zero)),
                   equals(itemBox.localToGlobal(itemBox.size.bottomRight(Offset.zero))));
            break;
          case TextDirection.ltr:
            expect(buttonBox.localToGlobal(Offset.zero), equals(itemBox.localToGlobal(Offset.zero)));
            break;
        }
        expect(buttonBox.size.height, equals(itemBox.size.height));
      }

      // The two RenderParagraph objects, for the 'two' items' Text children,
      // should have the same size and location.
      checkSelectedItemTextGeometry(tester, 'two');

      await tester.pumpWidget(Container()); // reset test
    });
  }

  testWidgets('Arrow icon aligns with the edge of button when expanded', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();

    Widget build() => buildFrame(buttonKey: buttonKey, value: 'two', isExpanded: true, onChanged: onChanged);

    await tester.pumpWidget(build());
    final RenderBox buttonBox = tester.renderObject<RenderBox>(find.byKey(buttonKey));
    assert(buttonBox.attached);

    final RenderBox arrowIcon = tester.renderObject<RenderBox>(find.byIcon(Icons.arrow_drop_down));
    assert(arrowIcon.attached);

    // Arrow icon should be aligned with far right of button when expanded
    expect(arrowIcon.localToGlobal(Offset.zero).dx,
        buttonBox.size.centerRight(Offset(-arrowIcon.size.width, 0.0)).dx);
  });

  testWidgets('Dropdown button icon will accept widgets as icons', (WidgetTester tester) async {
    final Widget customWidget = Container(
      decoration: ShapeDecoration(
        shape: CircleBorder(
          side: BorderSide(
            width: 5.0,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );

    await tester.pumpWidget(buildFrame(
      icon: customWidget,
      onChanged: onChanged,
    ));

    expect(find.byWidget(customWidget), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsNothing);

    await tester.pumpWidget(buildFrame(
      icon: const Icon(Icons.assessment),
      onChanged: onChanged,
    ));

    expect(find.byIcon(Icons.assessment), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
  });

  testWidgets('Dropdown button icon should have default size and colors when not defined', (WidgetTester tester) async {
    final Key iconKey = UniqueKey();
    final Icon customIcon = Icon(Icons.assessment, key: iconKey);

    await tester.pumpWidget(buildFrame(
      icon: customIcon,
      onChanged: onChanged,
    ));

    // test for size
    final RenderBox icon = tester.renderObject(find.byKey(iconKey));
    expect(icon.size, const Size(24.0, 24.0));

    // test for enabled color
    final RichText enabledRichText = tester.widget<RichText>(_iconRichText(iconKey));
    expect(enabledRichText.text.style.color, Colors.grey.shade700);

    // test for disabled color
    await tester.pumpWidget(buildFrame(
      icon: customIcon,
      onChanged: null,
    ));

    final RichText disabledRichText = tester.widget<RichText>(_iconRichText(iconKey));
    expect(disabledRichText.text.style.color, Colors.grey.shade400);
  });

  testWidgets('Dropdown button icon should have the passed in size and color instead of defaults', (WidgetTester tester) async {
    final Key iconKey = UniqueKey();
    final Icon customIcon = Icon(Icons.assessment, key: iconKey);

    await tester.pumpWidget(buildFrame(
      icon: customIcon,
      iconSize: 30.0,
      iconEnabledColor: Colors.pink,
      iconDisabledColor: Colors.orange,
      onChanged: onChanged,
    ));

    // test for size
    final RenderBox icon = tester.renderObject(find.byKey(iconKey));
    expect(icon.size, const Size(30.0, 30.0));

    // test for enabled color
    final RichText enabledRichText = tester.widget<RichText>(_iconRichText(iconKey));
    expect(enabledRichText.text.style.color, Colors.pink);

    // test for disabled color
    await tester.pumpWidget(buildFrame(
      icon: customIcon,
      iconSize: 30.0,
      iconEnabledColor: Colors.pink,
      iconDisabledColor: Colors.orange,
      onChanged: null,
    ));

    final RichText disabledRichText = tester.widget<RichText>(_iconRichText(iconKey));
    expect(disabledRichText.text.style.color, Colors.orange);
  });

  testWidgets('Dropdown button should use its own size and color properties over those defined by the theme', (WidgetTester tester) async {
    final Key iconKey = UniqueKey();

    final Icon customIcon = Icon(
      Icons.assessment,
      key: iconKey,
      size: 40.0,
      color: Colors.yellow,
    );

    await tester.pumpWidget(buildFrame(
      icon: customIcon,
      iconSize: 30.0,
      iconEnabledColor: Colors.pink,
      iconDisabledColor: Colors.orange,
      onChanged: onChanged,
    ));

    // test for size
    final RenderBox icon = tester.renderObject(find.byKey(iconKey));
    expect(icon.size, const Size(40.0, 40.0));

    // test for enabled color
    final RichText enabledRichText = tester.widget<RichText>(_iconRichText(iconKey));
    expect(enabledRichText.text.style.color, Colors.yellow);

    // test for disabled color
    await tester.pumpWidget(buildFrame(
      icon: customIcon,
      iconSize: 30.0,
      iconEnabledColor: Colors.pink,
      iconDisabledColor: Colors.orange,
      onChanged: null,
    ));

    final RichText disabledRichText = tester.widget<RichText>(_iconRichText(iconKey));
    expect(disabledRichText.text.style.color, Colors.yellow);
  });

  testWidgets('Dropdown button with isDense:true aligns selected menu item', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();
    const String value = 'two';

    Widget build() => buildFrame(buttonKey: buttonKey, value: value, isDense: true, onChanged: onChanged);

    await tester.pumpWidget(build());
    final RenderBox buttonBox = tester.renderObject<RenderBox>(find.byKey(buttonKey));
    assert(buttonBox.attached);

    await tester.tap(find.text('two'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    // The selected dropdown item is both in menu we just popped up, and in
    // the IndexedStack contained by the dropdown button. Both of them should
    // have the same vertical center as the button.
    final List<RenderBox> itemBoxes = tester.renderObjectList<RenderBox>(find.byKey(const ValueKey<String>('two'))).toList();
    expect(itemBoxes.length, equals(2));

    // When isDense is true, the button's height is reduced. The menu items'
    // heights are not.
    final double menuItemHeight = itemBoxes.map<double>((RenderBox box) => box.size.height).reduce(math.max);
    expect(menuItemHeight, greaterThan(buttonBox.size.height));

    for (RenderBox itemBox in itemBoxes) {
      assert(itemBox.attached);
      final Offset buttonBoxCenter = buttonBox.size.center(buttonBox.localToGlobal(Offset.zero));
      final Offset itemBoxCenter = itemBox.size.center(itemBox.localToGlobal(Offset.zero));
      expect(buttonBoxCenter.dy, equals(itemBoxCenter.dy));
    }

    // The two RenderParagraph objects, for the 'two' items' Text children,
    // should have the same size and location.
    checkSelectedItemTextGeometry(tester, 'two');
  });

  testWidgets('Dropdown button can have a text style with no fontSize specified', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/33425
    const String value = 'foo';
    final UniqueKey itemKey = UniqueKey();

    await tester.pumpWidget(TestApp(
      textDirection: TextDirection.ltr,
      child: Material(
        child: DropdownButton<String>(
          value: value,
          items: <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
              key: itemKey,
              value: 'foo',
              child: const Text(value),
            ),
          ],
          isDense: true,
          onChanged: (_) { },
          style: const TextStyle(color: Colors.blue),
        ),
      ),
    ));

    expect(tester.takeException(), isNull);
  });

  testWidgets('Dropdown menu scrolls to first item in long lists', (WidgetTester tester) async {
    // Open the dropdown menu
    final Key buttonKey = UniqueKey();
    await tester.pumpWidget(buildFrame(
      buttonKey: buttonKey,
      value: null, // nothing selected
      items: List<String>.generate(/*length=*/ 100, (int index) => index.toString()),
      onChanged: onChanged,
    ));
    await tester.tap(find.byKey(buttonKey));
    await tester.pump();
    await tester.pumpAndSettle(); // finish the menu animation

    // Find the first item in the scrollable dropdown list
    final Finder menuItemFinder = find.byType(Scrollable);
    final RenderBox menuItemContainer = tester.renderObject<RenderBox>(menuItemFinder);
    final RenderBox firstItem = tester.renderObject<RenderBox>(
      find.descendant(of: menuItemFinder, matching: find.byKey(const ValueKey<String>('0'))));

    // List should be scrolled so that the first item is at the top. Menu items
    // are offset 8.0 from the top edge of the scrollable menu.
    const Offset selectedItemOffset = Offset(0.0, -8.0);
    expect(
      firstItem.size.topCenter(firstItem.localToGlobal(selectedItemOffset)).dy,
      equals(menuItemContainer.size.topCenter(menuItemContainer.localToGlobal(Offset.zero)).dy),
    );
  });

  testWidgets('Dropdown menu aligns selected item with button in long lists', (WidgetTester tester) async {
    // Open the dropdown menu
    final Key buttonKey = UniqueKey();
    await tester.pumpWidget(buildFrame(
      buttonKey: buttonKey,
      value: '50',
      items: List<String>.generate(/*length=*/ 100, (int index) => index.toString()),
      onChanged: onChanged,
    ));
    final RenderBox buttonBox = tester.renderObject<RenderBox>(find.byKey(buttonKey));
    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle(); // finish the menu animation

    // Find the selected item in the scrollable dropdown list
    final RenderBox selectedItem = tester.renderObject<RenderBox>(
      find.descendant(of: find.byType(Scrollable), matching: find.byKey(const ValueKey<String>('50'))));

    // List should be scrolled so that the selected item is in line with the button
    expect(
      selectedItem.size.center(selectedItem.localToGlobal(Offset.zero)).dy,
      equals(buttonBox.size.center(buttonBox.localToGlobal(Offset.zero)).dy),
    );
  });

  testWidgets('Size of DropdownButton with null value', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();
    String value;

    Widget build() => buildFrame(buttonKey: buttonKey, value: value, onChanged: onChanged);

    await tester.pumpWidget(build());
    final RenderBox buttonBoxNullValue = tester.renderObject<RenderBox>(find.byKey(buttonKey));
    assert(buttonBoxNullValue.attached);

    value = 'three';
    await tester.pumpWidget(build());
    final RenderBox buttonBox = tester.renderObject<RenderBox>(find.byKey(buttonKey));
    assert(buttonBox.attached);

    // A Dropdown button with a null value should be the same size as a
    // one with a non-null value.
    expect(buttonBox.localToGlobal(Offset.zero), equals(buttonBoxNullValue.localToGlobal(Offset.zero)));
    expect(buttonBox.size, equals(buttonBoxNullValue.size));
  });

  testWidgets('Size of DropdownButton with no items', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/26419
    final Key buttonKey = UniqueKey();
    List<String> items;

    Widget build() => buildFrame(buttonKey: buttonKey, items: items, onChanged: onChanged);

    await tester.pumpWidget(build());
    final RenderBox buttonBoxNullItems = tester.renderObject<RenderBox>(find.byKey(buttonKey));
    assert(buttonBoxNullItems.attached);

    items = <String>[];
    await tester.pumpWidget(build());
    final RenderBox buttonBoxEmptyItems = tester.renderObject<RenderBox>(find.byKey(buttonKey));
    assert(buttonBoxEmptyItems.attached);

    items = <String>['one', 'two', 'three', 'four'];
    await tester.pumpWidget(build());
    final RenderBox buttonBox = tester.renderObject<RenderBox>(find.byKey(buttonKey));
    assert(buttonBox.attached);

    // A Dropdown button with a null value should be the same size as a
    // one with a non-null value.
    expect(buttonBox.localToGlobal(Offset.zero), equals(buttonBoxNullItems.localToGlobal(Offset.zero)));
    expect(buttonBox.size, equals(buttonBoxNullItems.size));
  });

  testWidgets('Layout of a DropdownButton with null value', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();
    String value;

    void onChanged(String newValue) {
      value = newValue;
    }

    Widget build() => buildFrame(buttonKey: buttonKey, value: value, onChanged: onChanged);

    await tester.pumpWidget(build());
    final RenderBox buttonBox = tester.renderObject<RenderBox>(find.byKey(buttonKey));
    assert(buttonBox.attached);

    // Show the menu.
    await tester.tap(find.byKey(buttonKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    // Tap on item 'one', which must appear over the button.
    await tester.tap(find.byKey(buttonKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    await tester.pumpWidget(build());
    expect(value, equals('one'));
  });

  testWidgets('Size of DropdownButton with null value and a hint', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();
    String value;

    // The hint will define the dropdown's width
    Widget build() => buildFrame(buttonKey: buttonKey, value: value, hint: const Text('onetwothree'));

    await tester.pumpWidget(build());
    expect(find.text('onetwothree'), findsOneWidget);
    final RenderBox buttonBoxHintValue = tester.renderObject<RenderBox>(find.byKey(buttonKey));
    assert(buttonBoxHintValue.attached);

    value = 'three';
    await tester.pumpWidget(build());
    final RenderBox buttonBox = tester.renderObject<RenderBox>(find.byKey(buttonKey));
    assert(buttonBox.attached);

    // A Dropdown button with a null value and a hint should be the same size as a
    // one with a non-null value.
    expect(buttonBox.localToGlobal(Offset.zero), equals(buttonBoxHintValue.localToGlobal(Offset.zero)));
    expect(buttonBox.size, equals(buttonBoxHintValue.size));
  });

  testWidgets('Dropdown menus must fit within the screen', (WidgetTester tester) async {

    // The dropdown menu isn't readily accessible. To find it we're assuming that it
    // contains a ListView and that it's an instance of _DropdownMenu.
    Rect getMenuRect() {
      Rect menuRect;
      tester.element(find.byType(ListView)).visitAncestorElements((Element element) {
        if (element.toString().startsWith('_DropdownMenu')) {
          final RenderBox box = element.findRenderObject();
          assert(box != null);
          menuRect = box.localToGlobal(Offset.zero) & box.size;
          return false;
        }
        return true;
      });
      assert(menuRect != null);
      return menuRect;
    }

    // In all of the tests that follow we're assuming that the dropdown menu
    // is horizontally aligned with the center of the dropdown button and padded
    // on the top, left, and right.
    const EdgeInsets buttonPadding = EdgeInsets.only(top: 8.0, left: 16.0, right: 24.0);

    Rect getExpandedButtonRect() {
      final RenderBox box = tester.renderObject<RenderBox>(find.byType(dropdownButtonType));
      final Rect buttonRect = box.localToGlobal(Offset.zero) & box.size;
      return buttonPadding.inflateRect(buttonRect);
    }

    Rect buttonRect;
    Rect menuRect;

    Future<void> popUpAndDown(Widget frame) async {
      await tester.pumpWidget(frame);
      await tester.tap(find.byType(dropdownButtonType));
      await tester.pumpAndSettle();
      menuRect = getMenuRect();
      buttonRect = getExpandedButtonRect();
      await tester.tap(find.byType(dropdownButtonType));
    }

    // Dropdown button is along the top of the app. The top of the menu is
    // aligned with the top of the expanded button and shifted horizontally
    // so that it fits within the frame.

    await popUpAndDown(
      buildFrame(alignment: Alignment.topLeft, value: menuItems.last, onChanged: onChanged)
    );
    expect(menuRect.topLeft, Offset.zero);
    expect(menuRect.topRight, Offset(menuRect.width, 0.0));

    await popUpAndDown(
      buildFrame(alignment: Alignment.topCenter, value: menuItems.last, onChanged: onChanged)
    );
    expect(menuRect.topLeft, Offset(buttonRect.left, 0.0));
    expect(menuRect.topRight, Offset(buttonRect.right, 0.0));

    await popUpAndDown(
      buildFrame(alignment: Alignment.topRight, value: menuItems.last, onChanged: onChanged)
    );
    expect(menuRect.topLeft, Offset(800.0 - menuRect.width, 0.0));
    expect(menuRect.topRight, const Offset(800.0, 0.0));

    // Dropdown button is along the middle of the app. The top of the menu is
    // aligned with the top of the expanded button (because the 1st item
    // is selected) and shifted horizontally so that it fits within the frame.

    await popUpAndDown(
      buildFrame(alignment: Alignment.centerLeft, value: menuItems.first, onChanged: onChanged)
    );
    expect(menuRect.topLeft, Offset(0.0, buttonRect.top));
    expect(menuRect.topRight, Offset(menuRect.width, buttonRect.top));

    await popUpAndDown(
      buildFrame(alignment: Alignment.center, value: menuItems.first, onChanged: onChanged)
    );
    expect(menuRect.topLeft, buttonRect.topLeft);
    expect(menuRect.topRight, buttonRect.topRight);

    await popUpAndDown(
      buildFrame(alignment: Alignment.centerRight, value: menuItems.first, onChanged: onChanged)
    );
    expect(menuRect.topLeft, Offset(800.0 - menuRect.width, buttonRect.top));
    expect(menuRect.topRight, Offset(800.0, buttonRect.top));

    // Dropdown button is along the bottom of the app. The bottom of the menu is
    // aligned with the bottom of the expanded button and shifted horizontally
    // so that it fits within the frame.

    await popUpAndDown(
      buildFrame(alignment: Alignment.bottomLeft, value: menuItems.first, onChanged: onChanged)
    );
    expect(menuRect.bottomLeft, const Offset(0.0, 600.0));
    expect(menuRect.bottomRight, Offset(menuRect.width, 600.0));

    await popUpAndDown(
      buildFrame(alignment: Alignment.bottomCenter, value: menuItems.first, onChanged: onChanged)
    );
    expect(menuRect.bottomLeft, Offset(buttonRect.left, 600.0));
    expect(menuRect.bottomRight, Offset(buttonRect.right, 600.0));

    await popUpAndDown(
      buildFrame(alignment: Alignment.bottomRight, value: menuItems.first, onChanged: onChanged)
    );
    expect(menuRect.bottomLeft, Offset(800.0 - menuRect.width, 600.0));
    expect(menuRect.bottomRight, const Offset(800.0, 600.0));
  });

  testWidgets('Dropdown menus are dismissed on screen orientation changes', (WidgetTester tester) async {
    await tester.pumpWidget(buildFrame(onChanged: onChanged));
    await tester.tap(find.byType(dropdownButtonType));
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsOneWidget);

    window.onMetricsChanged();
    await tester.pump();
    expect(find.byType(ListView, skipOffstage: false), findsNothing);
  });

  testWidgets('Semantics Tree contains only selected element', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(buildFrame(items: menuItems, onChanged: onChanged));

    expect(semantics, isNot(includesNodeWith(label: menuItems[0])));
    expect(semantics, includesNodeWith(label: menuItems[1]));
    expect(semantics, isNot(includesNodeWith(label: menuItems[2])));
    expect(semantics, isNot(includesNodeWith(label: menuItems[3])));

    semantics.dispose();
  });

  testWidgets('Dropdown button includes semantics', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    const Key key = Key('test');
    await tester.pumpWidget(buildFrame(
      buttonKey: key,
      value: null,
      items: menuItems,
      onChanged: (String _) { },
      hint: const Text('test'),
    ));

    // By default the hint contributes the label.
    expect(tester.getSemantics(find.byKey(key)), matchesSemantics(
      isButton: true,
      label: 'test',
      hasTapAction: true,
    ));

    await tester.pumpWidget(buildFrame(
      buttonKey: key,
      value: 'three',
      items: menuItems,
      onChanged: onChanged,
      hint: const Text('test'),
    ));

    // Displays label of select item and is no longer tappable.
    expect(tester.getSemantics(find.byKey(key)), matchesSemantics(
      isButton: true,
      label: 'three',
      hasTapAction: true,
    ));
    handle.dispose();
  });

  testWidgets('Dropdown menu includes semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const Key key = Key('test');
    await tester.pumpWidget(buildFrame(
      buttonKey: key,
      value: null,
      items: menuItems,
      onChanged: onChanged,
    ));
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(
              flags: <SemanticsFlag>[
                SemanticsFlag.scopesRoute,
                SemanticsFlag.namesRoute,
              ],
              label: 'Popup menu',
              children: <TestSemantics>[
                TestSemantics(
                  children: <TestSemantics>[
                    TestSemantics(
                      flags: <SemanticsFlag>[
                        SemanticsFlag.hasImplicitScrolling,
                      ],
                      children: <TestSemantics>[
                        TestSemantics(
                          label: 'one',
                          textDirection: TextDirection.ltr,
                          tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                          actions: <SemanticsAction>[SemanticsAction.tap],
                        ),
                        TestSemantics(
                          label: 'two',
                          textDirection: TextDirection.ltr,
                          tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                          actions: <SemanticsAction>[SemanticsAction.tap],
                        ),
                        TestSemantics(
                          label: 'three',
                          textDirection: TextDirection.ltr,
                          tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                          actions: <SemanticsAction>[SemanticsAction.tap],
                        ),
                        TestSemantics(
                          label: 'four',
                          textDirection: TextDirection.ltr,
                          tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                          actions: <SemanticsAction>[SemanticsAction.tap],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ), ignoreId: true, ignoreRect: true, ignoreTransform: true));
    semantics.dispose();
  });

  testWidgets('disabledHint displays on empty items or onChanged', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();

    Widget build({ List<String> items, ValueChanged<String> onChanged }) => buildFrame(
      items: items,
      onChanged: onChanged,
      buttonKey: buttonKey, value: null,
      hint: const Text('enabled'),
      disabledHint: const Text('disabled'));

    // [disabledHint] should display when [items] is null
    await tester.pumpWidget(build(items: null, onChanged: onChanged));
    expect(find.text('enabled'), findsNothing);
    expect(find.text('disabled'), findsOneWidget);

    // [disabledHint] should display when [items] is an empty list.
    await tester.pumpWidget(build(items: <String>[], onChanged: onChanged));
    expect(find.text('enabled'), findsNothing);
    expect(find.text('disabled'), findsOneWidget);

    // [disabledHint] should display when [onChanged] is null
    await tester.pumpWidget(build(items: menuItems, onChanged: null));
    expect(find.text('enabled'), findsNothing);
    expect(find.text('disabled'), findsOneWidget);
    final RenderBox disabledHintBox = tester.renderObject<RenderBox>(find.byKey(buttonKey));

    // A Dropdown button with a disabled hint should be the same size as a
    // one with a regular enabled hint.
    await tester.pumpWidget(build(items: menuItems, onChanged: onChanged));
    expect(find.text('disabled'), findsNothing);
    expect(find.text('enabled'), findsOneWidget);
    final RenderBox enabledHintBox = tester.renderObject<RenderBox>(find.byKey(buttonKey));
    expect(enabledHintBox.localToGlobal(Offset.zero), equals(disabledHintBox.localToGlobal(Offset.zero)));
    expect(enabledHintBox.size, equals(disabledHintBox.size));
  });

  testWidgets('Dropdown in middle showing middle item', (WidgetTester tester) async {
    final List<DropdownMenuItem<int>> items =
      List<DropdownMenuItem<int>>.generate(100, (int i) =>
        DropdownMenuItem<int>(value: i, child: Text('$i')));

    final DropdownButton<int> button = DropdownButton<int>(
      value: 50,
      onChanged: (int newValue) { },
      items: items,
    );

    double getMenuScroll() {
      double scrollPosition;
      final ListView listView = tester.element(find.byType(ListView)).widget;
      final ScrollController scrollController = listView.controller;
      assert(scrollController != null);
      scrollPosition = scrollController.position.pixels;
      assert(scrollPosition != null);
      return scrollPosition;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Align(
            alignment: Alignment.center,
            child: button,
          ),
        ),
      ),
    );

    await tester.tap(find.text('50'));
    await tester.pumpAndSettle();
    expect(getMenuScroll(), 2180.0);
  });

  testWidgets('Dropdown in top showing bottom item', (WidgetTester tester) async {
    final List<DropdownMenuItem<int>> items =
      List<DropdownMenuItem<int>>.generate(100, (int i) =>
        DropdownMenuItem<int>(value: i, child: Text('$i')));

    final DropdownButton<int> button = DropdownButton<int>(
      value: 99,
      onChanged: (int newValue) { },
      items: items,
    );

    double getMenuScroll() {
      double scrollPosition;
      final ListView listView = tester.element(find.byType(ListView)).widget;
      final ScrollController scrollController = listView.controller;
      assert(scrollController != null);
      scrollPosition = scrollController.position.pixels;
      assert(scrollPosition != null);
      return scrollPosition;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Align(
            alignment: Alignment.topCenter,
            child: button,
          ),
        ),
      ),
    );

    await tester.tap(find.text('99'));
    await tester.pumpAndSettle();
    expect(getMenuScroll(), 4312.0);
  });

  testWidgets('Dropdown in bottom showing top item', (WidgetTester tester) async {
    final List<DropdownMenuItem<int>> items =
      List<DropdownMenuItem<int>>.generate(100, (int i) =>
        DropdownMenuItem<int>(value: i, child: Text('$i')));

    final DropdownButton<int> button = DropdownButton<int>(
      value: 0,
      onChanged: (int newValue) { },
      items: items,
    );

    double getMenuScroll() {
      double scrollPosition;
      final ListView listView = tester.element(find.byType(ListView)).widget;
      final ScrollController scrollController = listView.controller;
      assert(scrollController != null);
      scrollPosition = scrollController.position.pixels;
      assert(scrollPosition != null);
      return scrollPosition;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: button,
          ),
        ),
      ),
    );

    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();
    expect(getMenuScroll(), 0.0);
  });

  testWidgets('Dropdown in center showing bottom item', (WidgetTester tester) async {
    final List<DropdownMenuItem<int>> items =
      List<DropdownMenuItem<int>>.generate(100, (int i) =>
        DropdownMenuItem<int>(value: i, child: Text('$i')));

    final DropdownButton<int> button = DropdownButton<int>(
      value: 99,
      onChanged: (int newValue) { },
      items: items,
    );

    double getMenuScroll() {
      double scrollPosition;
      final ListView listView = tester.element(find.byType(ListView)).widget;
      final ScrollController scrollController = listView.controller;
      assert(scrollController != null);
      scrollPosition = scrollController.position.pixels;
      assert(scrollPosition != null);
      return scrollPosition;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Align(
            alignment: Alignment.center,
            child: button,
          ),
        ),
      ),
    );

    await tester.tap(find.text('99'));
    await tester.pumpAndSettle();
    expect(getMenuScroll(), 4312.0);
  });

  testWidgets('Dropdown menu respects parent size limits', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/24417

    int selectedIndex;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: const SizedBox(height: 200),
          body: Navigator(
            onGenerateRoute: (RouteSettings settings) {
              return MaterialPageRoute<void>(
                builder: (BuildContext context) {
                  return SafeArea(
                    child: Container(
                      alignment: Alignment.topLeft,
                      // From material/dropdown.dart (menus are unaligned by default):
                      //  _kUnalignedMenuMargin = EdgeInsetsDirectional.only(start: 16.0, end: 24.0)
                      // This padding ensures that the entire menu will be visible
                      padding: const EdgeInsetsDirectional.only(start: 16.0, end: 24.0),
                      child: DropdownButton<int>(
                        value: 12,
                        onChanged: (int i) { selectedIndex = i; },
                        items: List<DropdownMenuItem<int>>.generate(100, (int i) {
                          return DropdownMenuItem<int>(value: i, child: Text('$i'));
                        }),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(selectedIndex, null);

    await tester.tap(find.text('13').last);
    await tester.pumpAndSettle();
    expect(selectedIndex, 13);
  });

  testWidgets('Dropdown button will accept widgets as its underline', (
      WidgetTester tester) async {

    const BoxDecoration decoration = BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFCCBB00), width: 4.0)),
    );
    const BoxDecoration defaultDecoration = BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFBDBDBD), width: 0.0)),
    );

    final Widget customUnderline = Container(height: 4.0, decoration: decoration);
    final Key buttonKey = UniqueKey();

    final Finder decoratedBox = find.descendant(
      of: find.byKey(buttonKey),
      matching: find.byType(DecoratedBox),
    );

    await tester.pumpWidget(buildFrame(buttonKey: buttonKey, underline: customUnderline,
        value: 'two', onChanged: onChanged));
    expect(tester.widget<DecoratedBox>(decoratedBox).decoration, decoration);

    await tester.pumpWidget(buildFrame(buttonKey: buttonKey, value: 'two', onChanged: onChanged));
    expect(tester.widget<DecoratedBox>(decoratedBox).decoration, defaultDecoration);
  });

    testWidgets('Dropdown form field with autovalidation test', (WidgetTester tester) async {
    String value = 'one';
    int _validateCalled = 0;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MaterialApp(
            home: Material(
              child: DropdownButtonFormField<String>(
                value: value,
                hint: const Text('Select Value'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.fastfood)
                ),
                items: menuItems.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
                validator: (String currentValue) {
                  _validateCalled++;
                  return currentValue == null ? 'Must select value' : null;
                },
                autovalidate: true,
              ),
            ),
          );
        },
      ),
    );

    expect(_validateCalled, 1);
    expect(value, equals('one'));
    await tester.tap(find.text('one'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('three').last);
    await tester.pump();
    expect(_validateCalled, 2);
    await tester.pumpAndSettle();
    expect(value, equals('three'));
  });

  testWidgets('Arrow icon aligns with the edge of button in form field when expanded', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();

    // There shouldn't be overflow when expanded although list contains longer items.
    final List<String> items = <String>[
      '1234567890',
      'abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890',
    ];

    await tester.pumpWidget(
      buildFormFrame(
        buttonKey: buttonKey,
        value: '1234567890',
        isExpanded: true,
        onChanged: onChanged,
        items: items,
      ),
    );
    final RenderBox buttonBox = tester.renderObject<RenderBox>(
      find.byKey(buttonKey),
    );
    expect(buttonBox.attached, isTrue);

    final RenderBox arrowIcon = tester.renderObject<RenderBox>(
      find.byIcon(Icons.arrow_drop_down),
    );
    expect(arrowIcon.attached, isTrue);

    // Arrow icon should be aligned with far right of button when expanded
    expect(
      arrowIcon.localToGlobal(Offset.zero).dx,
      buttonBox.size.centerRight(Offset(-arrowIcon.size.width, 0.0)).dx,
    );
  });

  testWidgets('Dropdown button form field with isDense:true aligns selected menu item', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();
    const String value = 'two';

    await tester.pumpWidget(
      buildFormFrame(
        buttonKey: buttonKey,
        value: value,
        isDense: true,
        onChanged: onChanged,
      ),
    );
    final RenderBox buttonBox = tester.renderObject<RenderBox>(
      find.byKey(buttonKey),
    );
    expect(buttonBox.attached, isTrue);

    await tester.tap(find.text('two'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    // The selected dropdown item is both in menu we just popped up, and in
    // the IndexedStack contained by the dropdown button. Both of them should
    // have the same vertical center as the button.
    final List<RenderBox> itemBoxes = tester.renderObjectList<RenderBox>(
      find.byKey(const ValueKey<String>('two')),
    ).toList();
    expect(itemBoxes.length, equals(2));

    // When isDense is true, the button's height is reduced. The menu items'
    // heights are not.
    final List<double> itemBoxesHeight = itemBoxes.map<double>((RenderBox box) => box.size.height).toList();
    final double menuItemHeight = itemBoxesHeight.reduce(math.max);
    expect(menuItemHeight, greaterThanOrEqualTo(buttonBox.size.height));

    for (RenderBox itemBox in itemBoxes) {
      expect(itemBox.attached, isTrue);
      final Offset buttonBoxCenter = buttonBox.size.center(buttonBox.localToGlobal(Offset.zero));
      final Offset itemBoxCenter = itemBox.size.center(itemBox.localToGlobal(Offset.zero));
      expect(buttonBoxCenter.dy, equals(itemBoxCenter.dy));
    }
  });

  testWidgets('Dropdown button form field - custom text style', (WidgetTester tester) async {
    const String value = 'foo';
    final UniqueKey itemKey = UniqueKey();

    await tester.pumpWidget(
      TestApp(
        textDirection: TextDirection.ltr,
        child: Material(
          child: DropdownButtonFormField<String>(
            value: value,
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                key: itemKey,
                value: 'foo',
                child: const Text(value),
              ),
            ],
            isDense: true,
            onChanged: (_) { },
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 20.0,
            ),
          ),
        ),
      ),
    );

    final RichText richText = tester.widget<RichText>(
      find.descendant(
        of: find.byKey(itemKey),
        matching: find.byType(RichText),
      ),
    );

    expect(richText.text.style.color, Colors.amber);
    expect(richText.text.style.fontSize, 20.0);
  });

  testWidgets('Dropdown form field - disabledHint displays when the items list is empty, when items is null', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();

    Widget build({ List<String> items }){
      return buildFormFrame(
        items: items,
        buttonKey: buttonKey,
        value: null,
        hint: const Text('enabled'),
        disabledHint: const Text('disabled'),
      );
    }
    // [disabledHint] should display when [items] is null
    await tester.pumpWidget(build(items: null));
    expect(find.text('enabled'), findsNothing);
    expect(find.text('disabled'), findsOneWidget);

    // [disabledHint] should display when [items] is an empty list.
    await tester.pumpWidget(build(items: <String>[]));
    expect(find.text('enabled'), findsNothing);
    expect(find.text('disabled'), findsOneWidget);
  });

  testWidgets('Dropdown form field - disabledHint displays when onChanged is null', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();

    Widget build({ List<String> items, ValueChanged<String> onChanged }){
      return buildFormFrame(
        items: items,
        buttonKey: buttonKey,
        value: null,
        onChanged: onChanged,
        hint: const Text('enabled'),
        disabledHint: const Text('disabled'),
      );
    }
    await tester.pumpWidget(build(items: menuItems, onChanged: null));
    expect(find.text('enabled'), findsNothing);
    expect(find.text('disabled'), findsOneWidget);
  });

  testWidgets('Dropdown form field - disabled hint should be of same size as enabled hint', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();

    Widget build({ List<String> items}){
      return buildFormFrame(
        items: items,
        buttonKey: buttonKey,
        value: null,
        hint: const Text('enabled'),
        disabledHint: const Text('disabled'),
      );
    }
    await tester.pumpWidget(build(items: null));
    final RenderBox disabledHintBox = tester.renderObject<RenderBox>(
      find.byKey(buttonKey),
    );

    await tester.pumpWidget(build(items: menuItems));
    final RenderBox enabledHintBox = tester.renderObject<RenderBox>(
      find.byKey(buttonKey),
    );
    expect(enabledHintBox.localToGlobal(Offset.zero), equals(disabledHintBox.localToGlobal(Offset.zero)));
    expect(enabledHintBox.size, equals(disabledHintBox.size));
  });

  testWidgets('Dropdown form field - Custom icon size and colors', (WidgetTester tester) async {
    final Key iconKey = UniqueKey();
    final Icon customIcon = Icon(Icons.assessment, key: iconKey);

    await tester.pumpWidget(buildFormFrame(
      icon: customIcon,
      iconSize: 30.0,
      iconEnabledColor: Colors.pink,
      iconDisabledColor: Colors.orange,
      onChanged: onChanged,
    ));

    // test for size
    final RenderBox icon = tester.renderObject(find.byKey(iconKey));
    expect(icon.size, const Size(30.0, 30.0));

    // test for enabled color
    final RichText enabledRichText = tester.widget<RichText>(_iconRichText(iconKey));
    expect(enabledRichText.text.style.color, Colors.pink);

    // test for disabled color
    await tester.pumpWidget(buildFormFrame(
      icon: customIcon,
      iconSize: 30.0,
      iconEnabledColor: Colors.pink,
      iconDisabledColor: Colors.orange,
      items: null,
    ));

    final RichText disabledRichText = tester.widget<RichText>(_iconRichText(iconKey));
    expect(disabledRichText.text.style.color, Colors.orange);
  });

  testWidgets('Dropdown form field - default elevation', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();
    debugDisableShadows = false;
    await tester.pumpWidget(buildFormFrame(
      buttonKey: buttonKey,
      items: menuItems,
      onChanged: onChanged,
    ));
    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();

    final Finder customPaint = find.ancestor(
      of: find.text('one').last,
      matching: find.byType(CustomPaint),
    ).last;

    // Verifying whether or not default elevation(i.e. 8) paints desired shadow
    verifyPaintedShadow(customPaint, 8);
    debugDisableShadows = true;
  });

  testWidgets('Dropdown form field - custom elevation', (WidgetTester tester) async {
    debugDisableShadows = false;
    final Key buttonKeyOne = UniqueKey();
    final Key buttonKeyTwo = UniqueKey();

    await tester.pumpWidget(buildFormFrame(
      buttonKey: buttonKeyOne,
      items: menuItems,
      elevation: 16,
      onChanged: onChanged,
    ));
    await tester.tap(find.byKey(buttonKeyOne));
    await tester.pumpAndSettle();

    final Finder customPaintOne = find.ancestor(
      of: find.text('one').last,
      matching: find.byType(CustomPaint),
    ).last;

    verifyPaintedShadow(customPaintOne, 16);
    await tester.tap(find.text('one').last);
    await tester.pumpWidget(buildFormFrame(
      buttonKey: buttonKeyTwo,
      items: menuItems,
      elevation: 24,
      onChanged: onChanged,
    ));
    await tester.tap(find.byKey(buttonKeyTwo));
    await tester.pumpAndSettle();

    final Finder customPaintTwo = find.ancestor(
      of: find.text('one').last,
      matching: find.byType(CustomPaint),
    ).last;

    verifyPaintedShadow(customPaintTwo, 24);
    debugDisableShadows = true;
  });
}
