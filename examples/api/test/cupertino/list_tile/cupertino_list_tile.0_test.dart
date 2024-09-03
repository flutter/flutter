// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_samples/cupertino/list_tile/cupertino_list_tile.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test CupertinoListTile renders correctly with background color', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CupertinoListTileApp());

    final Finder cupertinoListTileFinder= find.byType(CupertinoListTile);

    // Verify if the 'CupertinoListTile Sample' text is present
    expect(find.text('CupertinoListTile Sample'), findsOneWidget);

    // Verify if the first CupertinoListTile with background color is present
    expect(find.byType(CupertinoListTile), findsOneWidget);

    // Verify if the CupertinoListTile contains the expected widgets
    expect(find.byIcon(Icons.leaderboard), findsOneWidget);
    expect(find.text('Here is the title'), findsOneWidget);
    expect(find.text('Here is a second line'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect((tester.firstWidget(cupertinoListTileFinder) as CupertinoListTile).backgroundColor, Colors.red);
  });

}
