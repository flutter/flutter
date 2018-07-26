// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Alert dialog control test', (WidgetTester tester) async {
    bool didDelete = false;

    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return new CupertinoAlertDialog(
            title: const Text('The title'),
            content: const Text('The content'),
            actions: <Widget>[
              const CupertinoDialogAction(
                child: Text('Cancel'),
              ),
              new CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  didDelete = true;
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(didDelete, isFalse);

    await tester.tap(find.text('Delete'));
    await tester.pump();

    expect(didDelete, isTrue);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('Dialog destructive action styles', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(const CupertinoDialogAction(
      isDestructiveAction: true,
      child: Text('Ok'),
    )));

    final DefaultTextStyle widget = tester.widget(find.byType(DefaultTextStyle));

    expect(widget.style.color.red, greaterThan(widget.style.color.blue));
    expect(widget.style.color.alpha, lessThan(255));
  });

  testWidgets('Dialog default action styles', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(const CupertinoDialogAction(
      isDefaultAction: true,
      child: Text('Ok'),
    )));

    final DefaultTextStyle widget = tester.widget(find.byType(DefaultTextStyle));

    expect(widget.style.fontWeight, equals(FontWeight.w600));
  });

  testWidgets('Default and destructive style', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(const CupertinoDialogAction(
      isDefaultAction: true,
      isDestructiveAction: true,
      child: Text('Ok'),
    )));

    final DefaultTextStyle widget = tester.widget(find.byType(DefaultTextStyle));

    expect(widget.style.fontWeight, equals(FontWeight.w600));
    expect(widget.style.color.red, greaterThan(widget.style.color.blue));
  });

  testWidgets('Message is scrollable, has correct padding with large text sizes',
      (WidgetTester tester) async {
    final ScrollController scrollController = new ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return new MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 3.0),
            child: new CupertinoAlertDialog(
              title: const Text('The Title'),
              content: new Text('Very long content ' * 20),
              actions: const <Widget>[
                CupertinoDialogAction(
                  child: Text('Cancel'),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: Text('OK'),
                ),
              ],
              scrollController: scrollController,
            ),
          );
        }
      )
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(scrollController.offset, 0.0);
    scrollController.jumpTo(100.0);
    expect(scrollController.offset, 100.0);
    // Set the scroll position back to zero.
    scrollController.jumpTo(0.0);

    // Expect the modal dialog box to take all available height.
    expect(
      tester.getSize(
        find.byType(ClipRRect)
      ),
      equals(const Size(270.0, 560.0)),
    );

    // Check sizes/locations of the text. The text is large so these 2 buttons are stacked.
    // Visually the "Cancel" button and "OK" button are the same height. I don't know why
    // the test is reporting different height. I allowed it because the test looks correct
    // when run.
    expect(tester.getSize(find.text('The Title')), equals(const Size(230.0, 171.0)));
    expect(tester.getTopLeft(find.text('The Title')), equals(const Offset(285.0, 40.0)));
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'Cancel')), equals(const Size(270.0, 148.0)));
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'OK')), equals(const Size(270.0, 98.0)));
  });

  testWidgets('Button list is scrollable, has correct position with large text sizes.',
      (WidgetTester tester) async {
    final ScrollController actionScrollController = new ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return new MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 3.0),
            child: new CupertinoAlertDialog(
              title: const Text('The title'),
              content: const Text('The content.'),
              actions: const <Widget>[
                CupertinoDialogAction(
                  child: Text('One'),
                ),
                CupertinoDialogAction(
                  child: Text('Two'),
                ),
                CupertinoDialogAction(
                  child: Text('Three'),
                ),
                CupertinoDialogAction(
                  child: Text('Chocolate Brownies'),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: Text('Cancel'),
                ),
              ],
              actionScrollController: actionScrollController,
            ),
          );
        }
      )
    );

    await tester.tap(find.text('Go'));

    await tester.pump();

    // Check that the action buttons list is scrollable.
    expect(actionScrollController.offset, 0.0);
    actionScrollController.jumpTo(100.0);
    expect(actionScrollController.offset, 100.0);
    actionScrollController.jumpTo(0.0);

    // Check that the action buttons are aligned vertically.
    expect(tester.getCenter(find.widgetWithText(CupertinoDialogAction, 'One')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(CupertinoDialogAction, 'Two')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(CupertinoDialogAction, 'Three')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(CupertinoDialogAction, 'Chocolate Brownies')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(CupertinoDialogAction, 'Cancel')).dx, equals(400.0));

    // Check that the action buttons are the correct heights.
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'One')).height, equals(98.0));
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'Two')).height, equals(98.0));
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'Three')).height, equals(148.0));
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'Chocolate Brownies')).height, equals(298.0));
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'Cancel')).height, equals(148.0));
  });

  testWidgets('Title Section is empty, Button section is not empty.',
      (WidgetTester tester) async {
    const double textScaleFactor = 1.0;
    final ScrollController actionScrollController = new ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return new MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
            child: new CupertinoAlertDialog(
              actions: const <Widget>[
                CupertinoDialogAction(
                  child: Text('One'),
                ),
                CupertinoDialogAction(
                  child: Text('Two'),
                ),
              ],
              actionScrollController: actionScrollController,
            ),
          );
        }
      ),
    );

    await tester.tap(find.text('Go'));

    await tester.pump();

    // Check that the dialog size is the same as the actions section size. This
    // ensures that an empty content section doesn't accidentally render some
    // empty space in the dialog.
    final Finder contentSectionFinder = find.byElementPredicate((Element element) {
      return element.widget.runtimeType.toString() == '_CupertinoAlertActionSection';
    });

    final Finder modalBoundaryFinder = find.byType(ClipRRect);

    expect(
      tester.getSize(contentSectionFinder),
      tester.getSize(modalBoundaryFinder),
    );

    // Check that the title/message section is not displayed
    expect(actionScrollController.offset, 0.0);
    expect(tester.getTopLeft(find.widgetWithText(CupertinoDialogAction, 'One')).dy, equals(277.3333333333333));

    // Check that the button's vertical size is the same.
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'One')).height,
        equals(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'Two')).height));
  });

  testWidgets('Button section is empty, Title section is not empty.',
      (WidgetTester tester) async {
    const double textScaleFactor = 1.0;
    final ScrollController scrollController = new ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return new MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
            child: new CupertinoAlertDialog(
              title: const Text('The title'),
              content: const Text('The content.'),
              scrollController: scrollController,
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('Go'));

    await tester.pump();

    // Check that there's no button action section.
    expect(scrollController.offset, 0.0);
    expect(find.widgetWithText(CupertinoDialogAction, 'One'), findsNothing);

    // Check that the dialog size is the same as the content section size. This
    // ensures that an empty button section doesn't accidentally render some
    // empty space in the dialog.
    final Finder contentSectionFinder = find.byElementPredicate((Element element) {
      return element.widget.runtimeType.toString() == '_CupertinoAlertContentSection';
    });

    final Finder modalBoundaryFinder = find.byType(ClipRRect);

    expect(
      tester.getSize(contentSectionFinder),
      tester.getSize(modalBoundaryFinder),
    );
  });

  testWidgets('Actions section height for 1 button is height of button.',
          (WidgetTester tester) async {
    final ScrollController scrollController = new ScrollController();
    double dividerWidth; // Will be set when the dialog builder runs. Needs a BuildContext.
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          dividerWidth = 1.0 / MediaQuery.of(context).devicePixelRatio;
          return new CupertinoAlertDialog(
            title: const Text('The Title'),
            content: const Text('The message'),
            actions: const <Widget>[
              CupertinoDialogAction(
                child: Text('OK'),
              ),
            ],
            scrollController: scrollController,
          );
        },
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    final RenderBox okButtonBox = findActionButtonRenderBoxByTitle(tester, 'OK');
    final RenderBox actionsSectionBox = findActionsSectionRenderBox(tester);

    expect(okButtonBox.size.width, actionsSectionBox.size.width);
    expect(okButtonBox.size.height + dividerWidth, actionsSectionBox.size.height);
  });

  testWidgets('Actions section height for 2 side-by-side buttons is height of tallest button.',
          (WidgetTester tester) async {
    final ScrollController scrollController = new ScrollController();
    double dividerWidth; // Will be set when the dialog builder runs. Needs a BuildContext.
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          dividerWidth = 1.0 / MediaQuery.of(context).devicePixelRatio;
          return new CupertinoAlertDialog(
            title: const Text('The Title'),
            content: const Text('The message'),
            actions: const <Widget>[
              CupertinoDialogAction(
                child: Text('OK'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: Text('Cancel'),
              ),
            ],
            scrollController: scrollController,
          );
        },
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    final RenderBox okButtonBox = findActionButtonRenderBoxByTitle(tester, 'OK');
    final RenderBox cancelButtonBox = findActionButtonRenderBoxByTitle(tester, 'Cancel');
    final RenderBox actionsSectionBox = findActionsSectionRenderBox(tester);

    expect(okButtonBox.size.width, cancelButtonBox.size.width);

    expect(
      actionsSectionBox.size.width,
      okButtonBox.size.width + cancelButtonBox.size.width + dividerWidth,
    );

    expect(
      actionsSectionBox.size.height,
      max(okButtonBox.size.height, cancelButtonBox.size.height) + dividerWidth,
    );
  });

  testWidgets('Actions section height for 2 stacked buttons is height of both buttons.',
          (WidgetTester tester) async {
    final ScrollController scrollController = new ScrollController();
    double dividerWidth; // Will be set when the dialog builder runs. Needs a BuildContext.
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          dividerWidth = 1.0 / MediaQuery.of(context).devicePixelRatio;
          return new CupertinoAlertDialog(
            title: const Text('The Title'),
            content: const Text('The message'),
            actions: const <Widget>[
              CupertinoDialogAction(
                child: Text('OK'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: Text('This is too long to fit'),
              ),
            ],
            scrollController: scrollController,
          );
        },
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    final RenderBox okButtonBox = findActionButtonRenderBoxByTitle(tester, 'OK');
    final RenderBox longButtonBox = findActionButtonRenderBoxByTitle(tester, 'This is too long to fit');
    final RenderBox actionsSectionBox = findActionsSectionRenderBox(tester);

    expect(okButtonBox.size.width, longButtonBox.size.width);

    expect(okButtonBox.size.width, actionsSectionBox.size.width);

    expect(
      okButtonBox.size.height + longButtonBox.size.height + (2.0 * dividerWidth),
      actionsSectionBox.size.height,
    );
  });

  testWidgets('Actions section height for 3 buttons is 1.5 buttons tall.',
          (WidgetTester tester) async {
    final ScrollController scrollController = new ScrollController();
    double dividerWidth; // Will be set when the dialog builder runs. Needs a BuildContext.
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          dividerWidth = 1.0 / MediaQuery.of(context).devicePixelRatio;
          return new CupertinoAlertDialog(
            title: const Text('The Title'),
            content: const Text('The message'),
            actions: const <Widget>[
              CupertinoDialogAction(
                child: Text('Option 1'),
              ),
              CupertinoDialogAction(
                child: Text('Option 2'),
              ),
              CupertinoDialogAction(
                child: Text('Option 3'),
              ),
            ],
            scrollController: scrollController,
          );
        },
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    final RenderBox option1ButtonBox = findActionButtonRenderBoxByTitle(tester, 'Option 1');
    final RenderBox option2ButtonBox = findActionButtonRenderBoxByTitle(tester, 'Option 2');
    final RenderBox option3ButtonBox = findActionButtonRenderBoxByTitle(tester, 'Option 3');
    final RenderBox actionsSectionBox = findActionsSectionRenderBox(tester);

    expect(option1ButtonBox.size.width, option2ButtonBox.size.width);
    expect(option2ButtonBox.size.width, option3ButtonBox.size.width);
    expect(option1ButtonBox.size.width, actionsSectionBox.size.width);

    final double expectedHeight = option1ButtonBox.size.height
        + option2ButtonBox.size.height
        + option3ButtonBox.size.height
        + (3 * dividerWidth);
    expect(
      expectedHeight,
      actionsSectionBox.size.height,
    );
  });

  testWidgets('Actions section overscroll is painted white.', (WidgetTester tester) async {
    final ScrollController scrollController = new ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return new CupertinoAlertDialog(
            title: const Text('The Title'),
            content: const Text('The message'),
            actions: const <Widget>[
              CupertinoDialogAction(
                child: Text('Option 1'),
              ),
              CupertinoDialogAction(
                child: Text('Option 2'),
              ),
              CupertinoDialogAction(
                child: Text('Option 3'),
              ),
            ],
            scrollController: scrollController,
          );
        },
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    final RenderBox actionsSectionBox = findActionsSectionRenderBox(tester);

    // The way that overscroll white is accomplished in a scrollable action
    // section is that the custom RenderBox that lays out the buttons and draws
    // the dividers also paints a white background the size of Rect.largest.
    // That background ends up being clipped by the containing ScrollView.
    //
    // Here we test that the largest Rect is contained within the painted Path.
    // We don't test for exclusion because for some reason the Path is reporting
    // that even points beyond Rect.largest are within the Path. That's not an
    // issue for our use-case, so we don't worry about it.
    expect(actionsSectionBox, paints..path(
      includes: <Offset>[
        new Offset(Rect.largest.left, Rect.largest.top),
        new Offset(Rect.largest.right, Rect.largest.bottom),
      ],
    ));
  });

  testWidgets('Pressed button changes appearance and dividers disappear.', (WidgetTester tester) async {
    final ScrollController scrollController = new ScrollController();
    double dividerWidth; // Will be set when the dialog builder runs. Needs a BuildContext.
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          dividerWidth = 1.0 / MediaQuery.of(context).devicePixelRatio;
          return new CupertinoAlertDialog(
            title: const Text('The Title'),
            content: const Text('The message'),
            actions: const <Widget>[
              CupertinoDialogAction(
                child: Text('Option 1'),
              ),
              CupertinoDialogAction(
                child: Text('Option 2'),
              ),
              CupertinoDialogAction(
                child: Text('Option 3'),
              ),
            ],
            scrollController: scrollController,
          );
        },
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    const Color normalButtonBackgroundColor = Color(0xc0ffffff);
    const Color pressedButtonBackgroundColor = Color(0x90ffffff);
    final RenderBox firstButtonBox = findActionButtonRenderBoxByTitle(tester, 'Option 1');
    final RenderBox secondButtonBox = findActionButtonRenderBoxByTitle(tester, 'Option 2');
    final RenderBox actionsSectionBox = findActionsSectionRenderBox(tester);

    final Offset pressedButtonCenter = new Offset(
      secondButtonBox.size.width / 2.0,
      (2 * dividerWidth) + firstButtonBox.size.height + (secondButtonBox.size.height / 2.0),
    );
    final Offset topDividerCenter = new Offset(
      secondButtonBox.size.width / 2.0,
      dividerWidth + firstButtonBox.size.height + (0.5 * dividerWidth),
    );
    final Offset bottomDividerCenter = new Offset(
      secondButtonBox.size.width / 2.0,
      (2 * dividerWidth)
          + firstButtonBox.size.height
          + secondButtonBox.size.height
          + (0.5 * dividerWidth),
    );

    // Before pressing the button, verify following expectations:
    // - Background includes the button that will be pressed
    // - Background excludes the divider above and below the button that will be pressed
    // - Pressed button background does NOT include the button that will be pressed
    expect(actionsSectionBox, paints
      ..path(
        color: normalButtonBackgroundColor,
        includes: <Offset>[
          pressedButtonCenter,
        ],
        excludes: <Offset>[
          topDividerCenter,
          bottomDividerCenter,
        ],
      )
      ..path(
        color: pressedButtonBackgroundColor,
        excludes: <Offset>[
          pressedButtonCenter,
        ],
      ),
    );

    // Press down on the button.
    final TestGesture gesture = await tester.press(find.widgetWithText(CupertinoDialogAction, 'Option 2'));
    await tester.pump();

    // While pressing the button, verify following expectations:
    // - Background excludes the pressed button
    // - Background includes the divider above and below the pressed button
    // - Pressed button background includes the pressed
    expect(actionsSectionBox, paints
      ..path(
        color: normalButtonBackgroundColor,
        // The background should contain the divider above and below the pressed
        // button. While pressed, surrounding dividers disappear, which means
        // they become part of the background.
        includes: <Offset>[
          topDividerCenter,
          bottomDividerCenter,
        ],
        // The background path should not include the tapped button background...
        excludes: <Offset>[
          pressedButtonCenter,
        ],
      )
      // For a pressed button, a dedicated path is painted with a pressed button
      // background color...
      ..path(
        color: pressedButtonBackgroundColor,
        includes: <Offset>[
          pressedButtonCenter,
        ],
      ),
    );

    // We must explicitly cause an "up" gesture to avoid a crash.
    // todo(mattcarroll) remove this call when #19540 is fixed
    await gesture.up();
  });
}

RenderBox findActionButtonRenderBoxByTitle(WidgetTester tester, String title) {
  final RenderObject buttonBox = tester.renderObject(find.widgetWithText(CupertinoDialogAction, title));
  assert(buttonBox is RenderBox);
  return buttonBox;
}

RenderBox findActionsSectionRenderBox(WidgetTester tester) {
  final RenderObject actionsSection = tester.renderObject(find.byElementPredicate(
    (Element element) {
      return element.renderObject.runtimeType.toString() == '_RenderCupertinoDialogActions';
    }),
  );
  assert(actionsSection is RenderBox);
  return actionsSection;
}

Widget createAppWithButtonThatLaunchesDialog({WidgetBuilder dialogBuilder}) {
  return new MaterialApp(
    home: new Material(
      child: new Center(
        child: new Builder(builder: (BuildContext context) {
          return new RaisedButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: dialogBuilder,
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