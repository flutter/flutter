// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Alert dialog control test', (WidgetTester tester) async {
    bool didDelete = false;

    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text('The title'),
            content: const Text('The content'),
            actions: <Widget>[
              const CupertinoDialogAction(
                child: Text('Cancel'),
              ),
              CupertinoDialogAction(
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

  testWidgets('Dialog not barrier dismissible by default', (WidgetTester tester) async {
    await tester.pumpWidget(createAppWithCenteredButton(const Text('Go')));

    final BuildContext context = tester.element(find.text('Go'));

    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          width: 100.0,
          height: 100.0,
          alignment: Alignment.center,
          child: const Text('Dialog'),
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog'), findsOneWidget);

    // Tap on the barrier, which shouldn't do anything this time.
    await tester.tapAt(const Offset(10.0, 10.0));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog'), findsOneWidget);

  });

 testWidgets('Dialog configurable to be barrier dismissible', (WidgetTester tester) async {
    await tester.pumpWidget(createAppWithCenteredButton(const Text('Go')));

    final BuildContext context = tester.element(find.text('Go'));

    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Container(
          width: 100.0,
          height: 100.0,
          alignment: Alignment.center,
          child: const Text('Dialog'),
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog'), findsOneWidget);

    // Tap off the barrier.
    await tester.tapAt(const Offset(10.0, 10.0));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog'), findsNothing);
  });

  testWidgets('Dialog destructive action style', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(const CupertinoDialogAction(
      isDestructiveAction: true,
      child: Text('Ok'),
    )));

    final DefaultTextStyle widget = tester.widget(find.byType(DefaultTextStyle));

    expect(widget.style.color!.withAlpha(255), CupertinoColors.systemRed.color);
  });

  testWidgets('Dialog dark theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: CupertinoAlertDialog(
            title: const Text('The Title'),
            content: const Text('Content'),
            actions: <Widget>[
              CupertinoDialogAction(child: const Text('Cancel'), isDefaultAction: true, onPressed: () {}),
              const CupertinoDialogAction(child: Text('OK')),
            ],
          ),
        ),
      ),
    );

    final RichText cancelText =  tester.widget<RichText>(
      find.descendant(of: find.text('Cancel'), matching: find.byType(RichText)),
    );

    expect(
      cancelText.text.style!.color!.value,
      0xFF0A84FF, // dark elevated color of systemBlue.
    );

    expect(
      find.byType(CupertinoAlertDialog),
      paints..rect(color: const Color(0xBF1E1E1E)),
    );
  });

  testWidgets('Has semantic annotations', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(const MaterialApp(home: Material(
      child: CupertinoAlertDialog(
        title: Text('The Title'),
        content: Text('Content'),
        actions: <Widget>[
          CupertinoDialogAction(child: Text('Cancel')),
          CupertinoDialogAction(child: Text('OK')),
        ],
      ),
    )));

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              children: <TestSemantics>[
                TestSemantics(
                  children: <TestSemantics>[
                    TestSemantics(
                      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                      children: <TestSemantics>[
                        TestSemantics(
                          flags: <SemanticsFlag>[SemanticsFlag.scopesRoute, SemanticsFlag.namesRoute],
                          label: 'Alert',
                          children: <TestSemantics>[
                            TestSemantics(
                              flags: <SemanticsFlag>[
                                SemanticsFlag.hasImplicitScrolling,
                              ],
                              children: <TestSemantics>[
                                TestSemantics(label: 'The Title'),
                                TestSemantics(label: 'Content'),
                              ],
                            ),
                            TestSemantics(
                              flags: <SemanticsFlag>[
                                SemanticsFlag.hasImplicitScrolling,
                              ],
                              children: <TestSemantics>[
                                TestSemantics(
                                  flags: <SemanticsFlag>[SemanticsFlag.isButton],
                                  label: 'Cancel',
                                ),
                                TestSemantics(
                                  flags: <SemanticsFlag>[SemanticsFlag.isButton],
                                  label: 'OK',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ]
                )
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

  testWidgets('Dialog default action style', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(const CupertinoDialogAction(
      isDefaultAction: true,
      child: Text('Ok'),
    )));

    final DefaultTextStyle widget = tester.widget(find.byType(DefaultTextStyle));

    expect(widget.style.fontWeight, equals(FontWeight.w600));
  });

  testWidgets('Dialog default and destructive action styles', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(const CupertinoDialogAction(
      isDefaultAction: true,
      isDestructiveAction: true,
      child: Text('Ok'),
    )));

    final DefaultTextStyle widget = tester.widget(find.byType(DefaultTextStyle));

    expect(widget.style.color!.withAlpha(255), CupertinoColors.systemRed.color);
    expect(widget.style.fontWeight, equals(FontWeight.w600));
  });

  testWidgets('Dialog disabled action style', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(const CupertinoDialogAction(
      child: Text('Ok'),
    )));

    final DefaultTextStyle widget = tester.widget(find.byType(DefaultTextStyle));

    expect(widget.style.color!.opacity, greaterThanOrEqualTo(127 / 255));
    expect(widget.style.color!.opacity, lessThanOrEqualTo(128 / 255));
  });

  testWidgets('Dialog enabled action style', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(CupertinoDialogAction(
      child: const Text('Ok'),
      onPressed: () {},
    )));

    final DefaultTextStyle widget = tester.widget(find.byType(DefaultTextStyle));

    expect(widget.style.color!.opacity, equals(1.0));
  });

  testWidgets('Message is scrollable, has correct padding with large text sizes', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 3.0),
            child: CupertinoAlertDialog(
              title: const Text('The Title'),
              content: Text('Very long content ' * 20),
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
    await tester.pumpAndSettle();

    expect(scrollController.offset, 0.0);
    scrollController.jumpTo(100.0);
    expect(scrollController.offset, 100.0);
    // Set the scroll position back to zero.
    scrollController.jumpTo(0.0);

    await tester.pumpAndSettle();

    // Expect the modal dialog box to take all available height.
    expect(
      tester.getSize(
        find.byType(ClipRRect)
      ),
      equals(const Size(310.0, 560.0 - 24.0 * 2)),
    );

    // Check sizes/locations of the text. The text is large so these 2 buttons are stacked.
    // Visually the "Cancel" button and "OK" button are the same height when using the
    // regular font. However, when using the test font, "Cancel" becomes 2 lines which
    // is why the height we're verifying for "Cancel" is larger than "OK".
    expect(tester.getSize(find.text('The Title')), equals(const Size(270.0, 132.0)));
    expect(tester.getTopLeft(find.text('The Title')), equals(const Offset(265.0, 80.0 + 24.0)));
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'Cancel')), equals(const Size(310.0, 148.0)));
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'OK')), equals(const Size(310.0, 98.0)));
  });

  testWidgets('Dialog respects small constraints.', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return Center(
            child: ConstrainedBox(
              // Constrain the dialog to a tiny size and ensure it respects
              // these exact constraints.
              constraints: BoxConstraints.tight(const Size(200.0, 100.0)),
              child: CupertinoAlertDialog(
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
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    const double topAndBottomMargin = 40.0;
    const double topAndBottomPadding = 24.0 * 2;
    const double leftAndRightPadding = 40.0 * 2;
    final Finder modalFinder = find.byType(ClipRRect);
    expect(
      tester.getSize(modalFinder),
      equals(const Size(200.0 - leftAndRightPadding, 100.0 - topAndBottomMargin - topAndBottomPadding)),
    );
  });

  testWidgets('Button list is scrollable, has correct position with large text sizes.', (WidgetTester tester) async {
    final ScrollController actionScrollController = ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 3.0),
            child: CupertinoAlertDialog(
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
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'Three')).height, equals(98.0));
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'Chocolate Brownies')).height, equals(248.0));
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'Cancel')).height, equals(148.0));
  });

  testWidgets('Title Section is empty, Button section is not empty.', (WidgetTester tester) async {
    const double textScaleFactor = 1.0;
    final ScrollController actionScrollController = ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
            child: CupertinoAlertDialog(
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
    expect(tester.getTopLeft(find.widgetWithText(CupertinoDialogAction, 'One')).dy, equals(277.5));

    // Check that the button's vertical size is the same.
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'One')).height,
        equals(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'Two')).height));
  });

  testWidgets('Button section is empty, Title section is not empty.', (WidgetTester tester) async {
    const double textScaleFactor = 1.0;
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
            child: CupertinoAlertDialog(
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

  testWidgets('Actions section height for 1 button is height of button.', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return CupertinoAlertDialog(
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
    final RenderBox actionsSectionBox = findScrollableActionsSectionRenderBox(tester);

    expect(okButtonBox.size.width, actionsSectionBox.size.width);
    expect(okButtonBox.size.height, actionsSectionBox.size.height);
  });

  testWidgets('Actions section height for 2 side-by-side buttons is height of tallest button.', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    late double dividerWidth; // Will be set when the dialog builder runs. Needs a BuildContext.
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          dividerWidth = 1.0 / MediaQuery.of(context).devicePixelRatio;
          return CupertinoAlertDialog(
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
    final RenderBox actionsSectionBox = findScrollableActionsSectionRenderBox(tester);

    expect(okButtonBox.size.width, cancelButtonBox.size.width);

    expect(
      actionsSectionBox.size.width,
      okButtonBox.size.width + cancelButtonBox.size.width + dividerWidth,
    );

    expect(
      actionsSectionBox.size.height,
      max(okButtonBox.size.height, cancelButtonBox.size.height),
    );
  });

  testWidgets('Actions section height for 2 stacked buttons with enough room is height of both buttons.', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    late double dividerThickness; // Will be set when the dialog builder runs. Needs a BuildContext.
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          dividerThickness = 1.0 / MediaQuery.of(context).devicePixelRatio;
          return CupertinoAlertDialog(
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
    final RenderBox actionsSectionBox = findScrollableActionsSectionRenderBox(tester);

    expect(okButtonBox.size.width, longButtonBox.size.width);

    expect(okButtonBox.size.width, actionsSectionBox.size.width);

    expect(
      okButtonBox.size.height + dividerThickness + longButtonBox.size.height,
      actionsSectionBox.size.height,
    );
  });

  testWidgets('Actions section height for 2 stacked buttons without enough room and regular font is 1.5 buttons tall.', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text('The Title'),
            content: Text('The message\n' * 40),
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
    await tester.pumpAndSettle();

    final RenderBox actionsSectionBox = findScrollableActionsSectionRenderBox(tester);

    expect(
      actionsSectionBox.size.height,
      67.83333333333337,
    );
  });

  testWidgets('Actions section height for 2 stacked buttons without enough room and large accessibility font is 50% of dialog height.', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 3.0),
            child: CupertinoAlertDialog(
              title: const Text('The Title'),
              content: Text('The message\n' * 20),
              actions: const <Widget>[
                CupertinoDialogAction(
                  child: Text('This button is multi line'),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: Text('This button is multi line'),
                ),
              ],
              scrollController: scrollController,
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    final RenderBox actionsSectionBox = findScrollableActionsSectionRenderBox(tester);

    // The two multiline buttons with large text are taller than 50% of the
    // dialog height, but with the accessibility layout policy, the 2 buttons
    // should be in a scrollable area equal to half the dialog height.
    expect(
      actionsSectionBox.size.height,
      280.0 - 24.0,
    );
  });

  testWidgets('Actions section height for 3 buttons without enough room is 1.5 buttons tall.', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: const Text('The Title'),
            content: Text('The message\n' * 40),
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
    await tester.pumpAndSettle();

    final RenderBox option1ButtonBox = findActionButtonRenderBoxByTitle(tester, 'Option 1');
    final RenderBox option2ButtonBox = findActionButtonRenderBoxByTitle(tester, 'Option 2');
    final RenderBox actionsSectionBox = findScrollableActionsSectionRenderBox(tester);

    expect(option1ButtonBox.size.width, option2ButtonBox.size.width);
    expect(option1ButtonBox.size.width, actionsSectionBox.size.width);

    // Expected Height = button 1 + divider + 1/2 button 2 = 67.83333333333334
    const double expectedHeight = 67.83333333333334;
    expect(
      actionsSectionBox.size.height,
      moreOrLessEquals(expectedHeight),
    );
  });

  testWidgets('Actions section overscroll is painted white.', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return CupertinoAlertDialog(
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

    final RenderBox actionsSectionBox = findScrollableActionsSectionRenderBox(tester);

    // The way that overscroll white is accomplished in a scrollable action
    // section is that the custom RenderBox that lays out the buttons and draws
    // the dividers also paints a white background the size of Rect.largest.
    // That background ends up being clipped by the containing ScrollView.
    //
    // Here we test that the Rect(0.0, 0.0, renderBox.size.width, renderBox.size.height)
    // is contained within the painted Path.
    // We don't test for exclusion because for some reason the Path is reporting
    // that even points beyond Rect.largest are within the Path. That's not an
    // issue for our use-case, so we don't worry about it.
    expect(actionsSectionBox, paints..path(
      includes: <Offset>[
        Offset.zero,
        Offset(actionsSectionBox.size.width, actionsSectionBox.size.height),
      ],
    ));
  });

  testWidgets('Pressed button changes appearance and dividers disappear.', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    late double dividerThickness; // Will be set when the dialog builder runs. Needs a BuildContext.
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          dividerThickness = 1.0 / MediaQuery.of(context).devicePixelRatio;
          return CupertinoAlertDialog(
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

    const Color normalButtonBackgroundColor = Color(0xCCF2F2F2);
    const Color pressedButtonBackgroundColor = Color(0xFFE1E1E1);
    final RenderBox firstButtonBox = findActionButtonRenderBoxByTitle(tester, 'Option 1');
    final RenderBox secondButtonBox = findActionButtonRenderBoxByTitle(tester, 'Option 2');
    final RenderBox actionsSectionBox = findScrollableActionsSectionRenderBox(tester);

    final Offset pressedButtonCenter = Offset(
      secondButtonBox.size.width / 2.0,
      firstButtonBox.size.height + dividerThickness + (secondButtonBox.size.height / 2.0),
    );
    final Offset topDividerCenter = Offset(
      secondButtonBox.size.width / 2.0,
      firstButtonBox.size.height + (0.5 * dividerThickness),
    );
    final Offset bottomDividerCenter = Offset(
      secondButtonBox.size.width / 2.0,
      firstButtonBox.size.height
        + dividerThickness
        + secondButtonBox.size.height
        + (0.5 * dividerThickness),
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
    // todo(mattcarroll) remove this call, https://github.com/flutter/flutter/issues/19540
    await gesture.up();
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/52960

  testWidgets('ScaleTransition animation for showCupertinoDialog()', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: Builder(
            builder: (BuildContext context) {
              return CupertinoButton(
                onPressed: () {
                  showCupertinoDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return CupertinoAlertDialog(
                        title: const Text('The title'),
                        content: const Text('The content'),
                        actions: <Widget>[
                          const CupertinoDialogAction(
                            child: Text('Cancel'),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Go'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go'));

    // Enter animation.
    await tester.pump();
    Transform transform = tester.widget(find.byType(Transform));
    expect(transform.transform[0], moreOrLessEquals(1.3, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 50));
    transform = tester.widget(find.byType(Transform));
    expect(transform.transform[0], moreOrLessEquals(1.145, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 50));
    transform = tester.widget(find.byType(Transform));
    expect(transform.transform[0], moreOrLessEquals(1.044, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 50));
    transform = tester.widget(find.byType(Transform));
    expect(transform.transform[0], moreOrLessEquals(1.013, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 50));
    transform = tester.widget(find.byType(Transform));
    expect(transform.transform[0], moreOrLessEquals(1.003, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 50));
    transform = tester.widget(find.byType(Transform));
    expect(transform.transform[0], moreOrLessEquals(1.000, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 50));
    transform = tester.widget(find.byType(Transform));
    expect(transform.transform[0], moreOrLessEquals(1.000, epsilon: 0.001));

    await tester.tap(find.text('Delete'));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // No scaling on exit animation.
    expect(find.byType(Transform), findsNothing);
  });

  testWidgets('FadeTransition animation for showCupertinoDialog()', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: Builder(
            builder: (BuildContext context) {
              return CupertinoButton(
                onPressed: () {
                  showCupertinoDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return CupertinoAlertDialog(
                        title: const Text('The title'),
                        content: const Text('The content'),
                        actions: <Widget>[
                          const CupertinoDialogAction(
                            child: Text('Cancel'),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Go'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go'));

    // Enter animation.
    await tester.pump();
    FadeTransition transition = tester.firstWidget(find.byType(FadeTransition));

    await tester.pump(const Duration(milliseconds: 25));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, moreOrLessEquals(0.40, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 25));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, moreOrLessEquals(0.437, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 25));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, moreOrLessEquals(0.55, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 25));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, moreOrLessEquals(0.737, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 25));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, moreOrLessEquals(1.0, epsilon: 0.001));

    await tester.tap(find.text('Delete'));

    // Exit animation, look at reverse FadeTransition.
    await tester.pump(const Duration(milliseconds: 25));
    transition = tester.widgetList(find.byType(FadeTransition)).elementAt(1) as FadeTransition;
    expect(transition.opacity.value, moreOrLessEquals(0.500, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 25));
    transition = tester.widgetList(find.byType(FadeTransition)).elementAt(1) as FadeTransition;
    expect(transition.opacity.value, moreOrLessEquals(0.332, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 25));
    transition = tester.widgetList(find.byType(FadeTransition)).elementAt(1) as FadeTransition;
    expect(transition.opacity.value, moreOrLessEquals(0.188, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 25));
    transition = tester.widgetList(find.byType(FadeTransition)).elementAt(1) as FadeTransition;
    expect(transition.opacity.value, moreOrLessEquals(0.081, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 25));
    transition = tester.widgetList(find.byType(FadeTransition)).elementAt(1) as FadeTransition;
    expect(transition.opacity.value, moreOrLessEquals(0.019, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 25));
    transition = tester.widgetList(find.byType(FadeTransition)).elementAt(1) as FadeTransition;
    expect(transition.opacity.value, moreOrLessEquals(0.0, epsilon: 0.001));
  });

  testWidgets('Actions are accessible by key', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return const CupertinoAlertDialog(
            title: Text('The Title'),
            content: Text('The message'),
            actions: <Widget>[
              CupertinoDialogAction(
                key: Key('option_1'),
                child: Text('Option 1'),
              ),
              CupertinoDialogAction(
                key: Key('option_2'),
                child: Text('Option 2'),
              ),
            ],
          );
        },
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(find.byKey(const Key('option_1')), findsOneWidget);
    expect(find.byKey(const Key('option_2')), findsOneWidget);
    expect(find.byKey(const Key('option_3')), findsNothing);
  });

  testWidgets('Dialog widget insets by MediaQuery viewInsets', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(viewInsets: EdgeInsets.zero),
          child: CupertinoAlertDialog(content: Placeholder(fallbackHeight: 200.0)),
        ),
      ),
    );

    final Rect placeholderRectWithoutInsets = tester.getRect(find.byType(Placeholder));

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(viewInsets: EdgeInsets.fromLTRB(40.0, 30.0, 20.0, 10.0)),
          child: CupertinoAlertDialog(content: Placeholder(fallbackHeight: 200.0)),
        ),
      ),
    );

    // no change yet because padding is animated
    expect(tester.getRect(find.byType(Placeholder)), placeholderRectWithoutInsets);

    await tester.pump(const Duration(seconds: 1));

    // once animation settles the dialog is padded by the new viewInsets
    expect(tester.getRect(find.byType(Placeholder)), placeholderRectWithoutInsets.translate(10, 10));
  });

  testWidgets('Default cupertino dialog golden', (WidgetTester tester) async {
    await tester.pumpWidget(
      createAppWithButtonThatLaunchesDialog(
        dialogBuilder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 3.0),
            child: const RepaintBoundary(
              child: CupertinoAlertDialog(
                title: Text('Title'),
                content: Text('text'),
                actions: <Widget>[
                  CupertinoDialogAction(child: Text('No')),
                  CupertinoDialogAction(child: Text('OK')),
                ],
              ),
            ),
          );
        }
      ),
    );

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CupertinoAlertDialog),
      matchesGoldenFile('dialog_test.cupertino.default.png'),
    );
  });

  testWidgets('showCupertinoDialog - custom barrierLabel', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (BuildContext context) {
            return Center(
              child: CupertinoButton(
                child: const Text('X'),
                onPressed: () {
                  showCupertinoDialog<void>(
                    context: context,
                    barrierLabel: 'Custom label',
                    builder: (BuildContext context) {
                      return const CupertinoAlertDialog(
                        title: Text('Title'),
                        content: Text('Content'),
                        actions: <Widget>[
                          CupertinoDialogAction(child: Text('Yes')),
                          CupertinoDialogAction(child: Text('No')),
                        ],
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );

    expect(semantics, isNot(includesNodeWith(
      label: 'Custom label',
      flags: <SemanticsFlag>[SemanticsFlag.namesRoute],
    )));
  });

  testWidgets('CupertinoDialogRoute is state restorable', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        restorationScopeId: 'app',
        home: _RestorableDialogTestWidget(),
      ),
    );

    expect(find.byType(CupertinoAlertDialog), findsNothing);

    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    final TestRestorationData restorationData = await tester.getRestorationData();

    await tester.restartAndRestore();

    expect(find.byType(CupertinoAlertDialog), findsOneWidget);

    // Tap on the barrier.
    await tester.tapAt(const Offset(10.0, 10.0));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoAlertDialog), findsNothing);

    await tester.restoreFrom(restorationData);
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/33615
}

RenderBox findActionButtonRenderBoxByTitle(WidgetTester tester, String title) {
  final RenderObject buttonBox = tester.renderObject(find.widgetWithText(CupertinoDialogAction, title));
  assert(buttonBox is RenderBox);
  return buttonBox as RenderBox;
}

RenderBox findScrollableActionsSectionRenderBox(WidgetTester tester) {
  final RenderObject actionsSection = tester.renderObject(find.byElementPredicate(
    (Element element) {
      return element.widget.runtimeType.toString() == '_CupertinoAlertActionSection';
    }),
  );
  assert(actionsSection is RenderBox);
  return actionsSection as RenderBox;
}

Widget createAppWithButtonThatLaunchesDialog({
  required WidgetBuilder dialogBuilder
}) {
  return MaterialApp(
    home: Material(
      child: Center(
        child: Builder(builder: (BuildContext context) {
          return ElevatedButton(
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
  return Directionality(
    textDirection: TextDirection.ltr,
    child: child,
  );
}

Widget createAppWithCenteredButton(Widget child) {
  return MaterialApp(
    home: Material(
      child: Center(
        child: ElevatedButton(
          onPressed: null,
          child: child
        ),
      )
    )
  );
}


class _RestorableDialogTestWidget extends StatelessWidget{
  static Route<Object?> _dialogBuilder(BuildContext context, Object? arguments) {
    return CupertinoDialogRoute<void>(
      context: context,
      builder: (BuildContext context) {
        return const CupertinoAlertDialog(
          title: Text('Title'),
          content: Text('Content'),
          actions: <Widget>[
            CupertinoDialogAction(child: Text('Yes')),
            CupertinoDialogAction(child: Text('No')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Home'),
      ),
      child: Center(child: CupertinoButton(
        onPressed: () {
          Navigator.of(context).restorablePush(_dialogBuilder);
        },
        child: const Text('X'),
      )),
    );
  }
}
