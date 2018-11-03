// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Verify that a BottomSheet can be rebuilt with ScaffoldFeatureController.setState()', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    PersistentBottomSheetController<void> bottomSheet;
    int buildCount = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        body: const Center(child: Text('body'))
      )
    ));

    bottomSheet = scaffoldKey.currentState.showBottomSheet<void>((_) {
      return Builder(
        builder: (BuildContext context) {
          buildCount += 1;
          return Container(height: 200.0);
        }
      );
    });

    await tester.pump();
    expect(buildCount, equals(1));

    bottomSheet.setState(() { });
    await tester.pump();
    expect(buildCount, equals(2));
  });

  testWidgets('Verify that a scrollable BottomSheet can be dismissed', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        body: const Center(child: Text('body'))
      )
    ));

    scaffoldKey.currentState.showBottomSheet<void>((BuildContext context) {
      return ListView(
        shrinkWrap: true,
        primary: false,
        children: <Widget>[
          Container(height: 100.0, child: const Text('One')),
          Container(height: 100.0, child: const Text('Two')),
          Container(height: 100.0, child: const Text('Three')),
        ],
      );
    });

    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);

    await tester.drag(find.text('Two'), const Offset(0.0, 400.0));
    await tester.pumpAndSettle();

    expect(find.text('Two'), findsNothing);
  });

  testWidgets('showBottomSheet()', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Placeholder(key: key),
      )
    ));

    int buildCount = 0;
    showBottomSheet<void>(
      context: key.currentContext,
      builder: (BuildContext context) {
        return Builder(
          builder: (BuildContext context) {
            buildCount += 1;
            return Container(height: 200.0);
          }
        );
      },
    );
    await tester.pump();
    expect(buildCount, equals(1));
  });

  testWidgets('Scaffold removes top MediaQuery padding', (WidgetTester tester) async {
    BuildContext scaffoldContext;
    BuildContext bottomSheetContext;

    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.all(50.0),
        ),
        child: Scaffold(
          resizeToAvoidBottomPadding: false,
          body: Builder(
            builder: (BuildContext context) {
              scaffoldContext = context;
              return Container();
            }
          ),
        ),
      )
    ));

    await tester.pump();

    showBottomSheet<void>(
      context: scaffoldContext,
      builder: (BuildContext context) {
        bottomSheetContext = context;
        return Container();
      },
    );

    await tester.pump();

    expect(
      MediaQuery.of(bottomSheetContext).padding,
      const EdgeInsets.only(
        bottom: 50.0,
        left: 50.0,
        right: 50.0,
      ),
    );
  });

  testWidgets('Scaffold.bottomSheet', (WidgetTester tester) async {
    final Key bottomSheetKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const Placeholder(),
          bottomSheet: Container(
            key: bottomSheetKey,
            alignment: Alignment.center,
            height: 200.0,
            child: Builder(
              builder: (BuildContext context) {
                return RaisedButton(
                  child: const Text('showModalBottomSheet'),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (BuildContext context) => const Text('modal bottom sheet'),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('showModalBottomSheet'), findsOneWidget);
    expect(tester.getSize(find.byKey(bottomSheetKey)), const Size(800.0, 200.0));
    expect(tester.getTopLeft(find.byKey(bottomSheetKey)), const Offset(0.0, 400.0));

    // Show the modal bottomSheet
    await tester.tap(find.text('showModalBottomSheet'));
    await tester.pumpAndSettle();
    expect(find.text('modal bottom sheet'), findsOneWidget);

    // Dismiss the modal bottomSheet
    await tester.tap(find.text('modal bottom sheet'));
    await tester.pumpAndSettle();
    expect(find.text('modal bottom sheet'), findsNothing);
    expect(find.text('showModalBottomSheet'), findsOneWidget);

    // Remove the persistent bottomSheet
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomSheet: null,
          body: Placeholder(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('showModalBottomSheet'), findsNothing);
    expect(find.byKey(bottomSheetKey), findsNothing);
  });
}
