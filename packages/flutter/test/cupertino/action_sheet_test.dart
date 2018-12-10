// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Verify that a tap on modal barrier dismisses an action sheet',
          (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        const CupertinoActionSheet(
          title: Text('Action Sheet'),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(find.text('Action Sheet'), findsOneWidget);

    await tester.tapAt(const Offset(20.0, 20.0));
    await tester.pump();
    expect(find.text('Action Sheet'), findsNothing);
  });

  testWidgets('Verify that a tap on title section (not buttons) does not dismiss an action sheet',
          (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        const CupertinoActionSheet(
          title: Text('Action Sheet'),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(find.text('Action Sheet'), findsOneWidget);

    await tester.tap(find.text('Action Sheet'));
    await tester.pump();
    expect(find.text('Action Sheet'), findsOneWidget);
  });

  testWidgets('Action sheet destructive text style', (WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          child: const Text('Ok'),
          onPressed: () {},
        ),
      ),
    );

    final DefaultTextStyle widget = tester.widget(find.widgetWithText(DefaultTextStyle, 'Ok'));

    expect(widget.style.color, CupertinoColors.destructiveRed);
  });

  testWidgets('Action sheet default text style', (WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(
        CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text('Ok'),
          onPressed: () {},
        ),
      ),
    );

    final DefaultTextStyle widget = tester.widget(find.widgetWithText(DefaultTextStyle, 'Ok'));

    expect(widget.style.fontWeight, equals(FontWeight.w600));
  });

  testWidgets('Action sheet text styles are correct when both title and message are included',
          (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        const CupertinoActionSheet(
          title: Text('Action Sheet'),
          message: Text('An action sheet')
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    final DefaultTextStyle titleStyle = tester.firstWidget(find.widgetWithText(DefaultTextStyle,
        'Action Sheet'));
    final DefaultTextStyle messageStyle = tester.firstWidget(find.widgetWithText(DefaultTextStyle,
        'An action sheet'));

    expect(titleStyle.style.fontWeight, FontWeight.w600);
    expect(messageStyle.style.fontWeight, FontWeight.w400);
  });

  testWidgets('Action sheet text styles are correct when title but no message is included',
          (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        const CupertinoActionSheet(
          title: Text('Action Sheet'),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    final DefaultTextStyle titleStyle = tester.firstWidget(find.widgetWithText(DefaultTextStyle,
        'Action Sheet'));

    expect(titleStyle.style.fontWeight, FontWeight.w400);
  });

  testWidgets('Action sheet text styles are correct when message but no title is included',
          (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        const CupertinoActionSheet(
          message: Text('An action sheet'),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    final DefaultTextStyle messageStyle = tester.firstWidget(find.widgetWithText(DefaultTextStyle,
        'An action sheet'));

    expect(messageStyle.style.fontWeight, FontWeight.w600);
  });

  testWidgets('Content section but no actions', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        CupertinoActionSheet(
          title: const Text('The title'),
          message: const Text('The message.'),
          messageScrollController: scrollController,
        ),
      ),
    );

    await tester.tap(find.text('Go'));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Content section should be at the bottom left of action sheet
    // (minus padding).
    expect(tester.getBottomLeft(find.byType(ClipRRect)),
        tester.getBottomLeft(find.byType(CupertinoActionSheet)) - const Offset(-8.0, 10.0));

    // Check that the dialog size is the same as the content section size
    // (minus padding).
    expect(
      tester.getSize(find.byType(ClipRRect)).height,
      tester.getSize(find.byType(CupertinoActionSheet)).height  - 20.0,
    );

    expect(
      tester.getSize(find.byType(ClipRRect)).width,
      tester.getSize(find.byType(CupertinoActionSheet)).width - 16.0,
    );
  });

  testWidgets('Actions but no content section', (WidgetTester tester) async {
    final ScrollController actionScrollController = ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        CupertinoActionSheet(
          actions: <Widget>[
            CupertinoActionSheetAction(
              child: const Text('One'),
              onPressed: () {},
            ),
            CupertinoActionSheetAction(
              child: const Text('Two'),
              onPressed: () {},
            ),
          ],
          actionScrollController: actionScrollController,
        ),
      ),
    );

    await tester.tap(find.text('Go'));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final Finder finder = find.byElementPredicate(
      (Element element) {
        return element.widget.runtimeType.toString() == '_CupertinoAlertActionSection';
      },
    );

    // Check that the title/message section is not displayed (action section is
    // at the top of the action sheet + padding).
    expect(tester.getTopLeft(finder),
        tester.getTopLeft(find.byType(CupertinoActionSheet)) + const Offset(8.0, 10.0));

    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)) + const Offset(8.0, 10.0),
        tester.getTopLeft(find.widgetWithText(CupertinoActionSheetAction, 'One')));
    expect(tester.getBottomLeft(find.byType(CupertinoActionSheet)) + const Offset(8.0, -10.0),
        tester.getBottomLeft(find.widgetWithText(CupertinoActionSheetAction, 'Two')));
  });

  testWidgets('Action section is scrollable', (WidgetTester tester) async {
    final ScrollController actionScrollController = ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        Builder(builder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 3.0),
            child: CupertinoActionSheet(
              title: const Text('The title'),
              message: const Text('The message.'),
              actions: <Widget>[
                CupertinoActionSheetAction(
                  child: const Text('One'),
                  onPressed: () {},
                ),
                CupertinoActionSheetAction(
                  child: const Text('Two'),
                  onPressed: () {},
                ),
                CupertinoActionSheetAction(
                  child: const Text('Three'),
                  onPressed: () {},
                ),
                CupertinoActionSheetAction(
                  child: const Text('Four'),
                  onPressed: () {},
                ),
                CupertinoActionSheetAction(
                  child: const Text('Five'),
                  onPressed: () {},
                ),
              ],
              actionScrollController: actionScrollController,
            ),
          );
        }),
      )
    );

    await tester.tap(find.text('Go'));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Check that the action buttons list is scrollable.
    expect(actionScrollController.offset, 0.0);
    actionScrollController.jumpTo(100.0);
    expect(actionScrollController.offset, 100.0);
    actionScrollController.jumpTo(0.0);

    // Check that the action buttons are aligned vertically.
    expect(tester.getCenter(find.widgetWithText(CupertinoActionSheetAction, 'One')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(CupertinoActionSheetAction, 'Two')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(CupertinoActionSheetAction, 'Three')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(CupertinoActionSheetAction, 'Four')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(CupertinoActionSheetAction, 'Five')).dx, equals(400.0));

    // Check that the action buttons are the correct heights.
    expect(tester.getSize(find.widgetWithText(CupertinoActionSheetAction, 'One')).height, equals(92.0));
    expect(tester.getSize(find.widgetWithText(CupertinoActionSheetAction, 'Two')).height, equals(92.0));
    expect(tester.getSize(find.widgetWithText(CupertinoActionSheetAction, 'Three')).height, equals(92.0));
    expect(tester.getSize(find.widgetWithText(CupertinoActionSheetAction, 'Four')).height, equals(92.0));
    expect(tester.getSize(find.widgetWithText(CupertinoActionSheetAction, 'Five')).height, equals(92.0));
  });

  testWidgets('Content section is scrollable', (WidgetTester tester) async {
    final ScrollController messageScrollController = ScrollController();
    double screenHeight;
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        Builder(builder: (BuildContext context) {
          screenHeight = MediaQuery.of(context).size.height;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 3.0),
            child: CupertinoActionSheet(
              title: const Text('The title'),
              message: Text('Very long content' * 200),
              actions: <Widget>[
                CupertinoActionSheetAction(
                  child: const Text('One'),
                  onPressed: () {},
                ),
                CupertinoActionSheetAction(
                  child: const Text('Two'),
                  onPressed: () {},
                ),
              ],
              messageScrollController: messageScrollController,
            ),
          );
        }),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(messageScrollController.offset, 0.0);
    messageScrollController.jumpTo(100.0);
    expect(messageScrollController.offset, 100.0);
    // Set the scroll position back to zero.
    messageScrollController.jumpTo(0.0);

    // Expect the action sheet to take all available height.
    expect(tester.getSize(find.byType(CupertinoActionSheet)).height, screenHeight);
  });

  testWidgets('Tap on button calls onPressed', (WidgetTester tester) async {
    bool wasPressed = false;
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        Builder(builder: (BuildContext context) {
          return CupertinoActionSheet(
            actions: <Widget>[
              CupertinoActionSheetAction(
                child: const Text('One'),
                onPressed: () {
                  wasPressed = true;
                  Navigator.pop(context);
                },
              ),
            ],
          );
        }),
      ),
    );

    await tester.tap(find.text('Go'));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(wasPressed, isFalse);

    await tester.tap(find.text('One'));

    expect(wasPressed, isTrue);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('One'), findsNothing);
  });

  testWidgets('Action sheet width is correct when given infinite horizontal space',
          (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        Row(
          children: <Widget>[
            CupertinoActionSheet(
              actions: <Widget>[
                CupertinoActionSheetAction(
                  child: const Text('One'),
                  onPressed: () {},
                ),
                CupertinoActionSheetAction(
                  child: const Text('Two'),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(tester.getSize(find.byType(CupertinoActionSheet)).width, 600.0);
  });

  testWidgets('Action sheet height is correct when given infinite vertical space',
          (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        Column(
          children: <Widget>[
            CupertinoActionSheet(
              actions: <Widget>[
                CupertinoActionSheetAction(
                  child: const Text('One'),
                  onPressed: () {},
                ),
                CupertinoActionSheetAction(
                  child: const Text('Two'),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(tester.getSize(find.byType(CupertinoActionSheet)).height,
        moreOrLessEquals(132.33333333333334));
  });

  testWidgets('1 action button with cancel button', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        CupertinoActionSheet(
          title: const Text('The title'),
          message: Text('Very long content' * 200),
          actions: <Widget>[
            CupertinoActionSheetAction(
              child: const Text('One'),
              onPressed: () {},
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    // Action section is size of one action button.
    expect(findScrollableActionsSectionRenderBox(tester).size.height, 56.0);
  });

  testWidgets('2 action buttons with cancel button', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        CupertinoActionSheet(
          title: const Text('The title'),
          message: Text('Very long content' * 200),
          actions: <Widget>[
            CupertinoActionSheetAction(
              child: const Text('One'),
              onPressed: () {},
            ),
            CupertinoActionSheetAction(
              child: const Text('Two'),
              onPressed: () {},
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(findScrollableActionsSectionRenderBox(tester).size.height,
        moreOrLessEquals(112.33333333333331));
  });

  testWidgets('3 action buttons with cancel button', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        CupertinoActionSheet(
          title: const Text('The title'),
          message: Text('Very long content' * 200),
          actions: <Widget>[
            CupertinoActionSheetAction(
              child: const Text('One'),
              onPressed: () {},
            ),
            CupertinoActionSheetAction(
              child: const Text('Two'),
              onPressed: () {},
            ),
            CupertinoActionSheetAction(
              child: const Text('Three'),
              onPressed: () {},
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(findScrollableActionsSectionRenderBox(tester).size.height,
        moreOrLessEquals(168.66666666666669));
  });

  testWidgets('4+ action buttons with cancel button', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        CupertinoActionSheet(
          title: const Text('The title'),
          message: Text('Very long content' * 200),
          actions: <Widget>[
            CupertinoActionSheetAction(
              child: const Text('One'),
              onPressed: () {},
            ),
            CupertinoActionSheetAction(
              child: const Text('Two'),
              onPressed: () {},
            ),
            CupertinoActionSheetAction(
              child: const Text('Three'),
              onPressed: () {},
            ),
            CupertinoActionSheetAction(
              child: const Text('Four'),
              onPressed: () {},
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(findScrollableActionsSectionRenderBox(tester).size.height,
        moreOrLessEquals(84.33333333333337));
  });

  testWidgets('1 action button without cancel button', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        CupertinoActionSheet(
          title: const Text('The title'),
          message: Text('Very long content' * 200),
          actions: <Widget>[
            CupertinoActionSheetAction(
              child: const Text('One'),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(findScrollableActionsSectionRenderBox(tester).size.height, 56.0);
  });

  testWidgets('2+ action buttons without cancel button', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        CupertinoActionSheet(
          title: const Text('The title'),
          message: Text('Very long content' * 200),
          actions: <Widget>[
            CupertinoActionSheetAction(
              child: const Text('One'),
              onPressed: () {},
            ),
            CupertinoActionSheetAction(
              child: const Text('Two'),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(findScrollableActionsSectionRenderBox(tester).size.height,
        moreOrLessEquals(84.33333333333337));
  });

  testWidgets('Action sheet with just cancel button is correct', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        CupertinoActionSheet(
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: (){},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    // Height should be cancel button height + padding
    expect(tester.getSize(find.byType(CupertinoActionSheet)).height, 76.0);
    expect(tester.getSize(find.byType(CupertinoActionSheet)).width, 600.0);
  });

  testWidgets('Cancel button tap calls onPressed', (WidgetTester tester) async {
    bool wasPressed = false;
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        Builder(builder: (BuildContext context) {
          return CupertinoActionSheet(
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () {
                wasPressed = true;
                Navigator.pop(context);
              },
            ),
          );
        }),
      ),
    );

    await tester.tap(find.text('Go'));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(wasPressed, isFalse);

    await tester.tap(find.text('Cancel'));

    expect(wasPressed, isTrue);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('Layout is correct when cancel button is present', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        CupertinoActionSheet(
          title: const Text('The title'),
          message: const Text('The message'),
          actions: <Widget>[
            CupertinoActionSheetAction(
              child: const Text('One'),
              onPressed: () {},
            ),
            CupertinoActionSheetAction(
              child: const Text('Two'),
              onPressed: () {},
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go'));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.getBottomLeft(find.widgetWithText(CupertinoActionSheetAction, 'Cancel')).dy, 590.0);
    expect(tester.getBottomLeft(find.widgetWithText(CupertinoActionSheetAction, 'One')).dy,
        moreOrLessEquals(469.66666666666663));
    expect(tester.getBottomLeft(find.widgetWithText(CupertinoActionSheetAction, 'Two')).dy, 526.0);
  });

  testWidgets('Enter/exit animation is correct', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        CupertinoActionSheet(
          title: const Text('The title'),
          message: const Text('The message'),
          actions: <Widget>[
            CupertinoActionSheetAction(
              child: const Text('One'),
              onPressed: () {},
            ),
            CupertinoActionSheetAction(
              child: const Text('Two'),
              onPressed: () {},
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () {},
          ),
        ),
      ),
    );

    // Enter animation
    await tester.tap(find.text('Go'));

    await tester.pump();
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, 600.0);

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(530.9, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(426.7, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(365.0, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(334.0, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(321.0, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(319.3, 0.1));

    // Action sheet has reached final height
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(319.3, 0.1));

    // Exit animation
    await tester.tapAt(const Offset(20.0, 20.0));
    await tester.pump();
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(319.3, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(388.4, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(492.6, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(554.2, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(585.2, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(598.2, 0.1));

    // Action sheet has disappeared
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(CupertinoActionSheet), findsNothing);
  });

  testWidgets('Modal barrier is pressed during transition', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        CupertinoActionSheet(
          title: const Text('The title'),
          message: const Text('The message'),
          actions: <Widget>[
            CupertinoActionSheetAction(
              child: const Text('One'),
              onPressed: () {},
            ),
            CupertinoActionSheetAction(
              child: const Text('Two'),
              onPressed: () {},
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () {},
          ),
        ),
      ),
    );

    // Enter animation
    await tester.tap(find.text('Go'));

    await tester.pump();
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, 600.0);

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(530.9, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(426.7, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(365.0, 0.1));

    // Exit animation
    await tester.tapAt(const Offset(20.0, 20.0));
    await tester.pump(const Duration(milliseconds: 60));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(426.7, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(530.9, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, 600.0);

    // Action sheet has disappeared
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(CupertinoActionSheet), findsNothing);
  });


  testWidgets('Action sheet semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        CupertinoActionSheet(
          title: const Text('The title'),
          message: const Text('The message'),
          actions: <Widget>[
            CupertinoActionSheetAction(
              child: const Text('One'),
              onPressed: () {},
            ),
            CupertinoActionSheetAction(
              child: const Text('Two'),
              onPressed: () {},
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              children: <TestSemantics>[
                TestSemantics(
                  flags: <SemanticsFlag>[
                    SemanticsFlag.scopesRoute,
                    SemanticsFlag.namesRoute,
                  ],
                  label: 'Alert',
                  children: <TestSemantics>[
                    TestSemantics(
                      flags: <SemanticsFlag>[
                        SemanticsFlag.hasImplicitScrolling,
                      ],
                      children: <TestSemantics>[
                        TestSemantics(
                          label: 'The title',
                        ),
                        TestSemantics(
                          label: 'The message',
                        ),
                      ],
                    ),
                    TestSemantics(
                      flags: <SemanticsFlag>[
                        SemanticsFlag.hasImplicitScrolling,
                      ],
                      children: <TestSemantics>[
                        TestSemantics(
                          flags: <SemanticsFlag>[
                            SemanticsFlag.isButton,
                          ],
                          actions: <SemanticsAction>[
                            SemanticsAction.tap,
                          ],
                          label: 'One',
                        ),
                        TestSemantics(
                          flags: <SemanticsFlag>[
                            SemanticsFlag.isButton,
                          ],
                          actions: <SemanticsAction>[
                            SemanticsAction.tap,
                          ],
                          label: 'Two',
                        ),
                      ],
                    ),
                    TestSemantics(
                      flags: <SemanticsFlag>[
                        SemanticsFlag.isButton,
                      ],
                      actions: <SemanticsAction>[
                        SemanticsAction.tap,
                      ],
                      label: 'Cancel',
                    )
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreId: true,
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    semantics.dispose();
  });
}

RenderBox findScrollableActionsSectionRenderBox(WidgetTester tester) {
  final RenderObject actionsSection = tester.renderObject(find.byElementPredicate(
    (Element element) {
      return element.widget.runtimeType.toString() == '_CupertinoAlertActionSection';
    }),
  );
  assert(actionsSection is RenderBox);
  return actionsSection;
}

Widget createAppWithButtonThatLaunchesActionSheet(Widget actionSheet) {
  return CupertinoApp(
    home: Center(
      child: Builder(builder: (BuildContext context) {
        return CupertinoButton(
          onPressed: () {
            showCupertinoModalPopup<void>(
              context: context,
              builder: (BuildContext context) {
                return actionSheet;
              },
            );
          },
          child: const Text('Go'),
        );
      }),
    ),
  );
}

Widget boilerplate(Widget child) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: child,
  );
}