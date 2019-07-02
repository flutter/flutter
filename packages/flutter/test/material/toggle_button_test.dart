// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

Widget boilerplate({Widget child}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  );
}

void main() {
  testWidgets('Initial toggle state is reflected', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            onPressed: (int index) {},
            isSelected: const <bool>[false, true],
            children: const <Widget>[
              Text('First child'),
              Text('Second child'),
            ],
          ),
        ),
      ),
    );

    final DefaultTextStyle textStyleOne = tester.firstWidget(
      find.widgetWithText(DefaultTextStyle, 'First child'),
    );
    expect(textStyleOne.style.color, theme.colorScheme.onSurface);
    final DefaultTextStyle textStyleTwo = tester.firstWidget(
      find.widgetWithText(DefaultTextStyle, 'Second child'),
    );
    expect(textStyleTwo.style.color, theme.colorScheme.primary);
  });

  testWidgets(
    'onPressed is triggered on button tap',
    (WidgetTester tester) async {
      final List<bool> _isSelected = <bool>[false, true];
      final ThemeData theme = ThemeData();
      await tester.pumpWidget(
        Material(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return boilerplate(
                child: ToggleButtons(
                  onPressed: (int index) {
                    setState(() {
                      _isSelected[index] = !_isSelected[index];
                    });
                  },
                  isSelected: _isSelected,
                  children: const <Widget>[
                    Text('First child'),
                    Text('Second child'),
                  ],
                ),
              );
            },
          ),
        ),
      );

      DefaultTextStyle textStyleOne;
      DefaultTextStyle textStyleTwo;

      expect(_isSelected[0], isFalse);
      expect(_isSelected[1], isTrue);
      textStyleOne = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyleOne.style.color, theme.colorScheme.onSurface);
      textStyleTwo = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'Second child'),
      );
      expect(textStyleTwo.style.color, theme.colorScheme.primary);

      await tester.tap(find.text('Second child'));
      await tester.pumpAndSettle();

      expect(_isSelected[0], isFalse);
      expect(_isSelected[1], isFalse);
      textStyleOne = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyleOne.style.color, theme.colorScheme.onSurface);
      textStyleTwo = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'Second child'),
      );
      expect(textStyleTwo.style.color, theme.colorScheme.onSurface);
    },
  );

  testWidgets(
    'onPressed that is null disables buttons',
    (WidgetTester tester) async {
      final List<bool> _isSelected = <bool>[false, true];
      final ThemeData theme = ThemeData();

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: _isSelected,
              children: const <Widget>[
                Text('First child'),
                Text('Second child'),
              ],
            ),
          ),
        ),
      );

      DefaultTextStyle textStyleOne;
      DefaultTextStyle textStyleTwo;

      expect(_isSelected[0], isFalse);
      expect(_isSelected[1], isTrue);
      textStyleOne = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyleOne.style.color, theme.disabledColor);
      textStyleTwo = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'Second child'),
      );
      expect(textStyleTwo.style.color, theme.disabledColor);

      await tester.tap(find.text('Second child'));
      await tester.pumpAndSettle();

      // nothing should change
      expect(_isSelected[0], isFalse);
      expect(_isSelected[1], isTrue);
      textStyleOne = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyleOne.style.color, theme.disabledColor);
      textStyleTwo = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'Second child'),
      );
      expect(textStyleTwo.style.color, theme.disabledColor);
    },
  );

  testWidgets('children property cannot be null', (WidgetTester tester) async {
    try {
      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[false, true],
              onPressed: (int index) {},
            ),
          ),
        ),
      );
      fail(
          'Should not be possible to create a toggle button with no children.');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('children != null'));
    }
  });

  testWidgets(
    'isSelected property cannot be null',
    (WidgetTester tester) async {
      try {
        await tester.pumpWidget(
          Material(
            child: boilerplate(
              child: ToggleButtons(
                onPressed: (int index) {},
                children: const <Widget>[
                  Text('First child'),
                  Text('Second child'),
                ],
              ),
            ),
          ),
        );
        fail(
            'Should not be possible to create a toggle button with no isSelected.');
      } on AssertionError catch (e) {
        expect(e.toString(), contains('isSelected != null'));
      }
    },
  );

  testWidgets(
    'children and isSelected properties have to be the same length',
    (WidgetTester tester) async {
      try {
        await tester.pumpWidget(
          Material(
            child: boilerplate(
              child: ToggleButtons(
                isSelected: const <bool>[false],
                children: const <Widget>[
                  Text('First child'),
                  Text('Second child'),
                ],
              ),
            ),
          ),
        );
        fail('Should not be possible to create a toggle button with mismatching'
            'children.length and isSelected.length.');
      } on AssertionError catch (e) {
        expect(e.toString(), contains('children.length'));
        expect(e.toString(), contains('isSelected.length'));
      }
    },
  );

  testWidgets(
    'Default text/icon colors for enabled, selected and disabled states',
    (WidgetTester tester) async {
      final ThemeData theme = ThemeData();
      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[false],
              onPressed: (int index) {},
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                  Icon(Icons.check),
                ]),
              ],
            ),
          ),
        ),
      );

      DefaultTextStyle textStyle;
      IconTheme iconTheme;

      textStyle = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyle.style.color, theme.colorScheme.onSurface);
      iconTheme = tester.firstWidget(
        find.widgetWithIcon(IconTheme, Icons.check),
      );
      expect(iconTheme.data.color, theme.colorScheme.onSurface);

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[true],
              onPressed: (int index) {},
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                  Icon(Icons.check),
                ]),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      textStyle = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyle.style.color, theme.colorScheme.primary);
      iconTheme = tester.firstWidget(
        find.widgetWithIcon(IconTheme, Icons.check),
      );
      expect(iconTheme.data.color, theme.colorScheme.primary);

      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              isSelected: const <bool>[true],
              children: <Widget>[
                Row(children: const <Widget>[
                  Text('First child'),
                  Icon(Icons.check),
                ]),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      textStyle = tester.firstWidget(
        find.widgetWithText(DefaultTextStyle, 'First child'),
      );
      expect(textStyle.style.color, theme.disabledColor);
      iconTheme = tester.firstWidget(
        find.widgetWithIcon(IconTheme, Icons.check),
      );
      expect(iconTheme.data.color, theme.disabledColor);
    },
  );

  testWidgets('Default button fillColor', (WidgetTester tester) async {
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            isSelected: const <bool>[true],
            onPressed: (int index) {},
            children: <Widget>[
              Row(children: const <Widget>[
                Text('First child'),
              ]),
            ],
          ),
        ),
      ),
    );

    final Material material = tester.firstWidget<Material>(
      find.descendant(
        of: find.byType(RawMaterialButton),
        matching: find.byType(Material),
      ),
    );

    expect(material.color, isNull);
    expect(material.type, MaterialType.transparency);
  });

  testWidgets('Default InkWell colors', (WidgetTester tester) async {
    final ThemeData theme = ThemeData();
    await tester.pumpWidget(
      Material(
        child: boilerplate(
          child: ToggleButtons(
            isSelected: const <bool>[true],
            onPressed: (int index) {},
            children: <Widget>[
              Row(children: const <Widget>[
                Text('First child'),
              ]),
            ],
          ),
        ),
      ),
    );

    final Offset center = tester.getCenter(find.text('First child'));
    // highlightColor
    // splashColor
    final TestGesture touchGesture = await tester.createGesture();
    await touchGesture.down(center);
    await tester.pumpAndSettle();

    RenderObject inkFeatures;
    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(inkFeatures, paints
      ..circle(color: theme.splashColor)
      ..rect(color: theme.highlightColor)
    );

    await touchGesture.up();
    await tester.pumpAndSettle();

    // hoverColor
    final TestGesture hoverGesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await hoverGesture.addPointer();
    await hoverGesture.moveTo(center);
    await tester.pumpAndSettle();

    inkFeatures = tester.allRenderObjects.firstWhere((RenderObject object) {
      return object.runtimeType.toString() == '_RenderInkFeatures';
    });
    expect(inkFeatures, paints
      ..rect(color: theme.hoverColor)
    );
    hoverGesture.removePointer();

    // focusColor
  });

  testWidgets(
    'Default border colors for enabled, selected and disabled states',
    (WidgetTester tester) async {
      // borderColor
      // selectedBorderColor
      // disabledBorderColor
    },
  );

  // custom colors
  // color
  // selectedcolor
  // disabledColor
  // fillColor
  // focusColor
  // highlightColor
  // hoverColor
  // splashColor
  // borderColor
  // selectedBorderColor
  // disabledBorderColor

  // default border radius
  // custom border radius
  // default border width
  // custom border width

  // themes are respected
  // color
  // selectedcolor
  // disabledColor
  // fillColor
  // focusColor
  // highlightColor
  // hoverColor
  // splashColor
  // borderColor
  // selectedBorderColor
  // disabledBorderColor
  // border radius
  // border width

  // height of all buttons must match the tallest button

  // RTL and LTR

  // proper paints based on state
}
