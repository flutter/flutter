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
    await tester.tap(find.text('Delete').first);

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
    expect(tester.getSize(find.byType(DecoratedBox).at(1)), equals(const Size(270.0, 560.0)));

    // Check sizes/locations of the text.
    expect(tester.getSize(find.text('The Title')), equals(const Size(230.0, 171.0)));
    expect(getFirstSizeOfMany(find.text('Cancel').first), equals(const Size(86.83333333333334, 300.0)));
    expect(getFirstSizeOfMany(find.text('OK').first), equals(const Size(86.83333333333334, 100.0)));
    expect(tester.getTopLeft(find.text('The Title')), equals(const Offset(285.0, 40.0)));

    // The Cancel and OK buttons have different Y values because "Cancel" is
    // wrapping (as it should with large text sizes like this).
    expect(getTopLeft(find.text('Cancel').first), equals(const Offset(289.0, 256.0)));
    expect(getTopLeft(find.text('OK').first), equals(const Offset(424.1666666666667, 356.0)));
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
    expect(getCenter(find.widgetWithText(CupertinoDialogAction, 'One').first).dx, equals(400.0));
    expect(getCenter(find.widgetWithText(CupertinoDialogAction, 'Two').first).dx, equals(400.0));
    expect(getCenter(find.widgetWithText(CupertinoDialogAction, 'Three').first).dx, equals(400.0));
    expect(getCenter(find.widgetWithText(CupertinoDialogAction, 'Chocolate Brownies').first).dx, equals(400.0));
    expect(getCenter(find.widgetWithText(CupertinoDialogAction, 'Cancel').first).dx, equals(400.0));

//    actionScrollController.jumpTo(49.0);
//    await tester.pumpAndSettle();
//
//    print('One');
//    Finder finder = find.widgetWithText(CupertinoDialogAction, 'One');
//    for (Element element in finder.evaluate()) {
//      print('Element: $element, ${element.hashCode}');
//      print('Size: ${(element.renderObject as RenderBox).size}');
//    }
//    print('');
//
//    print('Three');
//    finder = find.widgetWithText(CupertinoDialogAction, 'Three');
//    for (Element element in finder.evaluate()) {
//      print('Element: $element, ${element.hashCode}');
//      print('Size: ${(element.renderObject as RenderBox).size}');
//    }
//    print('');
//
//    print('Chocolate Brownies');
//    finder = find.widgetWithText(CupertinoDialogAction, 'Chocolate Brownies');
//    for (Element element in finder.evaluate()) {
//      print('Element: $element, ${element.hashCode}');
//      print('Size: ${(element.renderObject as RenderBox).size}');
//    }
//    print('');
//
//    print('First element: ${find.widgetWithText(CupertinoDialogAction, 'Chocolate Brownies').first.evaluate().first.hashCode}');

    // Check that the action buttons are the correct heights.
    expect(getFirstSizeOfMany(find.widgetWithText(CupertinoDialogAction, 'One')).height, equals(98.0));
    expect(getFirstSizeOfMany(find.widgetWithText(CupertinoDialogAction, 'Two')).height, equals(98.0));
    expect(getFirstSizeOfMany(find.widgetWithText(CupertinoDialogAction, 'Three')).height, equals(148.0));
    expect(getFirstSizeOfMany(find.widgetWithText(CupertinoDialogAction, 'Chocolate Brownies')).height, equals(298.0));
    expect(getFirstSizeOfMany(find.widgetWithText(CupertinoDialogAction, 'Cancel')).height, equals(148.0));
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
    final ScrollPosition actionsScrollPosition = actionScrollController.positions.where(
      (ScrollPosition position) {
        return position.viewportDimension > 0.0;
      },
    ).first;
//    expect(actionScrollController.offset, 0.0);
    expect(actionsScrollPosition.pixels, 0.0);
    expect(tester.getTopLeft(find.widgetWithText(CupertinoDialogAction, 'One').first).dy, equals(283.66666666666663));

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

Size getFirstSizeOfMany(Finder finder) {
  TestAsyncUtils.guardSync();
  final Element element = finder.evaluate().first;
  final RenderBox box = element.renderObject;
  assert(box != null);
  return box.size;
}

Offset getCenter(Finder finder) {
  return _getElementPoint(finder, (Size size) => size.center(Offset.zero));
}

Offset getTopLeft(Finder finder) {
  return _getElementPoint(finder, (Size size) => Offset.zero);
}

Offset _getElementPoint(Finder finder, Offset sizeToPoint(Size size)) {
  TestAsyncUtils.guardSync();
  final Element element = finder.evaluate().first;
  final RenderBox box = element.renderObject;
  assert(box != null);
  return box.localToGlobal(sizeToPoint(box.size));
}