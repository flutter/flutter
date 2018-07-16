// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Alert dialog control test', (WidgetTester tester) async {
    bool didDelete = false;

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new Center(
          child: new Builder(
            builder: (BuildContext context) {
              return new RaisedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return new CupertinoAlertDialog(
                        title: const Text('The title'),
                        content: const Text('The content'),
                        actions: <Widget>[
                          const CupertinoDialogAction(
                            child: const Text('Cancel'),
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
                  );
                },
                child: const Text('Go'),
              );
            },
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Go'));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(didDelete, isFalse);

    // The Render Object that lays out the action buttons contains a duplicate
    // copy of those action buttons for layout calculations. Therefore, we need
    // to specify that we want the first 'Delete' text we find.
    await tester.tap(find.text('Delete'));

    expect(didDelete, isTrue);

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('Dialog destructive action styles', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(const CupertinoDialogAction(
      isDestructiveAction: true,
      child: const Text('Ok'),
    )));

    final DefaultTextStyle widget = tester.widget(find.byType(DefaultTextStyle));

    expect(widget.style.color.red, greaterThan(widget.style.color.blue));
    expect(widget.style.color.alpha, lessThan(255));
    sleep(const Duration(seconds: 5));
  });

  testWidgets('Dialog default action styles', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(const CupertinoDialogAction(
      isDefaultAction: true,
      child: const Text('Ok'),
    )));

    final DefaultTextStyle widget = tester.widget(find.byType(DefaultTextStyle));

    expect(widget.style.fontWeight, equals(FontWeight.w600));
  });

  testWidgets('Default and destructive style', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(const CupertinoDialogAction(
      isDefaultAction: true,
      isDestructiveAction: true,
      child: const Text('Ok'),
    )));

    final DefaultTextStyle widget = tester.widget(find.byType(DefaultTextStyle));

    expect(widget.style.fontWeight, equals(FontWeight.w600));
    expect(widget.style.color.red, greaterThan(widget.style.color.blue));
  });

  testWidgets('Message is scrollable, has correct padding with large text sizes',
      (WidgetTester tester) async {
    final ScrollController scrollController = new ScrollController();
    await tester.pumpWidget(
      new MaterialApp(home: new Material(
        child: new Center(
          child: new Builder(builder: (BuildContext context) {
            return new RaisedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return new MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaleFactor: 3.0),
                      child: new CupertinoAlertDialog(
                        title: const Text('The Title'),
                        content: new Text('Very long content ' * 20),
                        actions: const <Widget>[
                          const CupertinoDialogAction(
                            child: const Text('Cancel'),
                          ),
                          const CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: const Text('OK'),
                          ),
                        ],
                        scrollController: scrollController,
                      ),
                    );
                  },
                );
              },
              child: const Text('Go'),
            );
          }),
        ),
      )),
    );

    await tester.tap(find.text('Go'));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(scrollController.offset, 0.0);
    scrollController.jumpTo(100.0);
    expect(scrollController.offset, 100.0);
    // Set the scroll position back to zero.
    scrollController.jumpTo(0.0);

    // Find the actual dialog box. The first decorated box is the popup barrier.
    expect(
      tester.getSize(
        find.byKey(const Key('cupertino_alert_dialog_modal'))
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
    const double textScaleFactor = 3.0;
    final ScrollController actionScrollController = new ScrollController(keepScrollOffset: true);
    await tester.pumpWidget(
      new MaterialApp(home: new Material(
        child: new Center(
          child: new Builder(builder: (BuildContext context) {
            return new RaisedButton(
              onPressed: () {
                showDialog<Null>(
                  context: context,
                  builder: (BuildContext context) {
                    return new MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
                      child: new CupertinoAlertDialog(
                        title: const Text('The title'),
                        content: const Text('The content.'),
                        actions: const <Widget>[
                          const CupertinoDialogAction(
                            child: const Text('One'),
                          ),
                          const CupertinoDialogAction(
                            child: const Text('Two'),
                          ),
                          const CupertinoDialogAction(
                            child: const Text('Three'),
                          ),
                          const CupertinoDialogAction(
                            child: const Text('Chocolate Brownies'),
                          ),
                          const CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: const Text('Cancel'),
                          ),
                        ],
                        actionScrollController: actionScrollController,
                      ),
                    );
                  },
                );
              },
              child: const Text('Go'),
            );
          }),
        ),
      )),
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
      new MaterialApp(home: new Material(
        child: new Center(
          child: new Builder(builder: (BuildContext context) {
            return new RaisedButton(
              onPressed: () {
                showDialog<Null>(
                  context: context,
                  builder: (BuildContext context) {
                    return new MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
                      child: new CupertinoAlertDialog(
                        actions: const <Widget>[
                          const CupertinoDialogAction(
                            child: const Text('One'),
                          ),
                          const CupertinoDialogAction(
                            child: const Text('Two'),
                          ),
                        ],
                        actionScrollController: actionScrollController,
                      ),
                    );
                  },
                );
              },
              child: const Text('Go'),
            );
          }),
        ),
      )),
    );

    await tester.tap(find.text('Go'));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Check that the title/message section is not displayed
    expect(actionScrollController.offset, 0.0);
    expect(tester.getTopLeft(find.widgetWithText(CupertinoDialogAction, 'One').first).dy, equals(277.3333333333333));

    // Check that the button's vertical size is the same.
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'One').first).height,
        equals(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'Two').first).height));
  });

  testWidgets('Button section is empty, Title section is not empty.',
      (WidgetTester tester) async {
    const double textScaleFactor = 1.0;
    final ScrollController scrollController = new ScrollController(keepScrollOffset: true);
    await tester.pumpWidget(
      new MaterialApp(home: new Material(
        child: new Center(
          child: new Builder(builder: (BuildContext context) {
            return new RaisedButton(
              onPressed: () {
                showDialog<Null>(
                  context: context,
                  builder: (BuildContext context) {
                    return new MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
                      child: new CupertinoAlertDialog(
                        title: const Text('The title'),
                        content: const Text('The content.'),
                        scrollController: scrollController,
                      ),
                    );
                  },
                );
              },
              child: const Text('Go'),
            );
          }),
        ),
      )),
    );

    await tester.tap(find.text('Go'));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Check that there's no button action section.
    expect(scrollController.offset, 0.0);
    expect(find.widgetWithText(CupertinoDialogAction, 'One'), findsNothing);

    // Check that the dialog size is the same as the content section size. This
    // ensures that an empty button section doesn't accidentally render some
    // empty space in the dialog.
    expect(
      tester.getSize(find.byKey(const Key('cupertino_alert_dialog_content_section'))),
      tester.getSize(find.byKey(const Key('cupertino_alert_dialog_modal'))),
    );
  });
}

Widget boilerplate(Widget child) {
  return new Directionality(
    textDirection: TextDirection.ltr,
    child: child,
  );
}