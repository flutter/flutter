// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
                  showDialog<Null>(
                    context: context,
                    child: new CupertinoAlertDialog(
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
                    ),
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
    final ScrollController scrollController = new ScrollController(keepScrollOffset: true);
    await tester.pumpWidget(
      new MaterialApp(home: new Material(
        child: new Center(
          child: new Builder(builder: (BuildContext context) {
            return new RaisedButton(
              onPressed: () {
                showDialog<Null>(
                  context: context,
                  child: new Builder(builder: (BuildContext context) {
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
                  }),
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
    expect(tester.getSize(find.byType(DecoratedBox).at(1)), equals(const Size(270.0, 560.0)));

    // Check sizes/locations of the text.
    expect(tester.getSize(find.text('The Title')), equals(const Size(230.0, 198.0)));
    expect(tester.getSize(find.text('Cancel')), equals(const Size(87.0, 300.0)));
    expect(tester.getSize(find.text('OK')), equals(const Size(87.0, 100.0)));
    expect(tester.getTopLeft(find.text('The Title')), equals(const Offset(285.0, 40.0)));

    // The Cancel and OK buttons have different Y values because "Cancel" is
    // wrapping (as it should with large text sizes like this).
    expect(tester.getTopLeft(find.text('Cancel')), equals(const Offset(289.0, 256.0)));
    expect(tester.getTopLeft(find.text('OK')), equals(const Offset(424.0, 356.0)));
  });

  testWidgets('Button list is scrollable, has correct position with large text sizes.',
      (WidgetTester tester) async {
    const double textScaleFactor = 3.0;
    final ScrollController scrollController = new ScrollController(keepScrollOffset: true);
    await tester.pumpWidget(
      new MaterialApp(home: new Material(
        child: new Center(
          child: new Builder(builder: (BuildContext context) {
            return new RaisedButton(
              onPressed: () {
                showDialog<Null>(
                  context: context,
                  child: new Builder(builder: (BuildContext context) {
                    return new MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
                      child: new CupertinoAlertDialog(
                        title: const Text('The title'),
                        content: const Text('The content.'),
                        actions: <Widget>[
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
                        actionScrollController: scrollController,
                      ),
                    );
                  }),
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
    expect(scrollController.offset, 0.0);
    scrollController.jumpTo(100.0);
    expect(scrollController.offset, 100.0);
    scrollController.jumpTo(0.0);

    // Check that the action buttons are aligned vertically.
    expect(tester.getCenter(find.widgetWithText(CupertinoDialogAction, 'One')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(CupertinoDialogAction, 'Two')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(CupertinoDialogAction, 'Three')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(CupertinoDialogAction, 'Chocolate Brownies')).dx, equals(400.0));
    expect(tester.getCenter(find.widgetWithText(CupertinoDialogAction, 'Cancel')).dx, equals(400.0));
  });

  testWidgets('Title Section is empty, Button section is not empty.',
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
                  child: new Builder(builder: (BuildContext context) {
                    return new MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
                      child: new CupertinoAlertDialog(
                        actions: <Widget>[
                          const CupertinoDialogAction(
                            child: const Text('One'),
                          ),
                          const CupertinoDialogAction(
                            child: const Text('Two'),
                          ),
                        ],
                        actionScrollController: scrollController,
                      ),
                    );
                  }),
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
    expect(scrollController.offset, 0.0);
    expect(tester.getTopLeft(find.widgetWithText(CupertinoDialogAction, 'One')).dy, equals(288.0));

    // Check that the button's vertical size is the same.
    expect(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'One')).height,
        equals(tester.getSize(find.widgetWithText(CupertinoDialogAction, 'Two')).height));
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
                  child: new Builder(builder: (BuildContext context) {
                    return new MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaleFactor: textScaleFactor),
                      child: new CupertinoAlertDialog(
                        title: const Text('The title'),
                        content: const Text('The content.'),
                        scrollController: scrollController,
                      ),
                    );
                  }),
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
    expect(find.widgetWithText(CupertinoDialogAction, 'One').evaluate().toList().length, equals(0));
  });
}

Widget boilerplate(Widget child) {
  return new Directionality(
    textDirection: TextDirection.ltr,
    child: child,
  );
}
