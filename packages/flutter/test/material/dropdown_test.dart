// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math' as math;
import 'dart:ui' show window;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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

Widget buildDropdown({
    bool isFormField,
    Key buttonKey,
    String value = 'two',
    ValueChanged<String> onChanged,
    VoidCallback onTap,
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
    List<Widget> Function(BuildContext) selectedItemBuilder,
    double itemHeight = kMinInteractiveDimension,
    Alignment alignment = Alignment.center,
    TextDirection textDirection = TextDirection.ltr,
    Size mediaSize,
    FocusNode focusNode,
    bool autofocus = false,
    Color focusColor,
    Color dropdownColor,
  }) {
  final List<DropdownMenuItem<String>> listItems = items == null
      ? null
      : items.map<DropdownMenuItem<String>>((String item) {
    return DropdownMenuItem<String>(
      key: ValueKey<String>(item),
      value: item,
      child: Text(item, key: ValueKey<String>(item + 'Text')),
    );
  }).toList();

  if (isFormField) {
    return Form(
      child: DropdownButtonFormField<String>(
        key: buttonKey,
        value: value,
        hint: hint,
        disabledHint: disabledHint,
        onChanged: onChanged,
        onTap: onTap,
        icon: icon,
        iconSize: iconSize,
        iconDisabledColor: iconDisabledColor,
        iconEnabledColor: iconEnabledColor,
        isDense: isDense,
        isExpanded: isExpanded,
        // No underline attribute
        focusNode: focusNode,
        autofocus: autofocus,
        focusColor: focusColor,
        dropdownColor: dropdownColor,
        items: listItems,
        selectedItemBuilder: selectedItemBuilder,
        itemHeight: itemHeight,
      ),
    );
  }
  return DropdownButton<String>(
    key: buttonKey,
    value: value,
    hint: hint,
    disabledHint: disabledHint,
    onChanged: onChanged,
    onTap: onTap,
    icon: icon,
    iconSize: iconSize,
    iconDisabledColor: iconDisabledColor,
    iconEnabledColor: iconEnabledColor,
    isDense: isDense,
    isExpanded: isExpanded,
    underline: underline,
    focusNode: focusNode,
    autofocus: autofocus,
    focusColor: focusColor,
    dropdownColor: dropdownColor,
    items: listItems,
    selectedItemBuilder: selectedItemBuilder,
    itemHeight: itemHeight,
  );
}

Widget buildFrame({
  Key buttonKey,
  String value = 'two',
  ValueChanged<String> onChanged,
  VoidCallback onTap,
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
  List<Widget> Function(BuildContext) selectedItemBuilder,
  double itemHeight = kMinInteractiveDimension,
  Alignment alignment = Alignment.center,
  TextDirection textDirection = TextDirection.ltr,
  Size mediaSize,
  FocusNode focusNode,
  bool autofocus = false,
  Color focusColor,
  Color dropdownColor,
  bool isFormField = false,
}) {
  return TestApp(
    textDirection: textDirection,
    mediaSize: mediaSize,
    child: Material(
      child: Align(
        alignment: alignment,
        child: RepaintBoundary(
          child: buildDropdown(
            isFormField: isFormField,
            buttonKey: buttonKey,
            value: value,
            hint: hint,
            disabledHint: disabledHint,
            onChanged: onChanged,
            onTap: onTap,
            icon: icon,
            iconSize: iconSize,
            iconDisabledColor: iconDisabledColor,
            iconEnabledColor: iconEnabledColor,
            isDense: isDense,
            isExpanded: isExpanded,
            underline: underline,
            focusNode: focusNode,
            autofocus: autofocus,
            focusColor: focusColor,
            dropdownColor: dropdownColor,
            items: items,
            selectedItemBuilder: selectedItemBuilder,
            itemHeight: itemHeight,),
        ),
      ),
    ),
  );
}

class TestApp extends StatefulWidget {
  const TestApp({
    Key key,
    this.textDirection,
    this.child,
    this.mediaSize,
  }) : super(key: key);

