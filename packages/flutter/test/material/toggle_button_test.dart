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
    final List<bool> _isSelected = <bool>[false, true];

    await tester.pumpWidget(
      Material(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return boilerplate(
              child: ToggleButtons(
                children: <Widget>[
                  _isSelected[0] ? const Text('selected') : const Text('unselected'),
                  _isSelected[1] ? const Text('selected') : const Text('unselected'),
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

    expect(find.text('selected'), findsOneWidget);
    expect(find.text('unselected'), findsOneWidget);

    await tester.tap(find.text('unselected'));
    await tester.pumpAndSettle();

    expect(find.text('selected'), findsNWidgets(2));
    expect(find.text('unselected'), findsNothing);
  });

  testWidgets('onPressed is triggered on button tap', (WidgetTester tester) async {

  });

  // null onPressed disables the buttons
  testWidgets('onPressed that is null disables buttons', (WidgetTester tester) async {

  });

  // children cannot be null
  testWidgets('children property cannot be null', (WidgetTester tester) async {

  });

  // isSelected cannot be null
  testWidgets('isSelected property cannot be null', (WidgetTester tester) async {

  });

  // children and isSelected have to be same length
  testWidgets('children and isSelected properties have to be the same length', (WidgetTester tester) async {

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

  // height of all buttons must match the tallest button

  // RTL and LTR

  // proper paints based on state
}