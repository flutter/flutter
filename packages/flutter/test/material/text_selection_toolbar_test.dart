// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../widgets/editable_text_utils.dart' show textOffsetToPosition;

// A custom text selection menu that just displays a single custom button.
class _CustomMaterialTextSelectionControls extends MaterialTextSelectionControls {
  static const double _kToolbarContentDistanceBelow = 20.0;
  static const double _kToolbarContentDistance = 8.0;

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ClipboardStatusNotifier clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    final TextSelectionPoint startTextSelectionPoint = endpoints[0];
    final TextSelectionPoint endTextSelectionPoint = endpoints.length > 1
      ? endpoints[1]
      : endpoints[0];
    final Offset anchorAbove = Offset(
      globalEditableRegion.left + selectionMidpoint.dx,
      globalEditableRegion.top + startTextSelectionPoint.point.dy - textLineHeight - _kToolbarContentDistance
    );
    final Offset anchorBelow = Offset(
      globalEditableRegion.left + selectionMidpoint.dx,
      globalEditableRegion.top + endTextSelectionPoint.point.dy + _kToolbarContentDistanceBelow,
    );

    return TextSelectionToolbar(
      anchorAbove: anchorAbove,
      anchorBelow: anchorBelow,
      children: <Widget>[
        TextSelectionToolbarTextButton(
          padding: TextSelectionToolbarTextButton.getPadding(0, 1),
          onPressed: () {},
          child: const Text('Custom button'),
        ),
      ],
    );
  }
}

class TestBox extends SizedBox {
  const TestBox({Key? key}) : super(key: key, width: itemWidth, height: itemHeight);

  static const double itemHeight = 44.0;
  static const double itemWidth = 100.0;
}

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
    final List<Widget> children = List<Widget>.generate(7, (int i) => const TestBox());

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
    expect(find.byType(TestBox), findsNWidgets(children.length));
    expect(_findOverflowButton(), findsNothing);

    // Adding one more child makes the children overflow.
    setState(() {
      children.add(
        const TestBox(),
      );
    });
    await tester.pumpAndSettle();
    expect(find.byType(TestBox), findsNWidgets(children.length - 1));
    expect(_findOverflowButton(), findsOneWidget);

    // Tap the overflow button to show the overflow menu.
    await tester.tap(_findOverflowButton());
    await tester.pumpAndSettle();
    expect(find.byType(TestBox), findsNWidgets(1));
    expect(_findOverflowButton(), findsOneWidget);

    // Tap the overflow button again to hide the overflow menu.
    await tester.tap(_findOverflowButton());
    await tester.pumpAndSettle();
    expect(find.byType(TestBox), findsNWidgets(children.length - 1));
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

  testWidgets('can create and use a custom toolbar', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SelectableText(
              'Select me custom menu',
              selectionControls: _CustomMaterialTextSelectionControls(),
            ),
          ),
        ),
      ),
    );

    // The selection menu is not initially shown.
    expect(find.text('Custom button'), findsNothing);

    // Long press on "custom" to select it.
    final Offset customPos = textOffsetToPosition(tester, 11);
    final TestGesture gesture = await tester.startGesture(customPos, pointer: 7);
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();

    // The custom selection menu is shown.
    expect(find.text('Custom button'), findsOneWidget);
    expect(find.text('Cut'), findsNothing);
    expect(find.text('Copy'), findsNothing);
    expect(find.text('Paste'), findsNothing);
    expect(find.text('Select all'), findsNothing);
  }, skip: kIsWeb);
}