  final TextDirection textDirection;
  final Widget child;
  final Size mediaSize;

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

Future<void> checkDropdownColor(WidgetTester tester, {Color color, bool isFormField = false }) async {
  const String text = 'foo';
  await tester.pumpWidget(
    MaterialApp(
      home: Material(
        child: isFormField
            ? Form(
                child: DropdownButtonFormField<String>(
                  dropdownColor: color,
                  value: text,
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: text,
                      child: Text(text),
                    ),
                  ],
                  onChanged: (_) {},
                ),
              )
            : DropdownButton<String>(
                dropdownColor: color,
                value: text,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: text,
                    child: Text(text),
                  ),
                ],
                onChanged: (_) {},
              ),
      ),
    ),
  );
  await tester.tap(find.text(text));
  await tester.pump();

  expect(
    find.ancestor(
      of: find.text(text).last,
      matching: find.byType(CustomPaint)).at(2),
    paints
      ..save()
      ..rrect()
      ..rrect()
      ..rrect()
      ..rrect(color: color ?? Colors.grey[50], hasMaskFilter: false)
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
      matchesGoldenFile('dropdown_test.default.png'),
    );
  });

  testWidgets('Expanded dropdown golden', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();
    Widget build() => buildFrame(buttonKey: buttonKey, value: 'two', isExpanded: true, onChanged: onChanged);
    await tester.pumpWidget(build());
    final Finder buttonFinder = find.byKey(buttonKey);
    assert(tester.renderObject(buttonFinder).attached);
    await expectLater(
      find.ancestor(of: buttonFinder, matching: find.byType(RepaintBoundary)).first,
      matchesGoldenFile('dropdown_test.expanded.png'),
    );
  });

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

  testWidgets('DropdownButton does not allow duplicate item values', (WidgetTester tester) async {
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
            body: DropdownButton<String>(
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
        contains("There should be exactly one item with [DropdownButton]'s value"),
      );
    }
  });

  testWidgets('DropdownButton value should only appear in one menu item', (WidgetTester tester) async {
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
        contains("There should be exactly one item with [DropdownButton]'s value"),
      );
    }
  });

  testWidgets('Dropdown form field uses form field state', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String value;
    await tester.pumpWidget(
        StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return MaterialApp(
                home: Material(
                  child: Form(
                    key: formKey,
                    child: DropdownButtonFormField<String>(
                      key: buttonKey,
                      value: value,
                      hint: const Text('Select Value'),
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.fastfood)
                      ),
                      items: menuItems.map((String val) {
                        return DropdownMenuItem<String>(
                            value: val,
                            child: Text(val)
                        );
                      }).toList(),
                      validator: (String v) => v == null ? 'Must select value' : null,
                      onChanged: (String newValue) {},
                      onSaved: (String v) {
                        setState(() {
                          value = v;
                        });
                      },
                    ),
                  ),
                ),
              );
            }
        )
    );
    int getIndex() {
      final IndexedStack stack = tester.element(find.byType(IndexedStack)).widget as IndexedStack;
      return stack.index;
    }
    // Initial value of null displays hint
    expect(value, equals(null));
    expect(getIndex(), 4);
    await tester.tap(find.text('Select Value'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('three').last);
    await tester.pumpAndSettle();
    expect(getIndex(), 2);
    // Changes only made to FormField state until form saved
    expect(value, equals(null));
    final FormState form = formKey.currentState;
    form.save();
    expect(value, equals('three'));
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
    final List<DropdownMenuItem<int>> items = <DropdownMenuItem<int>>[
      for (int i = 0; i < 20; ++i) DropdownMenuItem<int>(value: i, child: Text('$i')),
    ];

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

  for (final TextDirection textDirection in TextDirection.values) {
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
      final List<RenderBox> itemBoxes = tester.renderObjectList<RenderBox>(find.byKey(const ValueKey<String>('two'))).toList();
      expect(itemBoxes.length, equals(2));
      for (final RenderBox itemBox in itemBoxes) {
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

    for (final RenderBox itemBox in itemBoxes) {
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
          final RenderBox box = element.findRenderObject() as RenderBox;
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

  testWidgets('Dropdown menus are dismissed on screen orientation changes, but not on keyboard hide', (WidgetTester tester) async {
    await tester.pumpWidget(buildFrame(onChanged: onChanged, mediaSize: const Size(800, 600)));
    await tester.tap(find.byType(dropdownButtonType));
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsOneWidget);

    // Show a keyboard (simulate by shortening the height).
    await tester.pumpWidget(buildFrame(onChanged: onChanged, mediaSize: const Size(800, 300)));
    await tester.pump();
    expect(find.byType(ListView, skipOffstage: false), findsOneWidget);

    // Hide a keyboard again (simulate by increasing the height).
    await tester.pumpWidget(buildFrame(onChanged: onChanged, mediaSize: const Size(800, 600)));
    await tester.pump();
    expect(find.byType(ListView, skipOffstage: false), findsOneWidget);

    // Rotate the device (simulate by changing the aspect ratio).
    await tester.pumpWidget(buildFrame(onChanged: onChanged, mediaSize: const Size(600, 800)));
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
      isFocusable: true,
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
      isFocusable: true,
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
                              flags: <SemanticsFlag>[
                                SemanticsFlag.isFocused,
                                SemanticsFlag.isFocusable,
                              ],
                              tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                            ),
                            TestSemantics(
                              label: 'two',
                              textDirection: TextDirection.ltr,
                              flags: <SemanticsFlag>[SemanticsFlag.isFocusable],
                              tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                            ),
                            TestSemantics(
                              label: 'three',
                              textDirection: TextDirection.ltr,
                              flags: <SemanticsFlag>[SemanticsFlag.isFocusable],
                              tags: <SemanticsTag>[const SemanticsTag('RenderViewport.twoPane')],
                              actions: <SemanticsAction>[SemanticsAction.tap],
                            ),
                            TestSemantics(
                              label: 'four',
                              textDirection: TextDirection.ltr,
                              flags: <SemanticsFlag>[SemanticsFlag.isFocusable],
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
            TestSemantics(),
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
      buttonKey: buttonKey,
      value: null,
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

  testWidgets(
    'DropdowwnButton hint displays when the items list is empty, '
    'items is null, and disabledHint is null',
    (WidgetTester tester) async {
      final Key buttonKey = UniqueKey();

      Widget build({ List<String> items }){
        return buildFrame(
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

  testWidgets('DropdownButton disabledHint is null by default', (WidgetTester tester) async {
    final Key buttonKey = UniqueKey();

    Widget build({ List<String> items }){
      return buildFrame(
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

  testWidgets('Size of largest widget is used DropdownButton when selectedItemBuilder is non-null', (WidgetTester tester) async {
    final List<String> items = <String>['25', '50', '100'];
    const String selectedItem = '25';

    await tester.pumpWidget(buildFrame(
      // To test the size constraints, the selected item should not be the
      // largest item. This validates that the button sizes itself according
      // to the largest item regardless of which one is selected.
      value: selectedItem,
      items: items,
      itemHeight: null,
      selectedItemBuilder: (BuildContext context) {
        return items.map<Widget>((String item) {
          return Container(
            height: double.parse(item),
            width: double.parse(item),
            child: Center(child: Text(item)),
          );
        }).toList();
      },
      onChanged: (String newValue) {},
    ));

    final RenderBox dropdownButtonRenderBox = tester.renderObject<RenderBox>(
      find.widgetWithText(Row, '25'),
    );
    // DropdownButton should be the height of the largest item
    expect(dropdownButtonRenderBox.size.height, 100);
    // DropdownButton should be width of largest item added to the icon size
    expect(dropdownButtonRenderBox.size.width, 100 + 24.0);
  });

  testWidgets(
    'Enabled button - Size of largest widget is used DropdownButton when selectedItemBuilder '
    'is non-null and hint is defined, but smaller than largest selected item widget',
    (WidgetTester tester) async {
      final List<String> items = <String>['25', '50', '100'];

      await tester.pumpWidget(buildFrame(
        value: null,
        // [hint] widget is smaller than largest selected item widget
        hint: Container(
          height: 50,
          width: 50,
          child: const Text('hint')
        ),
        items: items,
        itemHeight: null,
        selectedItemBuilder: (BuildContext context) {
          return items.map<Widget>((String item) {
            return Container(
              height: double.parse(item),
              width: double.parse(item),
              child: Center(child: Text(item)),
            );
          }).toList();
        },
        onChanged: (String newValue) {},
      ));

      final RenderBox dropdownButtonRenderBox = tester.renderObject<RenderBox>(
        find.widgetWithText(Row, 'hint'),
      );
      // DropdownButton should be the height of the largest item
      expect(dropdownButtonRenderBox.size.height, 100);
      // DropdownButton should be width of largest item added to the icon size
      expect(dropdownButtonRenderBox.size.width, 100 + 24.0);
    },
  );

  testWidgets(
    'Enabled button - Size of largest widget is used DropdownButton when selectedItemBuilder '
    'is non-null and hint is defined, but larger than largest selected item widget',
    (WidgetTester tester) async {
      final List<String> items = <String>['25', '50', '100'];
      const String selectedItem = '25';

      await tester.pumpWidget(buildFrame(
        // To test the size constraints, the selected item should not be the
        // largest item. This validates that the button sizes itself according
        // to the largest item regardless of which one is selected.
        value: selectedItem,
        // [hint] widget is larger than largest selected item widget
        hint: Container(
          height: 125,
          width: 125,
          child: const Text('hint')
        ),
        items: items,
        itemHeight: null,
        selectedItemBuilder: (BuildContext context) {
          return items.map<Widget>((String item) {
            return Container(
              height: double.parse(item),
              width: double.parse(item),
              child: Center(child: Text(item)),
            );
          }).toList();
        },
        onChanged: (String newValue) {},
      ));

      final RenderBox dropdownButtonRenderBox = tester.renderObject<RenderBox>(
        find.widgetWithText(Row, '25'),
      );
      // DropdownButton should be the height of the largest item (hint inclusive)
      expect(dropdownButtonRenderBox.size.height, 125);
      // DropdownButton should be width of largest item (hint inclusive) added to the icon size
      expect(dropdownButtonRenderBox.size.width, 125 + 24.0);
    },
  );

  testWidgets(
    'Disabled button - Size of largest widget is used DropdownButton when selectedItemBuilder '
    'is non-null, and hint is defined, but smaller than largest selected item widget',
    (WidgetTester tester) async {
      final List<String> items = <String>['25', '50', '100'];

      await tester.pumpWidget(buildFrame(
        value: null,
        // [hint] widget is smaller than largest selected item widget
        hint: Container(
          height: 50,
          width: 50,
          child: const Text('hint')
        ),
        items: items,
        itemHeight: null,
        selectedItemBuilder: (BuildContext context) {
          return items.map<Widget>((String item) {
            return Container(
              height: double.parse(item),
              width: double.parse(item),
              child: Center(child: Text(item)),
            );
          }).toList();
        },
        onChanged: null,
      ));

      final RenderBox dropdownButtonRenderBox = tester.renderObject<RenderBox>(
        find.widgetWithText(Row, 'hint'),
      );
      // DropdownButton should be the height of the largest item
      expect(dropdownButtonRenderBox.size.height, 100);
      // DropdownButton should be width of largest item added to the icon size
      expect(dropdownButtonRenderBox.size.width, 100 + 24.0);
    },
  );

  testWidgets(
    'Disabled button - Size of largest widget is used DropdownButton when selectedItemBuilder '
    'is non-null and hint is defined, but larger than largest selected item widget',
    (WidgetTester tester) async {
      final List<String> items = <String>['25', '50', '100'];

      await tester.pumpWidget(buildFrame(
        value: null,
        // [hint] widget is larger than largest selected item widget
        hint: Container(
          height: 125,
          width: 125,
          child: const Text('hint')
        ),
        items: items,
        itemHeight: null,
        selectedItemBuilder: (BuildContext context) {
          return items.map<Widget>((String item) {
            return Container(
              height: double.parse(item),
              width: double.parse(item),
              child: Center(child: Text(item)),
            );
          }).toList();
        },
        onChanged: null,
      ));

      final RenderBox dropdownButtonRenderBox = tester.renderObject<RenderBox>(
        find.widgetWithText(Row, '25'),
      );
      // DropdownButton should be the height of the largest item (hint inclusive)
      expect(dropdownButtonRenderBox.size.height, 125);
      // DropdownButton should be width of largest item (hint inclusive) added to the icon size
      expect(dropdownButtonRenderBox.size.width, 125 + 24.0);
    },
  );

  testWidgets(
    'Disabled button - Size of largest widget is used DropdownButton when selectedItemBuilder '
    'is non-null, and disabledHint is defined, but smaller than largest selected item widget',
    (WidgetTester tester) async {
      final List<String> items = <String>['25', '50', '100'];

      await tester.pumpWidget(buildFrame(
        value: null,
        // [hint] widget is smaller than largest selected item widget
        disabledHint: Container(
          height: 50,
          width: 50,
          child: const Text('hint')
        ),
        items: items,
        itemHeight: null,
        selectedItemBuilder: (BuildContext context) {
          return items.map<Widget>((String item) {
            return Container(
              height: double.parse(item),
              width: double.parse(item),
              child: Center(child: Text(item)),
            );
          }).toList();
        },
        onChanged: null,
      ));

      final RenderBox dropdownButtonRenderBox = tester.renderObject<RenderBox>(
        find.widgetWithText(Row, 'hint'),
      );
      // DropdownButton should be the height of the largest item
      expect(dropdownButtonRenderBox.size.height, 100);
      // DropdownButton should be width of largest item added to the icon size
      expect(dropdownButtonRenderBox.size.width, 100 + 24.0);
    },
  );

  testWidgets(
    'Disabled button - Size of largest widget is used DropdownButton when selectedItemBuilder '
    'is non-null and disabledHint is defined, but larger than largest selected item widget',
    (WidgetTester tester) async {
      final List<String> items = <String>['25', '50', '100'];

      await tester.pumpWidget(buildFrame(
        value: null,
        // [hint] widget is larger than largest selected item widget
        disabledHint: Container(
          height: 125,
          width: 125,
          child: const Text('hint')
        ),
        items: items,
        itemHeight: null,
        selectedItemBuilder: (BuildContext context) {
          return items.map<Widget>((String item) {
            return Container(
              height: double.parse(item),
              width: double.parse(item),
              child: Center(child: Text(item)),
            );
          }).toList();
        },
        onChanged: null,
      ));

      final RenderBox dropdownButtonRenderBox = tester.renderObject<RenderBox>(
        find.widgetWithText(Row, '25'),
      );
      // DropdownButton should be the height of the largest item (hint inclusive)
      expect(dropdownButtonRenderBox.size.height, 125);
      // DropdownButton should be width of largest item (hint inclusive) added to the icon size
      expect(dropdownButtonRenderBox.size.width, 125 + 24.0);
    },
  );

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
      final ListView listView = tester.element(find.byType(ListView)).widget as ListView;
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
      final ListView listView = tester.element(find.byType(ListView)).widget as ListView;
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
      final ListView listView = tester.element(find.byType(ListView)).widget as ListView;
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
      final ListView listView = tester.element(find.byType(ListView)).widget as ListView;
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

  testWidgets('Dropdown button will accept widgets as its underline', (WidgetTester tester) async {
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
    expect(tester.widgetList<DecoratedBox>(decoratedBox).last.decoration, decoration);

    await tester.pumpWidget(buildFrame(buttonKey: buttonKey, value: 'two', onChanged: onChanged));
    expect(tester.widgetList<DecoratedBox>(decoratedBox).last.decoration, defaultDecoration);
  });

  testWidgets('DropdownButton selectedItemBuilder builds custom buttons', (WidgetTester tester) async {
    const List<String> items = <String>[
      'One',
      'Two',
      'Three',
    ];
    String selectedItem = items[0];

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MaterialApp(
            home: Scaffold(
              body: DropdownButton<String>(
                value: selectedItem,
                onChanged: (String string) => setState(() => selectedItem = string),
                selectedItemBuilder: (BuildContext context) {
                  int index = 0;
                  return items.map((String string) {
                    index += 1;
                    return Text('$string as an Arabic numeral: $index');
                  }).toList();
                },
                items: items.map((String string) {
                  return DropdownMenuItem<String>(
                    child: Text(string),
                    value: string,
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );

    expect(find.text('One as an Arabic numeral: 1'), findsOneWidget);
    await tester.tap(find.text('One as an Arabic numeral: 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Two'));
    await tester.pumpAndSettle();
    expect(find.text('Two as an Arabic numeral: 2'), findsOneWidget);
  });

  testWidgets('DropdownButton uses default color when expanded', (WidgetTester tester) async {
    await checkDropdownColor(tester);
  });

  testWidgets('DropdownButton uses dropdownColor when expanded', (WidgetTester tester) async {
    await checkDropdownColor(tester, color: const Color.fromRGBO(120, 220, 70, 0.8));
  });

  testWidgets('DropdownButtonFormField uses dropdownColor when expanded', (WidgetTester tester) async {
    await checkDropdownColor(tester, color: const Color.fromRGBO(120, 220, 70, 0.8), isFormField: true);
  });

  testWidgets('DropdownButton hint displays properly when selectedItemBuilder is defined', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/42340
    final List<String> items = <String>['1', '2', '3'];
    String selectedItem;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MaterialApp(
            home: Scaffold(
              body: DropdownButton<String>(
                hint: const Text('Please select an item'),
                value: selectedItem,
                onChanged: (String string) => setState(() {
                  selectedItem = string;
                }),
                selectedItemBuilder: (BuildContext context) {
                  return items.map<Widget>((String item) {
                    return Text('You have selected: $item');
                  }).toList();
                },
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    child: Text(item),
                    value: item,
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );

    // Initially shows the hint text
    expect(find.text('Please select an item'), findsOneWidget);
    await tester.tap(find.text('Please select an item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    // Selecting an item should display its corresponding item builder
    expect(find.text('You have selected: 1'), findsOneWidget);
  });

  testWidgets('Variable size and oversized menu items', (WidgetTester tester) async {
    final List<double> itemHeights = <double>[30, 40, 50, 60];
    double dropdownValue = itemHeights[0];

    Widget buildFrame() {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return DropdownButton<double>(
                  onChanged: (double value) {
                    setState(() { dropdownValue = value; });
                  },
                  value: dropdownValue,
                  itemHeight: null,
                  items: itemHeights.map<DropdownMenuItem<double>>((double value) {
                    return DropdownMenuItem<double>(
                      key: ValueKey<double>(value),
                      value: value,
                      child: Center(
                        child: Container(
                          width: 100,
                          height: value,
                          color: Colors.blue,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      );
    }

    final Finder dropdownIcon = find.byType(Icon);
    final Finder item30 = find.byKey(const ValueKey<double>(30));
    final Finder item40 = find.byKey(const ValueKey<double>(40));
    final Finder item50 = find.byKey(const ValueKey<double>(50));
    final Finder item60 = find.byKey(const ValueKey<double>(60));

    // Only the DropdownButton is visible. It contains the selected item
    // and a dropdown arrow icon.
    await tester.pumpWidget(buildFrame());
    expect(dropdownIcon, findsOneWidget);
    expect(item30, findsOneWidget);

    // All menu items have a minimum height of 48. The centers of the
    // dropdown icon and the selected menu item are vertically aligned
    // and horizontally adjacent.
    expect(tester.getSize(item30), const Size(100, 48));
    expect(tester.getCenter(item30).dy, tester.getCenter(dropdownIcon).dy);
    expect(tester.getTopRight(item30).dx, tester.getTopLeft(dropdownIcon).dx);

    // Show the popup menu.
    await tester.tap(item30);
    await tester.pumpAndSettle();

    // Each item appears twice, once in the menu and once
    // in the dropdown button's IndexedStack.
    expect(item30.evaluate().length, 2);
    expect(item40.evaluate().length, 2);
    expect(item50.evaluate().length, 2);
    expect(item60.evaluate().length, 2);

    // Verify that the items have the expected sizes. The width of the items
    // that appear in the menu is padded by 16 on the left and right.
    expect(tester.getSize(item30.first), const Size(100, 48));
    expect(tester.getSize(item40.first), const Size(100, 48));
    expect(tester.getSize(item50.first), const Size(100, 50));
    expect(tester.getSize(item60.first), const Size(100, 60));
    expect(tester.getSize(item30.last), const Size(132, 48));
    expect(tester.getSize(item40.last), const Size(132, 48));
    expect(tester.getSize(item50.last), const Size(132, 50));
    expect(tester.getSize(item60.last), const Size(132, 60));

    // The vertical center of the selectedItem (item30) should
    // line up with its button counterpart.
    expect(tester.getCenter(item30.first).dy, tester.getCenter(item30.last).dy);

    // The menu items should be arranged in a column.
    expect(tester.getBottomLeft(item30.last), tester.getTopLeft(item40.last));
    expect(tester.getBottomLeft(item40.last), tester.getTopLeft(item50.last));
    expect(tester.getBottomLeft(item50.last), tester.getTopLeft(item60.last));

    // Dismiss the menu by selecting item40 and then show the menu again.
    await tester.tap(item40.last);
    await tester.pumpAndSettle();
    expect(dropdownValue, 40);
    await tester.tap(item40.first);
    await tester.pumpAndSettle();

    // The vertical center of the selectedItem (item40) should
    // line up with its button counterpart.
    expect(tester.getCenter(item40.first).dy, tester.getCenter(item40.last).dy);
  });

  testWidgets('DropdownButton menu items do not resize when its route is popped', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/44877.
    const List<String> items = <String>[
      'one',
      'two',
      'three',
    ];
    String item = items[0];
    MediaQueryData mediaQuery;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return MaterialApp(
            builder: (BuildContext context, Widget child) {
              mediaQuery ??= MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery,
                child: child,
              );
            },
            home: Scaffold(
              body: DropdownButton<String>(
                value: item,
                items: items.map((String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                )).toList(),
                onChanged: (String newItem) {
                  setState(() {
                    item = newItem;
                    mediaQuery = mediaQuery.copyWith(
                      textScaleFactor: mediaQuery.textScaleFactor + 0.1,
                    );
                  });
                },
              ),
            ),
          );
        },
      ),
    );

    // Verify that the first item is showing.
    expect(find.text('one'), findsOneWidget);

    // Select a different item to trigger setState, which updates mediaQuery
    // and forces a performLayout on the popped _DropdownRoute. This operation
    // should not cause an exception.
    await tester.tap(find.text('one'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('two').last);
    await tester.pumpAndSettle();
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('DropdownButton hint is selected item', (WidgetTester tester) async {
    const double hintPaddingOffset = 8;
    const List<String> itemValues = <String>['item0', 'item1', 'item2', 'item3'];
    String selectedItem = 'item0';

    Widget buildFrame() {
      return MaterialApp(
        home: Scaffold(
          body: ButtonTheme(
            alignedDropdown: true,
            child: DropdownButtonHideUnderline(
              child: Center(
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    // The pretzel below is from an actual app. The price
                    // of limited configurability is keeping this working.
                    return DropdownButton<String>(
                      isExpanded: true,
                      elevation: 2,
                      value: null,
                      hint: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          // Stack with a positioned widget is used to override the
                          // hard coded 16px margin in the dropdown code, so that
                          // this hint aligns "properly" with the menu.
                          return Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topCenter,
                            children: <Widget>[
                              PositionedDirectional(
                                width: constraints.maxWidth + hintPaddingOffset,
                                start: -hintPaddingOffset,
                                top: 4.0,
                                child: Text('-$selectedItem-'),
                              ),
                            ],
                          );
                        },
                      ),
                      onChanged: (String value) {
                        setState(() { selectedItem = value; });
                      },
                      icon: Container(),
                      items: itemValues.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame());
    expect(tester.getTopLeft(find.text('-item0-')).dx, 8);

    // Show the popup menu.
    await tester.tap(find.text('-item0-'));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('-item0-')).dx, 8);
  });

  testWidgets('DropdownButton can be focused, and has focusColor', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    final UniqueKey buttonKey = UniqueKey();
    final FocusNode focusNode = FocusNode(debugLabel: 'DropdownButton');
    await tester.pumpWidget(buildFrame(buttonKey: buttonKey, onChanged: onChanged, focusNode: focusNode, autofocus: true));
    await tester.pump(); // Pump a frame for autofocus to take effect.
    expect(focusNode.hasPrimaryFocus, isTrue);
    final Finder buttonFinder = find.byKey(buttonKey);
    expect(buttonFinder, paints ..rrect(rrect: const RRect.fromLTRBXY(0.0, 0.0, 104.0, 48.0, 4.0, 4.0), color: const Color(0x1f000000)));

    await tester.pumpWidget(buildFrame(buttonKey: buttonKey, onChanged: onChanged, focusNode: focusNode, focusColor: const Color(0xff00ff00)));
    expect(buttonFinder, paints ..rrect(rrect: const RRect.fromLTRBXY(0.0, 0.0, 104.0, 48.0, 4.0, 4.0), color: const Color(0xff00ff00)));
  });

  testWidgets('DropdownButtonFormField can be focused, and has focusColor', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    final UniqueKey buttonKey = UniqueKey();
    final FocusNode focusNode = FocusNode(debugLabel: 'DropdownButtonFormField');
    await tester.pumpWidget(buildFrame(isFormField: true, buttonKey: buttonKey, onChanged: onChanged, focusNode: focusNode, autofocus: true));
    await tester.pump(); // Pump a frame for autofocus to take effect.
    expect(focusNode.hasPrimaryFocus, isTrue);
    final Finder buttonFinder = find.descendant(of: find.byKey(buttonKey), matching: find.byType(InputDecorator));
    expect(buttonFinder, paints ..rrect(rrect: const RRect.fromLTRBXY(0.0, 12.0, 800.0, 60.0, 4.0, 4.0), color: const Color(0x1f000000)));

    await tester.pumpWidget(buildFrame(isFormField: true, buttonKey: buttonKey, onChanged: onChanged, focusNode: focusNode, focusColor: const Color(0xff00ff00)));
    expect(buttonFinder, paints ..rrect(rrect: const RRect.fromLTRBXY(0.0, 12.0, 800.0, 60.0, 4.0, 4.0), color: const Color(0xff00ff00)));
  });

  testWidgets("DropdownButton won't be focused if not enabled", (WidgetTester tester) async {
    final UniqueKey buttonKey = UniqueKey();
    final FocusNode focusNode = FocusNode(debugLabel: 'DropdownButton');
    await tester.pumpWidget(buildFrame(buttonKey: buttonKey, focusNode: focusNode, autofocus: true, focusColor: const Color(0xff00ff00)));
    await tester.pump(); // Pump a frame for autofocus to take effect (although it shouldn't).
    expect(focusNode.hasPrimaryFocus, isFalse);
    expect(find.byKey(buttonKey), isNot(paints ..rrect(rrect: const RRect.fromLTRBXY(0.0, 0.0, 104.0, 48.0, 4.0, 4.0), color: const Color(0xff00ff00))));
  });

  testWidgets('DropdownButton is activated with the enter/space key', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'DropdownButton');
    String value = 'one';

    Widget buildFrame() {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return DropdownButton<String>(
                  focusNode: focusNode,
                  autofocus: true,
                  onChanged: (String newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                  value: value,
                  itemHeight: null,
                  items: menuItems.map<DropdownMenuItem<String>>((String item) {
                    return DropdownMenuItem<String>(
                      key: ValueKey<String>(item),
                      value: item,
                      child: Text(item, key: ValueKey<String>(item + 'Text')),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame());
    await tester.pump(); // Pump a frame for autofocus to take effect.
    expect(focusNode.hasPrimaryFocus, isTrue);

    // Web doesn't respond to enter, only space.
    await tester.sendKeyEvent(kIsWeb ? LogicalKeyboardKey.space : LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation
    expect(value, equals('one'));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab); // Focus 'two'
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter); // Select 'two', should work on web too.
    await tester.pump();

    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(value, equals('two'));
  });

  testWidgets('Selected element is focused when dropdown is opened', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'DropdownButton');
    String value = 'one';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButton<String>(
                focusNode: focusNode,
                autofocus: true,
                onChanged: (String newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
                value: value,
                itemHeight: null,
                items: menuItems.map<DropdownMenuItem<String>>((String item) {
                  return DropdownMenuItem<String>(
                    key: ValueKey<String>(item),
                    value: item,
                    child: Text(item, key: ValueKey<String>('Text $item')),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    ));

    await tester.pump(); // Pump a frame for autofocus to take effect.
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu open animation
    expect(value, equals('one'));
    expect(Focus.of(tester.element(find.byKey(const ValueKey<String>('one')).last)).hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab); // Focus 'two'
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter); // Select 'two' and close the dropdown.

    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu close animation

    expect(value, equals('two'));

    // Now make sure that "two" is focused when we re-open the dropdown.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu open animation
    expect(value, equals('two'));
    final Element element = tester.element(find.byKey(const ValueKey<String>('two')).last);
    final FocusNode node = Focus.of(element);
    expect(node.hasFocus, isTrue);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/55320

  testWidgets('Selected element is correctly focused with dropdown that more items than fit on the screen', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'DropdownButton');
    int value = 1;
    final List<int> hugeMenuItems = List<int>.generate(50, (int index) => index);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return DropdownButton<int>(
                  focusNode: focusNode,
                  autofocus: true,
                  onChanged: (int newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                  value: value,
                  itemHeight: null,
                  items: hugeMenuItems.map<DropdownMenuItem<int>>((int item) {
                    return DropdownMenuItem<int>(
                      key: ValueKey<int>(item),
                      value: item,
                      child: Text(item.toString(), key: ValueKey<String>('Text $item')),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump(); // Pump a frame for autofocus to take effect.
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu open animation
    expect(value, equals(1));
    expect(Focus.of(tester.element(find.byKey(const ValueKey<int>(1)).last)).hasPrimaryFocus, isTrue);

    for (int i = 0; i < 41; ++i) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // Move to the next one.
      await tester.pumpAndSettle(const Duration(milliseconds: 200)); // Wait for it to animate the menu.
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter); // Select '42' and close the dropdown.
    await tester.pumpAndSettle(const Duration(seconds: 1)); // Finish the menu close animation
    expect(value, equals(42));

    // Now make sure that "42" is focused when we re-open the dropdown.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu open animation
    expect(value, equals(42));
    final Element element = tester.element(find.byKey(const ValueKey<int>(42)).last);
    final FocusNode node = Focus.of(element);
    expect(node.hasFocus, isTrue);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/55320

  testWidgets("Having a focused element doesn't interrupt scroll when flung by touch", (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode(debugLabel: 'DropdownButton');
    int value = 1;
    final List<int> hugeMenuItems = List<int>.generate(100, (int index) => index);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return DropdownButton<int>(
                  focusNode: focusNode,
                  autofocus: true,
                  onChanged: (int newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                  value: value,
                  itemHeight: null,
                  items: hugeMenuItems.map<DropdownMenuItem<int>>((int item) {
                    return DropdownMenuItem<int>(
                      key: ValueKey<int>(item),
                      value: item,
                      child: Text(item.toString(), key: ValueKey<String>('Text $item')),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump(); // Pump a frame for autofocus to take effect.
    expect(focusNode.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(value, equals(1));
    expect(Focus.of(tester.element(find.byKey(const ValueKey<int>(1)).last)).hasPrimaryFocus, isTrue);

    // Move to an item very far down the menu.
    for (int i = 0; i < 90; ++i) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // Move to the next one.
      await tester.pumpAndSettle(); // Wait for it to animate the menu.
    }
    expect(Focus.of(tester.element(find.byKey(const ValueKey<int>(91)).last)).hasPrimaryFocus, isTrue);

    // Scroll back to the top using touch, and make sure we end up there.
    final Finder menu = find.byWidgetPredicate((Widget widget) {
      return widget.runtimeType.toString().startsWith('_DropdownMenu<');
    });
    final Rect menuRect = tester.getRect(menu).shift(tester.getTopLeft(menu));
    for (int i = 0; i < 10; ++i) {
      await tester.fling(menu, Offset(0.0, menuRect.height), 10.0);
    }
    await tester.pumpAndSettle();

    // Make sure that we made it to the top and something didn't stop the
    // scroll.
    expect(find.byKey(const ValueKey<int>(1)), findsNWidgets(2));
    expect(
      tester.getRect(find.byKey(const ValueKey<int>(1)).last),
      equals(const Rect.fromLTRB(372.0, 104.0, 436.0, 152.0)),
    );

    // Scrolling to the top again has removed the one the focus was on from the
    // tree, causing it to lose focus.
    expect(Focus.of(tester.element(find.byKey(const ValueKey<int>(91)).last)).hasPrimaryFocus, isFalse);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/55320

  testWidgets('DropdownButton onTap callback is called when defined', (WidgetTester tester) async {
    int dropdownButtonTapCounter = 0;
    String value = 'one';

    void onChanged(String newValue) { value = newValue; }
    void onTap() { dropdownButtonTapCounter += 1; }

    Widget build() => buildFrame(
      value: value,
      onChanged: onChanged,
      onTap: onTap,
    );
    await tester.pumpWidget(build());

    expect(dropdownButtonTapCounter, 0);

    // Tap dropdown button.
    await tester.tap(find.text('one'));
    await tester.pumpAndSettle();

    expect(value, equals('one'));
    expect(dropdownButtonTapCounter, 1); // Should update counter.

    // Tap dropdown menu item.
    await tester.tap(find.text('three').last);
    await tester.pumpAndSettle();

    expect(value, equals('three'));
    expect(dropdownButtonTapCounter, 1); // Should not change.

    // Tap dropdown button again.
    await tester.tap(find.text('three'));
    await tester.pumpAndSettle();

    expect(value, equals('three'));
    expect(dropdownButtonTapCounter, 2); // Should update counter.

    // Tap dropdown menu item.
    await tester.tap(find.text('two').last);
    await tester.pumpAndSettle();

    expect(value, equals('two'));
    expect(dropdownButtonTapCounter, 2); // Should not change.
  });

  testWidgets('DropdownMenuItem onTap callback is called when defined', (WidgetTester tester) async {
    String value = 'one';
    final List<int> menuItemTapCounters = <int>[0, 0, 0, 0];
    void onChanged(String newValue) { value = newValue; }

    final List<VoidCallback> onTapCallbacks = <VoidCallback>[
      () { menuItemTapCounters[0] += 1; },
      () { menuItemTapCounters[1] += 1; },
      () { menuItemTapCounters[2] += 1; },
      () { menuItemTapCounters[3] += 1; },
    ];

    int currentIndex = -1;
    await tester.pumpWidget(
      TestApp(
        textDirection: TextDirection.ltr,
        child: Material(
          child: RepaintBoundary(
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              items: menuItems.map<DropdownMenuItem<String>>((String item) {
                currentIndex += 1;
                return DropdownMenuItem<String>(
                  value: item,
                  onTap: onTapCallbacks[currentIndex],
                  child: Text(item),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );

    // Tap dropdown button.
    await tester.tap(find.text('one'));
    await tester.pumpAndSettle();

    expect(value, equals('one'));
    // Counters should still be zero.
    expect(menuItemTapCounters, <int>[0, 0, 0, 0]);

    // Tap dropdown menu item.
    await tester.tap(find.text('three').last);
    await tester.pumpAndSettle();

    // Should update the counter for the third item (second index).
    expect(value, equals('three'));
    expect(menuItemTapCounters, <int>[0, 0, 1, 0]);

    // Tap dropdown button again.
    await tester.tap(find.text('three'));
    await tester.pumpAndSettle();

    // Should not change.
    expect(value, equals('three'));
    expect(menuItemTapCounters, <int>[0, 0, 1, 0]);

    // Tap dropdown menu item.
    await tester.tap(find.text('two').last);
    await tester.pumpAndSettle();

    // Should update the counter for the second item (first index).
    expect(value, equals('two'));
    expect(menuItemTapCounters, <int>[0, 1, 1, 0]);

    // Tap dropdown button again.
    await tester.tap(find.text('two'));
    await tester.pumpAndSettle();

    // Should not change.
    expect(value, equals('two'));
    expect(menuItemTapCounters, <int>[0, 1, 1, 0]);

    // Tap the already selected menu item
    await tester.tap(find.text('two').last);
    await tester.pumpAndSettle();

    // Should update the counter for the second item (first index), even
    // though it was already selected.
    expect(value, equals('two'));
    expect(menuItemTapCounters, <int>[0, 2, 1, 0]);
  });
}
