// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Find by a runtimeType String, including private types.
  Finder _findPrivate(String type) {
    return find.descendant(
      of: find.byType(MaterialApp),
      matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == type),
    );
  }

  // Finding TextSelectionToolbar won't give you the position as the user sees
  // it because it's a full-sized Stack at the top level. This method finds the
  // visible part of the toolbar for use in measurements.
  Finder _findToolbar() => _findPrivate('_TextSelectionToolbarOverflowable');

  Finder _findOverflowButton() => _findPrivate('_TextSelectionToolbarOverflowButton');

  testWidgets('puts children in an overflow menu if they overflow', (WidgetTester tester) async {
    late StateSetter setState;
    const double height = 44.0;
    const double itemWidth = 100.0;
    final List<Widget> children = <Widget>[
      Container(width: itemWidth, height: height),
      Container(width: itemWidth, height: height),
      Container(width: itemWidth, height: height),
      Container(width: itemWidth, height: height),
      Container(width: itemWidth, height: height),
      Container(width: itemWidth, height: height),
      Container(width: itemWidth, height: height),
      Container(width: itemWidth, height: height),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setter) {
              setState = setter;
              return TextSelectionToolbar(
                anchorAbove: const Offset(50.0, 100.0),
                anchorBelow: const Offset(50.0, 200.0),
                children: children,
              );
            },
          ),
        ),
      ),
    );

    // All children fit on the screen, so they are all rendered.
    expect(find.byType(Container), findsNWidgets(children.length));
    expect(_findOverflowButton(), findsNothing);

    // Adding one more child makes the children overflow.
    setState(() {
      children.add(
        Container(width: itemWidth, height: height),
      );
    });
    await tester.pump();
    expect(find.byType(Container), findsNWidgets(children.length - 2));
    expect(_findOverflowButton(), findsOneWidget);

    // Tap the overflow button to show the overflow menu.
    await tester.tap(_findOverflowButton());
    await tester.pumpAndSettle();
    expect(find.byType(Container), findsNWidgets(2));
    expect(_findOverflowButton(), findsOneWidget);

    // Tap the overflow button again to hide the overflow menu.
    await tester.tap(_findOverflowButton());
    await tester.pumpAndSettle();
    expect(find.byType(Container), findsNWidgets(children.length - 2));
    expect(_findOverflowButton(), findsOneWidget);
  });

  testWidgets('positions itself at anchorAbove if it fits', (WidgetTester tester) async {
    late StateSetter setState;
    const double height = 44.0;
    const double anchorBelowY = 500.0;
    double anchorAboveY = 0.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setter) {
              setState = setter;
              return TextSelectionToolbar(
                anchorAbove: Offset(50.0, anchorAboveY),
                anchorBelow: const Offset(50.0, anchorBelowY),
                children: <Widget>[
                  Container(color: Colors.red, width: 50.0, height: height),
                  Container(color: Colors.green, width: 50.0, height: height),
                  Container(color: Colors.blue, width: 50.0, height: height),
                ],
              );
            },
          ),
        ),
      ),
    );

    // When the toolbar doesn't fit above aboveAnchor, it positions itself below
    // belowAnchor.
    double toolbarY = tester.getTopLeft(_findToolbar()).dy;
    expect(toolbarY, equals(anchorBelowY));

    // Even when it barely doesn't fit.
    setState(() {
      anchorAboveY = 50.0;
    });
    await tester.pump();
    toolbarY = tester.getTopLeft(_findToolbar()).dy;
    expect(toolbarY, equals(anchorBelowY));

    // When it does fit above aboveAnchor, it positions itself there.
    setState(() {
      anchorAboveY = 60.0;
    });
    await tester.pump();
    toolbarY = tester.getTopLeft(_findToolbar()).dy;
    expect(toolbarY, equals(anchorAboveY - height));
  });
}
