// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget boilerplate({ Widget child }) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  );
}

void main() {
  testWidgets('Initial toggle state is reflected', (WidgetTester tester) async {
    ThemeData theme;
    await tester.pumpWidget(
      Material(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            theme = Theme.of(context);
            return boilerplate(
              child: ToggleButtons(
                children: const <Widget>[
                  Text('First child'),
                  Text('Second child'),
              ],
                onPressed: (int index) { },
                isSelected: const <bool>[false, true],
              ),
            );
          },
        ),
      ),
    );

    final DefaultTextStyle textStyleOne = tester.widget(find.widgetWithText(DefaultTextStyle, 'First child').first);
    expect(textStyleOne.style.color, theme.colorScheme.onSurface);
    final DefaultTextStyle textStyleTwo = tester.widget(find.widgetWithText(DefaultTextStyle, 'Second child').first);
    expect(textStyleTwo.style.color, theme.colorScheme.primary);
  });

  testWidgets('onPressed is triggered on button tap', (WidgetTester tester) async {
    final List<bool> _isSelected = <bool>[false, true];
    ThemeData theme;

    await tester.pumpWidget(
      Material(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            theme = Theme.of(context);
            return boilerplate(
              child: ToggleButtons(
                children: const <Widget>[
                  Text('First child'),
                  Text('Second child'),
                ],
                onPressed: (int index) {
                  setState(() {
                    _isSelected[index] = !_isSelected[index];
                  });
                },
                isSelected: _isSelected,
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
    textStyleOne = tester.widget(find.widgetWithText(DefaultTextStyle, 'First child').first);
    expect(textStyleOne.style.color, theme.colorScheme.onSurface);
    textStyleTwo = tester.widget(find.widgetWithText(DefaultTextStyle, 'Second child').first);
    expect(textStyleTwo.style.color, theme.colorScheme.primary);

    await tester.tap(find.text('Second child'));
    await tester.pumpAndSettle();

    expect(_isSelected[0], isFalse);
    expect(_isSelected[1], isFalse);
    textStyleOne = tester.widget(find.widgetWithText(DefaultTextStyle, 'First child').first);
    expect(textStyleOne.style.color, theme.colorScheme.onSurface);
    textStyleTwo = tester.widget(find.widgetWithText(DefaultTextStyle, 'Second child').first);
    expect(textStyleTwo.style.color, theme.colorScheme.onSurface);
  });

  testWidgets('onPressed that is null disables buttons', (WidgetTester tester) async {
    ThemeData theme;

    await tester.pumpWidget(
      Material(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            theme = Theme.of(context);
            return boilerplate(
              child: ToggleButtons(
                children: const <Widget>[
                  Text('First child'),
                  Text('Second child'),
                ],
                isSelected: const <bool>[false, true],
              ),
            );
          },
        ),
      ),
    );

    final DefaultTextStyle textStyleOne = tester.widget(find.widgetWithText(DefaultTextStyle, 'First child').first);
    expect(textStyleOne.style.color, theme.disabledColor);
    final DefaultTextStyle textStyleTwo = tester.widget(find.widgetWithText(DefaultTextStyle, 'Second child').first);
    expect(textStyleTwo.style.color, theme.disabledColor);
  });

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
      fail('Should not be possible to create a toggle button with no children.');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('children != null'));
    }
  });

  testWidgets('isSelected property cannot be null', (WidgetTester tester) async {
    try {
      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              children: const <Widget>[
                Text('First child'),
                Text('Second child'),
              ],
              onPressed: (int index) {},
            ),
          ),
        ),
      );
      fail('Should not be possible to create a toggle button with no isSelected.');
    } on AssertionError catch (e) {
      expect(e.toString(), contains('isSelected != null'));
    }
  });

  testWidgets('children and isSelected properties have to be the same length', (WidgetTester tester) async {
    try {
      await tester.pumpWidget(
        Material(
          child: boilerplate(
            child: ToggleButtons(
              children: const <Widget>[
                Text('First child'),
                Text('Second child'),
              ],
              isSelected: const <bool>[false],
            ),
          ),
        ),
      );
      fail(
        'Should not be possible to create a toggle button with mismatching'
        'children.length and isSelected.length.'
      );
    } on AssertionError catch (e) {
      expect(e.toString(), contains('children.length'));
      expect(e.toString(), contains('isSelected.length'));
    }
  });

  // all default colors
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