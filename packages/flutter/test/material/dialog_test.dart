// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Dialog is scrollable', (WidgetTester tester) async {
    bool didPressOk = false;

    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Builder(
            builder: (BuildContext context) {
              return new Center(
                child: new RaisedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showDialog<Null>(
                      context: context,
                      builder: (BuildContext context) {
                        return new AlertDialog(
                          content: new Container(
                            height: 5000.0,
                            width: 300.0,
                            color: Colors.green[500],
                          ),
                          actions: <Widget>[
                            new FlatButton(
                              onPressed: () {
                                didPressOk = true;
                              },
                              child: const Text('OK')
                            )
                          ],
                        );
                      },
                    );
                  }
                )
              );
            }
          )
        )
      )
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1));

    expect(didPressOk, false);
    await tester.tap(find.text('OK'));
    expect(didPressOk, true);
  });

  testWidgets('Dialog background color', (WidgetTester tester) async {

    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(brightness: Brightness.dark),
        home: new Material(
          child: new Builder(
            builder: (BuildContext context) {
              return new Center(
                child: new RaisedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showDialog<Null>(
                      context: context,
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          title: const Text('Title'),
                          content: const Text('Y'),
                          actions: const <Widget>[ ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1));

    final StatefulElement widget = tester.element(find.byType(Material).last);
    final Material materialWidget = widget.state.widget;
    //first and second expect check that the material is the dialog's one
    expect(materialWidget.type, MaterialType.card);
    expect(materialWidget.elevation, 24);
    expect(materialWidget.color, Colors.grey[800]);
  });

  testWidgets('Simple dialog control test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: const Material(
          child: const Center(
            child: const RaisedButton(
              onPressed: null,
              child: const Text('Go'),
            ),
          ),
        ),
      ),
    );

    final BuildContext context = tester.element(find.text('Go'));

    final Future<int> result = showDialog(
      context: context,
      builder: (BuildContext context) {
        return new SimpleDialog(
          title: const Text('Title'),
          children: <Widget>[
            new SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 42);
              },
              child: const Text('First option'),
            ),
            const SimpleDialogOption(
              child: const Text('Second option'),
            ),
          ],
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Title'), findsOneWidget);
    await tester.tap(find.text('First option'));

    expect(await result, equals(42));
  });

  testWidgets('Barrier dismissible', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        home: const Material(
          child: const Center(
            child: const RaisedButton(
              onPressed: null,
              child: const Text('Go'),
            ),
          ),
        ),
      ),
    );

    final BuildContext context = tester.element(find.text('Go'));

    showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return new Container(
          width: 100.0,
          height: 100.0,
          alignment: Alignment.center,
          child: const Text('Dialog1'),
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog1'), findsOneWidget);

    // Tap on the barrier.
    await tester.tapAt(const Offset(10.0, 10.0));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog1'), findsNothing);

    showDialog<Null>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return new Container(
          width: 100.0,
          height: 100.0,
          alignment: Alignment.center,
          child: const Text('Dialog2'),
        );
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog2'), findsOneWidget);

    // Tap on the barrier, which shouldn't do anything this time.
    await tester.tapAt(const Offset(10.0, 10.0));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Dialog2'), findsOneWidget);

  });

  testWidgets('Dialog hides underlying semantics tree', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    const String buttonText = 'A button covered by dialog overlay';
    await tester.pumpWidget(
      new MaterialApp(
        home: const Material(
          child: const Center(
            child: const RaisedButton(
              onPressed: null,
              child: const Text(buttonText),
            ),
          ),
        ),
      ),
    );

    expect(semantics, includesNodeWith(label: buttonText));

    final BuildContext context = tester.element(find.text(buttonText));

    const String alertText = 'A button in an overlay alert';
    showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return const AlertDialog(title: const Text(alertText));
      },
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(semantics, includesNodeWith(label: alertText));
    expect(semantics, isNot(includesNodeWith(label: buttonText)));

    semantics.dispose();
  });

  testWidgets('Dialogs removes MediaQuery padding', (WidgetTester tester) async {
    BuildContext outerContext;
    BuildContext dialogContext;

    await tester.pumpWidget(new Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: new MediaQuery(
        data: const MediaQueryData(
          padding: const EdgeInsets.all(50.0),
        ),
        child: new Navigator(
          onGenerateRoute: (_) {
            return new PageRouteBuilder<Null>(
              pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
                outerContext = context;
                return new Container();
              },
            );
          },
        ),
      ),
    ));

    showDialog<Null>(
      context: outerContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        dialogContext = context;
        return new Container();
      },
    );

    await tester.pump();

    expect(MediaQuery.of(outerContext).padding, const EdgeInsets.all(50.0));
    expect(MediaQuery.of(dialogContext).padding, EdgeInsets.zero);
  });
}
