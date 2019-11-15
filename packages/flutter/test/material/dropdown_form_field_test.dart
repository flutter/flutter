// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show window;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../rendering/mock_canvas.dart';

const List<String> menuItems = <String>['one', 'two', 'three', 'four'];
final ValueChanged<String> onChanged = (_) { };

Finder _iconRichText(Key iconKey) {
  return find.descendant(
    of: find.byKey(iconKey),
    matching: find.byType(RichText),
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
        data: MediaQueryData.fromWindow(window).copyWith(size: widget.mediaSize),
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

class TestApp extends StatefulWidget {
  const TestApp({ this.textDirection, this.child, this.mediaSize });
  final TextDirection textDirection;
  final Widget child;
  final Size mediaSize;
  @override
  _TestAppState createState() => _TestAppState();
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

void main() {
  testWidgets('DropdownButtonFormField with autovalidation test', (WidgetTester tester) async {
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

  testWidgets('DropdownButtonFormField arrow icon aligns with the edge of button when expanded', (WidgetTester tester) async {
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

  testWidgets('DropdownButtonFormField with isDense:true aligns selected menu item', (WidgetTester tester) async {
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

  testWidgets('DropdownButtonFormField - custom text style', (WidgetTester tester) async {
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

  testWidgets('DropdownButtonFormField - disabledHint displays when the items list is empty, when items is null', (WidgetTester tester) async {
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

  testWidgets(
    'DropdownButtonFormField - hint displays when the items list is '
    'empty, items is null, and disabledHint is null',
    (WidgetTester tester) async {
      final Key buttonKey = UniqueKey();

      Widget build({ List<String> items }){
        return buildFormFrame(
          items: items,
          buttonKey: buttonKey,
          value: null,
          hint: const Text('hint used when disabled'),
          disabledHint: null,
        );
      }
      // [hint] should display when [items] is null and [disabledHint] is not defined
      await tester.pumpWidget(build(items: null));
      expect(find.text('hint used when disabled'), findsOneWidget);

      // [hint] should display when [items] is an empty list and [disabledHint] is not defined.
      await tester.pumpWidget(build(items: <String>[]));
      expect(find.text('hint used when disabled'), findsOneWidget);
    },
  );

  testWidgets('DropdownButtonFormField - disabledHint is null by default', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();

    Widget build({ List<String> items }){
      return buildFormFrame(
        items: items,
        buttonKey: buttonKey,
        value: null,
        hint: const Text('hint used when disabled'),
      );
    }
    // [hint] should display when [items] is null and [disabledHint] is not defined
    await tester.pumpWidget(build(items: null));
    expect(find.text('hint used when disabled'), findsOneWidget);

    // [hint] should display when [items] is an empty list and [disabledHint] is not defined.
    await tester.pumpWidget(build(items: <String>[]));
    expect(find.text('hint used when disabled'), findsOneWidget);
  });

  testWidgets('DropdownButtonFormField - disabledHint is null by default', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();

    Widget build({ List<String> items }){
      return buildFormFrame(
        items: items,
        buttonKey: buttonKey,
        value: null,
        hint: const Text('hint used when disabled'),
      );
    }
    // [hint] should display when [items] is null and [disabledHint] is not defined
    await tester.pumpWidget(build(items: null));
    expect(find.text('hint used when disabled'), findsOneWidget);

    // [hint] should display when [items] is an empty list and [disabledHint] is not defined.
    await tester.pumpWidget(build(items: <String>[]));
    expect(find.text('hint used when disabled'), findsOneWidget);
  });

  testWidgets('DropdownButtonFormField - disabledHint displays when onChanged is null', (WidgetTester tester) async {
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

  testWidgets('DropdownButtonFormField - disabled hint should be of same size as enabled hint', (WidgetTester tester) async {
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

  testWidgets('DropdownButtonFormField - Custom icon size and colors', (WidgetTester tester) async {
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

  testWidgets('DropdownButtonFormField - default elevation', (WidgetTester tester) async {
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

  testWidgets('DropdownButtonFormField - custom elevation', (WidgetTester tester) async {
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

  testWidgets('DropdownButtonFormField does not allow duplicate item values', (WidgetTester tester) async {
    final List<DropdownMenuItem<String>> itemsWithDuplicateValues = <String>['a', 'b', 'c', 'c']
      .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList();

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownButtonFormField<String>(
              value: 'c',
              onChanged: (String newValue) {},
              items: itemsWithDuplicateValues,
            ),
          ),
        ),
      );

      fail('Should not be possible to have duplicate item value');
    } on AssertionError catch (error) {
      expect(
        error.toString(),
        contains('There should be exactly one item with [DropdownButton]\'s value'),
      );
    }
  });

  testWidgets('DropdownButtonFormField value should only appear in one menu item', (WidgetTester tester) async {
    final List<DropdownMenuItem<String>> itemsWithDuplicateValues = <String>['a', 'b', 'c', 'd']
      .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList();

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownButton<String>(
              value: 'e',
              onChanged: (String newValue) {},
              items: itemsWithDuplicateValues,
            ),
          ),
        ),
      );

      fail('Should not be possible to have no items with passed in value');
    } on AssertionError catch (error) {
      expect(
        error.toString(),
        contains('There should be exactly one item with [DropdownButton]\'s value'),
      );
    }
  });
}