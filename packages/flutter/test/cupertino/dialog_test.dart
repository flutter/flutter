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

    // Find the actual dialog box. The first decorated box is the popup barrier.
    expect(tester.getSize(find.byType(DecoratedBox).at(1)), equals(const Size(270.0, 560.0)));

    // Check sizes/locations of the text.
    expect(tester.getSize(find.text('The Title')), equals(const Size(230.0, 198.0)));
    expect(tester.getSize(find.text('Cancel')), equals(const Size(75.0, 300.0)));
    expect(tester.getSize(find.text('OK')), equals(const Size(75.0, 100.0)));
    expect(tester.getTopLeft(find.text('The Title')), equals(const Offset(285.0, 40.0)));

    // The Cancel and OK buttons have different Y values because "Cancel" is
    // wrapping (as it should with large text sizes like this).
    expect(tester.getTopLeft(find.text('Cancel')), equals(const Offset(295.0, 250.0)));
    expect(tester.getTopLeft(find.text('OK')), equals(const Offset(430.0, 350.0)));
  });
}

Widget boilerplate(Widget child) {
  return new Directionality(
    textDirection: TextDirection.ltr,
    child: child,
  );
}
