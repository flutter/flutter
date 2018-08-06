// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Verify that a tap on modal barrier dismisses an action sheet', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        const CupertinoActionSheet(
          title: const Text('Action Sheet'),
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

  testWidgets('Verify that a tap on title section (not buttons) does not dismiss an action sheet', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        const CupertinoActionSheet(
          title: const Text('Action Sheet'),
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
        ActionSheetAction(
          isDestructiveAction: true,
          child: const Text('Ok'),
          onPressed: () {},
        ),
      ),
    );

    final DefaultTextStyle widget = tester.widget(find.byType(DefaultTextStyle));

    expect(widget.style.color, CupertinoColors.destructiveRed);
  });

  testWidgets('Action sheet default text style', (WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(
        ActionSheetAction(
          isDefaultAction: true,
          child: const Text('Ok'),
          onPressed: () {},
        ),
      ),
    );

    final DefaultTextStyle widget = tester.widget(find.byType(DefaultTextStyle));

    expect(widget.style.fontWeight, equals(FontWeight.w600));
  });

  testWidgets('Action sheet text styles are correct when both title and message are included', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        const CupertinoActionSheet(
          title: const Text('Action Sheet'),
          message: const Text('An action sheet')
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    final DefaultTextStyle titleStyle = tester.firstWidget(find.widgetWithText(DefaultTextStyle, 'Action Sheet'));
    final DefaultTextStyle messageStyle = tester.firstWidget(find.widgetWithText(DefaultTextStyle, 'An action sheet'));

    expect(titleStyle.style.fontWeight, FontWeight.w600);
    expect(messageStyle.style.fontWeight, FontWeight.w400);
  });

  testWidgets('Action sheet text styles are correct when title but no message is included', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        const CupertinoActionSheet(
          title: const Text('Action Sheet'),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    final DefaultTextStyle titleStyle = tester.firstWidget(find.widgetWithText(DefaultTextStyle, 'Action Sheet'));

    expect(titleStyle.style.fontWeight, FontWeight.w400);
  });

  testWidgets('Action sheet text styles are correct when message but no title is included', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        const CupertinoActionSheet(
          message: const Text('An action sheet'),
        ),
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    final DefaultTextStyle messageStyle = tester.firstWidget(find.widgetWithText(DefaultTextStyle, 'An action sheet'));

    expect(messageStyle.style.fontWeight, FontWeight.w600);
  });

  testWidgets('Content section but no actions', (WidgetTester tester) async {
    final ScrollController scrollController = new ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        new CupertinoActionSheet(
              title: const Text('The title'),
              message: const Text('The message.'),
              messageScrollController: scrollController,
            ),
          ),
    );

    await tester.tap(find.text('Go'));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Check that there's no button action section.
    expect(scrollController.offset, 0.0);
    expect(find.widgetWithText(ActionSheetAction, 'One'), findsNothing);

    // Check that the dialog size is the same as the content section size (minus padding).
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
    final ScrollController actionScrollController = new ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
          new CupertinoActionSheet(
                actions: <Widget>[
                  ActionSheetAction(
                    child: const Text('One'),
                    onPressed: () {},
                  ),
                  ActionSheetAction(
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

    // Check that the title/message section is not displayed
    expect(actionScrollController.offset, 0.0);

    // Check that the button's vertical size is the same.
    expect(tester.getSize(find.widgetWithText(ActionSheetAction, 'One')).height,
        equals(tester.getSize(find.widgetWithText(ActionSheetAction, 'Two')).height));
  });

  testWidgets('Action section is scrollable', (WidgetTester tester) async {
    final ScrollController actionScrollController = new ScrollController();
    await tester.pumpWidget(
        createAppWithButtonThatLaunchesActionSheet(
            new Builder(builder: (BuildContext context) {
              return new MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: 3.0),
                child: new CupertinoActionSheet(
                  title: const Text('The title'),
                  message: const Text('The message.'),
                  actions: <Widget>[
                    ActionSheetAction(
                      child: const Text('One'),
                      onPressed: () {},
                    ),
                    ActionSheetAction(
                      child: const Text('Two'),
                      onPressed: () {},
                    ),
                    ActionSheetAction(
                      child: const Text('Three'),
                      onPressed: () {},
                    ),
                    ActionSheetAction(
                      child: const Text('Four'),
                      onPressed: () {},
                    ),
                    ActionSheetAction(
                      child: const Text('Five'),
                      onPressed: () {},
                    ),
                  ],
                  actionScrollController: actionScrollController,
                ),
              );
            }
          ),
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
    expect(tester.getCenter(find.widgetWithText(ActionSheetAction, 'One')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(ActionSheetAction, 'Two')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(ActionSheetAction, 'Three')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(ActionSheetAction, 'Four')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(ActionSheetAction, 'Five')).dx, equals(400.0));

    // Check that the action buttons are the correct heights.
    expect(tester.getSize(find.widgetWithText(ActionSheetAction, 'One')).height, equals(92.0));
    expect(tester.getSize(find.widgetWithText(ActionSheetAction, 'Two')).height, equals(92.0));
    expect(tester.getSize(find.widgetWithText(ActionSheetAction, 'Three')).height, equals(92.0));
    expect(tester.getSize(find.widgetWithText(ActionSheetAction, 'Four')).height, equals(92.0));
    expect(tester.getSize(find.widgetWithText(ActionSheetAction, 'Five')).height, equals(92.0));
  });

  testWidgets('Content section is scrollable', (WidgetTester tester) async {
    final ScrollController messageScrollController = new ScrollController();
    double screenHeight;
    await tester.pumpWidget(
            createAppWithButtonThatLaunchesActionSheet(
              new Builder(builder: (BuildContext context) {
                screenHeight = MediaQuery.of(context).size.height;
                return new MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaleFactor: 3.0),
                  child: new CupertinoActionSheet(
                    title: const Text('The title'),
                    message: new Text('Very long content' * 200),
                    actions: <Widget>[
                      ActionSheetAction(
                        child: const Text('One'),
                        onPressed: () {},
                      ),
                      ActionSheetAction(
                        child: const Text('Two'),
                        onPressed: () {},
                      ),
                    ],
                    messageScrollController: messageScrollController,
                  ),
                );
              }
            ),
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
          new Builder(builder: (BuildContext context) {
            return new CupertinoActionSheet(
              actions: <Widget>[
                ActionSheetAction(
                  child: const Text('One'),
                  onPressed: () {
                    wasPressed = true;
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        ),
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

  testWidgets('Action sheet width is correct when given infinite horizontal space', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        new Row(
          children: <Widget>[
            new CupertinoActionSheet(
              actions: <Widget>[
                ActionSheetAction(
                  child: const Text('One'),
                  onPressed: () {},
                ),
                ActionSheetAction(
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

  testWidgets('Action sheet height is correct when given infinite vertical space', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        new Column(
          children: <Widget>[
            new CupertinoActionSheet(
              actions: <Widget>[
                ActionSheetAction(
                  child: const Text('One'),
                  onPressed: () {},
                ),
                ActionSheetAction(
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

    expect(tester.getSize(find.byType(CupertinoActionSheet)).height, 132.66666666666669);
  });

  testWidgets('Button section height is correct when content and actions together are too big', (WidgetTester tester) async {
    await tester.pumpWidget(
        createAppWithButtonThatLaunchesActionSheet(
            new CupertinoActionSheet(
                title: const Text('The title'),
                message: new Text('Very long content' * 200),
                actions: <Widget>[
                  ActionSheetAction(
                    child: const Text('One'),
                    onPressed: () {},
                  ),
                  ActionSheetAction(
                    child: const Text('Two'),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(getRenderActionSection(tester).size.height, 112.66666666666667);
  });

  testWidgets('Action sheet with just cancel button is correct', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        new CupertinoActionSheet(
          cancelButton: new ActionSheetAction(
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
        new Builder(builder: (BuildContext context) {
          return new CupertinoActionSheet(
            cancelButton: new ActionSheetAction(
                child: const Text('Cancel'),
                onPressed: () {
                  wasPressed = true;
                  Navigator.pop(context);
                },
              ),
          );
        },
        ),
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
        new CupertinoActionSheet(
            title: const Text('The title'),
            message: const Text('The message'),
            actions: <Widget>[
              ActionSheetAction(
                child: const Text('One'),
                onPressed: () {},
              ),
              ActionSheetAction(
                child: const Text('Two'),
                onPressed: () {},
              ),
            ],
            cancelButton: ActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () {},
            ),
          ),
        ),
      );

    await tester.tap(find.text('Go'));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.getBottomLeft(find.widgetWithText(ActionSheetAction, 'Cancel')).dy, 590.0);
    expect(tester.getBottomLeft(find.widgetWithText(ActionSheetAction, 'One')).dy, 469.66666666666663);
    expect(tester.getBottomLeft(find.widgetWithText(ActionSheetAction, 'Two')).dy, 526.0);
  });

  testWidgets('Enter/exit animation is correct', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesActionSheet(
        new CupertinoActionSheet(
          title: const Text('The title'),
          message: const Text('The message'),
          actions: <Widget>[
            ActionSheetAction(
              child: const Text('One'),
              onPressed: () {},
            ),
            ActionSheetAction(
              child: const Text('Two'),
              onPressed: () {},
            ),
          ],
          cancelButton: ActionSheetAction(
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
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(532.8, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(431.6, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(371.7, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(341.6, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(329.0, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(327.3, 0.1));

    // Action sheet has reached final height
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(327.3, 0.1));

    // Exit animation
    await tester.tapAt(const Offset(20.0, 20.0));
    await tester.pump();
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(327.3, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(394.4, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(495.6, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(555.5, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(585.6, 0.1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(598.2, 0.1));

    // Action sheet has disappeared
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(CupertinoActionSheet), findsNothing);
  });

  testWidgets('Modal barrier is pressed during transition', (WidgetTester tester) async {
      await tester.pumpWidget(
        createAppWithButtonThatLaunchesActionSheet(
          new CupertinoActionSheet(
            title: const Text('The title'),
            message: const Text('The message'),
            actions: <Widget>[
              ActionSheetAction(
                child: const Text('One'),
                onPressed: () {},
              ),
              ActionSheetAction(
                child: const Text('Two'),
                onPressed: () {},
              ),
            ],
            cancelButton: ActionSheetAction(
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
      expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(532.8, 0.1));

      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(431.6, 0.1));

      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(371.7, 0.1));

      // Exit animation
      await tester.tapAt(const Offset(20.0, 20.0));
      await tester.pump(const Duration(milliseconds: 60));

      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(431.6, 0.1));

      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, closeTo(532.8, 0.1));

      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.getTopLeft(find.byType(CupertinoActionSheet)).dy, 600.0);

      // Action sheet has disappeared
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(CupertinoActionSheet), findsNothing);
  });
}

dynamic getRenderActionSection(WidgetTester tester) {
  return tester.allRenderObjects.firstWhere(
        (RenderObject currentObject) {
      return currentObject.toStringShort().contains('_RenderCupertinoAlertActions');
    },
  );
}

Widget createAppWithButtonThatLaunchesActionSheet(Widget actionSheet) {
  return new MaterialApp(
    home: new Material(
      child: new Center(
        child: new Builder(builder: (BuildContext context) {
          return new RaisedButton(
            onPressed: () {
              showCupertinoModalPopup<void>(
                context: context,
                child: actionSheet,
              );
            },
            child: const Text('Go'),
          );
        }),
      ),
    ),
  );
}

Widget boilerplate(Widget child) {
  return new Directionality(
    textDirection: TextDirection.ltr,
    child: child,
  );
}