// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show window;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../widgets/semantics_tester.dart';

const List<String> menuItems = const <String>['one', 'two', 'three', 'four'];

final Type dropdownButtonType = new DropdownButton<String>(
  onChanged: (_) { },
  items: const <DropdownMenuItem<String>>[]
).runtimeType;

Widget buildFrame({
  Key buttonKey,
  String value: 'two',
  ValueChanged<String> onChanged,
  bool isDense: false,
  Widget hint,
  List<String> items: menuItems,
  Alignment alignment: Alignment.center,
  TextDirection textDirection: TextDirection.ltr,
}) {
  return new TestApp(
    textDirection: textDirection,
    child: new Material(
      child: new Align(
        alignment: alignment,
        child: new DropdownButton<String>(
          key: buttonKey,
          value: value,
          hint: hint,
          onChanged: onChanged,
          isDense: isDense,
          items: items.map((String item) {
            return new DropdownMenuItem<String>(
              key: new ValueKey<String>(item),
              value: item,
              child: new Text(item, key: new ValueKey<String>(item + 'Text')),
            );
          }).toList(),
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
  _TestAppState createState() => new _TestAppState();
}

class _TestAppState extends State<TestApp> {
  @override
  Widget build(BuildContext context) {
    return new Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: new MediaQuery(
        data: new MediaQueryData.fromWindow(window),
        child: new Directionality(
          textDirection: widget.textDirection,
          child: new Navigator(
            onGenerateRoute: (RouteSettings settings) {
              assert(settings.name == '/');
              return new MaterialPageRoute<dynamic>(
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
  final List<RenderBox> boxes = tester.renderObjectList<RenderBox>(find.byKey(new ValueKey<String>(value + 'Text'))).toList();
  expect(boxes.length, equals(2));
  final RenderBox box0 = boxes[0];
  final RenderBox box1 = boxes[1];
  expect(box0.localToGlobal(Offset.zero), equals(box1.localToGlobal(Offset.zero)));
  expect(box0.size, equals(box1.size));
}

bool sameGeometry(RenderBox box1, RenderBox box2) {
  expect(box1.localToGlobal(Offset.zero), equals(box2.localToGlobal(Offset.zero)));
  expect(box1.size.height, equals(box2.size.height));
  return true;
}

void main() {
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
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new Navigator(
          initialRoute: '/',
          onGenerateRoute: (RouteSettings settings) {
            return new MaterialPageRoute<Null>(
              settings: settings,
              builder: (BuildContext context) {
                return new Material(
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
    final UniqueKey itemKey = new UniqueKey();
    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new ListView(
            children: <Widget>[
              new DropdownButton<String>(
                value: value,
                items: <DropdownMenuItem<String>>[
                  new DropdownMenuItem<String>(
                    key: itemKey,
                    value: value,
                    child: const Text(value),
                  ),
                ],
                onChanged: (_) {},
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
      items.add(new DropdownMenuItem<int>(value: i, child: new Text('$i')));

    void handleChanged(int newValue) {
      value = newValue;
    }

    final DropdownButton<int> button = new DropdownButton<int>(
      value: value,
      onChanged: handleChanged,
      items: items,
    );

    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Align(
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
      final Key buttonKey = new UniqueKey();
      const String value = 'two';

      Widget build() => buildFrame(buttonKey: buttonKey, value: value, textDirection: textDirection);

      await tester.pumpWidget(build());
      final RenderBox buttonBox = tester.renderObject(find.byKey(buttonKey));
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
      final List<RenderObject> itemBoxes = tester.renderObjectList(find.byKey(const ValueKey<String>('two'))).toList();
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

      await tester.pumpWidget(new Container()); // reset test
    });
  }

  testWidgets('Dropdown button with isDense:true aligns selected menu item', (WidgetTester tester) async {
    final Key buttonKey = new UniqueKey();
    const String value = 'two';

    Widget build() => buildFrame(buttonKey: buttonKey, value: value, isDense: true);

    await tester.pumpWidget(build());
    final RenderBox buttonBox = tester.renderObject(find.byKey(buttonKey));
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
    final double menuItemHeight = itemBoxes.map((RenderBox box) => box.size.height).reduce(math.max);
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

  testWidgets('Size of DropdownButton with null value', (WidgetTester tester) async {
    final Key buttonKey = new UniqueKey();
    String value;

    Widget build() => buildFrame(buttonKey: buttonKey, value: value);

    await tester.pumpWidget(build());
    final RenderBox buttonBoxNullValue = tester.renderObject(find.byKey(buttonKey));
    assert(buttonBoxNullValue.attached);


    value = 'three';
    await tester.pumpWidget(build());
    final RenderBox buttonBox = tester.renderObject(find.byKey(buttonKey));
    assert(buttonBox.attached);

    // A Dropdown button with a null value should be the same size as a
    // one with a non-null value.
    expect(buttonBox.localToGlobal(Offset.zero), equals(buttonBoxNullValue.localToGlobal(Offset.zero)));
    expect(buttonBox.size, equals(buttonBoxNullValue.size));
  });

  testWidgets('Layout of a DropdownButton with null value', (WidgetTester tester) async {
    final Key buttonKey = new UniqueKey();
    String value;

    void onChanged(String newValue) {
      value = newValue;
    }

    Widget build() => buildFrame(buttonKey: buttonKey, value: value, onChanged: onChanged);

    await tester.pumpWidget(build());
    final RenderBox buttonBox = tester.renderObject(find.byKey(buttonKey));
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
    final Key buttonKey = new UniqueKey();
    String value;

    // The hint will define the dropdown's width
    Widget build() => buildFrame(buttonKey: buttonKey, value: value, hint: const Text('onetwothree'));

    await tester.pumpWidget(build());
    expect(find.text('onetwothree'), findsOneWidget);
    final RenderBox buttonBoxHintValue = tester.renderObject(find.byKey(buttonKey));
    assert(buttonBoxHintValue.attached);


    value = 'three';
    await tester.pumpWidget(build());
    final RenderBox buttonBox = tester.renderObject(find.byKey(buttonKey));
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
    const EdgeInsets buttonPadding = const EdgeInsets.only(top: 8.0, left: 16.0, right: 24.0);

    Rect getExpandedButtonRect() {
      final RenderBox box = tester.renderObject<RenderBox>(find.byType(dropdownButtonType));
      final Rect buttonRect = box.localToGlobal(Offset.zero) & box.size;
      return buttonPadding.inflateRect(buttonRect);
    }

    Rect buttonRect;
    Rect menuRect;

    Future<Null> popUpAndDown(Widget frame) async {
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
      buildFrame(alignment: Alignment.topLeft, value: menuItems.last)
    );
    expect(menuRect.topLeft, Offset.zero);
    expect(menuRect.topRight, new Offset(menuRect.width, 0.0));

    await popUpAndDown(
      buildFrame(alignment: Alignment.topCenter, value: menuItems.last)
    );
    expect(menuRect.topLeft, new Offset(buttonRect.left, 0.0));
    expect(menuRect.topRight, new Offset(buttonRect.right, 0.0));

    await popUpAndDown(
      buildFrame(alignment: Alignment.topRight, value: menuItems.last)
    );
    expect(menuRect.topLeft, new Offset(800.0 - menuRect.width, 0.0));
    expect(menuRect.topRight, const Offset(800.0, 0.0));

    // Dropdown button is along the middle of the app. The top of the menu is
    // aligned with the top of the expanded button (because the 1st item
    // is selected) and shifted horizontally so that it fits within the frame.

    await popUpAndDown(
      buildFrame(alignment: Alignment.centerLeft, value: menuItems.first)
    );
    expect(menuRect.topLeft, new Offset(0.0, buttonRect.top));
    expect(menuRect.topRight, new Offset(menuRect.width, buttonRect.top));

    await popUpAndDown(
      buildFrame(alignment: Alignment.center, value: menuItems.first)
    );
    expect(menuRect.topLeft, buttonRect.topLeft);
    expect(menuRect.topRight, buttonRect.topRight);

    await popUpAndDown(
      buildFrame(alignment: Alignment.centerRight, value: menuItems.first)
    );
    expect(menuRect.topLeft, new Offset(800.0 - menuRect.width, buttonRect.top));
    expect(menuRect.topRight, new Offset(800.0, buttonRect.top));

    // Dropdown button is along the bottom of the app. The bottom of the menu is
    // aligned with the bottom of the expanded button and shifted horizontally
    // so that it fits within the frame.

    await popUpAndDown(
      buildFrame(alignment: Alignment.bottomLeft, value: menuItems.first)
    );
    expect(menuRect.bottomLeft, const Offset(0.0, 600.0));
    expect(menuRect.bottomRight, new Offset(menuRect.width, 600.0));

    await popUpAndDown(
      buildFrame(alignment: Alignment.bottomCenter, value: menuItems.first)
    );
    expect(menuRect.bottomLeft, new Offset(buttonRect.left, 600.0));
    expect(menuRect.bottomRight, new Offset(buttonRect.right, 600.0));

    await popUpAndDown(
      buildFrame(alignment: Alignment.bottomRight, value: menuItems.first)
    );
    expect(menuRect.bottomLeft, new Offset(800.0 - menuRect.width, 600.0));
    expect(menuRect.bottomRight, const Offset(800.0, 600.0));
  });

  testWidgets('Dropdown menus are dismissed on screen orientation changes', (WidgetTester tester) async {
    await tester.pumpWidget(buildFrame());
    await tester.tap(find.byType(dropdownButtonType));
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsOneWidget);

    window.onMetricsChanged();
    await tester.pump();
    expect(find.byType(ListView, skipOffstage: false), findsNothing);
  });


  testWidgets('Semantics Tree contains only selected element', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(buildFrame(items: menuItems));

    expect(semantics, isNot(includesNodeWith(label: menuItems[0])));
    expect(semantics, includesNodeWith(label: menuItems[1]));
    expect(semantics, isNot(includesNodeWith(label: menuItems[2])));
    expect(semantics, isNot(includesNodeWith(label: menuItems[3])));

    semantics.dispose();
  });
}
