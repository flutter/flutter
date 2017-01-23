// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Verify that a BottomSheet can be rebuilt with ScaffoldFeatureController.setState()', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
    PersistentBottomSheetController<Null> bottomSheet;
    int buildCount = 0;

    await tester.pumpWidget(new MaterialApp(
      home: new Scaffold(
        key: scaffoldKey,
        body: new Center(child: new Text('body'))
      )
    ));

    bottomSheet = scaffoldKey.currentState.showBottomSheet<Null>((_) {
      return new Builder(
        builder: (BuildContext context) {
          buildCount += 1;
          return new Container(height: 200.0);
        }
      );
    });

    await tester.pump();
    expect(buildCount, equals(1));

    bottomSheet.setState((){ });
    await tester.pump();
    expect(buildCount, equals(2));
  });

}
