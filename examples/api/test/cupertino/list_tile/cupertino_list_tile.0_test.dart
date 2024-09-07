// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/cupertino/list_tile/cupertino_list_tile.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test CupertinoListTile respects properties', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CupertinoListTileApp());

    final Finder cupertinoListTileFinder = find.byKey(const Key('CupertinoListTile with background color'));

    // Verify if the 'CupertinoListTile Sample' text is present.
    expect(find.text('CupertinoListTile Sample'), findsOneWidget);

    // Verify if the first CupertinoListTile with background color is present.
    expect(find.byType(CupertinoListTile), findsNWidgets(6));

    // Verify if the CupertinoListTile contains the expected widgets.
    expect(find.byType(FlutterLogo), findsNWidgets(4));
    expect(find.text('One-line with leading widget'), findsOneWidget);
    expect(find.text('One-line with trailing widget'), findsOneWidget);
    expect(find.text('One-line CupertinoListTile'), findsOneWidget);
    expect(find.text('One-line with both widgets'), findsOneWidget);
    expect(find.text('Two-line CupertinoListTile'), findsOneWidget);
    expect(find.text('Here is a subtitle'), findsOneWidget);
    expect(find.text('CupertinoListTile with background color'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNWidgets(3));
    expect(find.byIcon(Icons.info), findsOneWidget);
    expect((tester.firstWidget(cupertinoListTileFinder) as CupertinoListTile).backgroundColor, Colors.lightBlue);
  });
}
