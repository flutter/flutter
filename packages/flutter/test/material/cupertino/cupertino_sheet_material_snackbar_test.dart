// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression test for https://github.com/flutter/flutter/issues/163572.
  testWidgets('showCupertinoSheet shows snackbar at bottom of screen', (WidgetTester tester) async {
    final scaffoldKey = GlobalKey<ScaffoldMessengerState>();

    void showSheet(BuildContext context) {
      showCupertinoSheet<void>(
        context: context,
        pageBuilder: (BuildContext context) {
          return Scaffold(
            body: Column(
              children: <Widget>[
                const Text('Cupertino Sheet'),
                CupertinoButton(
                  onPressed: () {
                    scaffoldKey.currentState?.showSnackBar(
                      const SnackBar(content: Text('SnackBar'), backgroundColor: Colors.red),
                    );
                  },
                  child: const Text('Show SnackBar'),
                ),
              ],
            ),
          );
        },
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: scaffoldKey,
        home: Scaffold(
          body: Center(
            child: Column(
              children: <Widget>[
                const Text('Page 1'),
                Builder(
                  builder: (BuildContext context) {
                    return CupertinoButton(
                      onPressed: () {
                        showSheet(context);
                      },
                      child: const Text('Show Cupertino Sheet'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);

    await tester.tap(find.text('Show Cupertino Sheet'));
    await tester.pumpAndSettle();

    expect(
      tester
          .getTopLeft(
            find.ancestor(of: find.text('Cupertino Sheet'), matching: find.byType(Scaffold)),
          )
          .dy,
      greaterThan(0.0),
    );

    await tester.tap(find.text('Show SnackBar'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsAtLeast(1));
    expect(
      tester.getBottomLeft(find.byType(Scaffold).first).dy,
      equals(tester.getBottomLeft(find.byType(SnackBar).first).dy),
    );

    final TestGesture gesture = await tester.startGesture(const Offset(200, 400));
    await tester.pump();
    expect(
      tester.getBottomLeft(find.byType(Scaffold).first).dy,
      equals(tester.getBottomLeft(find.byType(SnackBar).first).dy),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.byType(Scaffold).first).dy,
      equals(tester.getBottomLeft(find.byType(SnackBar).first).dy),
    );
  });
}
