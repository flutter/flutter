// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/editable_text_utils.dart' show textOffsetToPosition;

// These constants are copied from cupertino/text_selection_toolbar.dart.
const double _kArrowScreenPadding = 26.0;
const double _kToolbarContentDistance = 8.0;
const double _kToolbarHeight = 43.0;

// A custom text selection menu that just displays a single custom button.
class _CustomCupertinoTextSelectionControls extends CupertinoTextSelectionControls {
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueNotifier<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double anchorX = (selectionMidpoint.dx + globalEditableRegion.left).clamp(
      _kArrowScreenPadding + mediaQuery.padding.left,
      mediaQuery.size.width - mediaQuery.padding.right - _kArrowScreenPadding,
    );
    final Offset anchorAbove = Offset(
      anchorX,
      endpoints.first.point.dy - textLineHeight + globalEditableRegion.top,
    );
    final Offset anchorBelow = Offset(
      anchorX,
      endpoints.last.point.dy + globalEditableRegion.top,
    );

    return CupertinoTextSelectionToolbar(
      anchorAbove: anchorAbove,
      anchorBelow: anchorBelow,
      children: <Widget>[
        CupertinoTextSelectionToolbarButton(
          onPressed: () {},
          child: const Text('Custom button'),
        ),
      ],
    );
  }
}

class TestBox extends SizedBox {
  const TestBox({super.key}) : super(width: itemWidth, height: itemHeight);

  static const double itemHeight = 44.0;
  static const double itemWidth = 100.0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Find by a runtimeType String, including private types.
  Finder findPrivate(String type) {
    return find.descendant(
      of: find.byType(CupertinoApp),
      matching: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == type),
    );
  }

  // Finding CupertinoTextSelectionToolbar won't give you the position as the user sees
  // it because it's a full-sized Stack at the top level. This method finds the
  // visible part of the toolbar for use in measurements.
  Finder findToolbar() => findPrivate('_CupertinoTextSelectionToolbarContent');

  Finder findOverflowNextButton() => find.text('▶');
  Finder findOverflowBackButton() => find.text('◀');

  testWidgets('paginates children if they overflow', (WidgetTester tester) async {
    late StateSetter setState;
    final List<Widget> children = List<Widget>.generate(7, (int i) => const TestBox());
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setter) {
              setState = setter;
              return CupertinoTextSelectionToolbar(
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
    expect(findOverflowNextButton(), findsNothing);
    expect(findOverflowBackButton(), findsNothing);

    // Adding one more child makes the children overflow.
    setState(() {
      children.add(
        const TestBox(),
      );
    });
    await tester.pumpAndSettle();
    expect(find.byType(TestBox), findsNWidgets(children.length - 1));
    expect(findOverflowNextButton(), findsOneWidget);
    expect(findOverflowBackButton(), findsNothing);

    // Tap the overflow next button to show the next page of children.
    await tester.tap(findOverflowNextButton());
    await tester.pumpAndSettle();
    expect(find.byType(TestBox), findsNWidgets(1));
    expect(findOverflowNextButton(), findsOneWidget);
    expect(findOverflowBackButton(), findsOneWidget);

    // Tapping the overflow next button again does nothing because it is
    // disabled and there are no more children to display.
    await tester.tap(findOverflowNextButton());
    await tester.pumpAndSettle();
    expect(find.byType(TestBox), findsNWidgets(1));
    expect(findOverflowNextButton(), findsOneWidget);
    expect(findOverflowBackButton(), findsOneWidget);

    // Tap the overflow back button to go back to the first page.
    await tester.tap(findOverflowBackButton());
    await tester.pumpAndSettle();
    expect(find.byType(TestBox), findsNWidgets(7));
    expect(findOverflowNextButton(), findsOneWidget);
    expect(findOverflowBackButton(), findsNothing);

    // Adding 7 more children overflows onto a third page.
    setState(() {
      children.add(const TestBox());
      children.add(const TestBox());
      children.add(const TestBox());
      children.add(const TestBox());
      children.add(const TestBox());
      children.add(const TestBox());
    });
    await tester.pumpAndSettle();
    expect(find.byType(TestBox), findsNWidgets(7));
    expect(findOverflowNextButton(), findsOneWidget);
    expect(findOverflowBackButton(), findsNothing);

    // Tap the overflow next button to show the second page of children.
    await tester.tap(findOverflowNextButton());
    await tester.pumpAndSettle();
    // With the back button, only six children fit on this page.
    expect(find.byType(TestBox), findsNWidgets(6));
    expect(findOverflowNextButton(), findsOneWidget);
    expect(findOverflowBackButton(), findsOneWidget);

    // Tap the overflow next button again to show the third page of children.
    await tester.tap(findOverflowNextButton());
    await tester.pumpAndSettle();
    expect(find.byType(TestBox), findsNWidgets(1));
    expect(findOverflowNextButton(), findsOneWidget);
    expect(findOverflowBackButton(), findsOneWidget);

    // Tap the overflow back button to go back to the second page.
    await tester.tap(findOverflowBackButton());
    await tester.pumpAndSettle();
    expect(find.byType(TestBox), findsNWidgets(6));
    expect(findOverflowNextButton(), findsOneWidget);
    expect(findOverflowBackButton(), findsOneWidget);

    // Tap the overflow back button to go back to the first page.
    await tester.tap(findOverflowBackButton());
    await tester.pumpAndSettle();
    expect(find.byType(TestBox), findsNWidgets(7));
    expect(findOverflowNextButton(), findsOneWidget);
    expect(findOverflowBackButton(), findsNothing);
  }, skip: kIsWeb); // [intended] We do not use Flutter-rendered context menu on the Web.

  testWidgets('positions itself at anchorAbove if it fits', (WidgetTester tester) async {
    late StateSetter setState;
    const double height = _kToolbarHeight;
    const double anchorBelowY = 500.0;
    double anchorAboveY = 0.0;

    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setter) {
              setState = setter;
              return CupertinoTextSelectionToolbar(
                anchorAbove: Offset(50.0, anchorAboveY),
                anchorBelow: const Offset(50.0, anchorBelowY),
                children: <Widget>[
                  Container(color: const Color(0xffff0000), width: 50.0, height: height),
                  Container(color: const Color(0xff00ff00), width: 50.0, height: height),
                  Container(color: const Color(0xff0000ff), width: 50.0, height: height),
                ],
              );
            },
          ),
        ),
      ),
    );

    // When the toolbar doesn't fit above aboveAnchor, it positions itself below
    // belowAnchor.
    double toolbarY = tester.getTopLeft(findToolbar()).dy;
    expect(toolbarY, equals(anchorBelowY + _kToolbarContentDistance));

    // Even when it barely doesn't fit.
    setState(() {
      anchorAboveY = 50.0;
    });
    await tester.pump();
    toolbarY = tester.getTopLeft(findToolbar()).dy;
    expect(toolbarY, equals(anchorBelowY + _kToolbarContentDistance));

    // When it does fit above aboveAnchor, it positions itself there.
    setState(() {
      anchorAboveY = 60.0;
    });
    await tester.pump();
    toolbarY = tester.getTopLeft(findToolbar()).dy;
    expect(toolbarY, equals(anchorAboveY - height - _kToolbarContentDistance));
  }, skip: kIsWeb); // [intended] We do not use Flutter-rendered context menu on the Web.

  testWidgets('can create and use a custom toolbar', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'Select me custom menu',
    );
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoTextField(
            controller: controller,
            selectionControls: _CustomCupertinoTextSelectionControls(),
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
  }, skip: kIsWeb); // [intended] We do not use Flutter-rendered context menu on the Web.
}
