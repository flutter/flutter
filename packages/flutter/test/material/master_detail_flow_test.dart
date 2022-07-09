// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'MasterDetailFlow tester',
    (WidgetTester tester) async {
      final Key listTileKey1 = GlobalKey();
      final Key listTileKey2 = GlobalKey();

      Widget buildFrame() {
        return MaterialApp(
          home: MasterDetailFlow.fromItems(
            masterItems: <MasterDetailFlowItem>[
              MasterDetailFlowItem(
                title: const Text('KeyOne'),
                detailsListChildBuilder: (BuildContext context, int index) =>
                    const Text(
                  'Key One Details',
                ),
                detailsChildrenCount: 1,
                key: listTileKey1,
              ),
              MasterDetailFlowItem(
                title: const Text('KeyTwo'),
                detailsListChildBuilder: (BuildContext context, int index) =>
                    const Text(
                      'Key Two Details',
                    ),
                detailsChildrenCount: 2,
                key: listTileKey2,
              ),
            ],
          ),
        );
      }

      void testMasterChildren() {
        expect(find.byKey(listTileKey1), findsOneWidget);
        expect(find.byKey(listTileKey2), findsOneWidget);
      }

      Future<void> testOpenDetailsPage(bool secondTile) async {
        expect(find.text('Key One Details'), findsNothing);
        expect(find.text('Key Two Details'), findsNothing);

        if(secondTile) {
          await tester.tap(find.byKey(listTileKey2));
          await tester.pumpAndSettle();

          expect(find.text('Key One Details'), findsNothing);
          expect(find.text('Key Two Details'), findsNWidgets(2));
        } else {
          await tester.tap(find.byKey(listTileKey1));
          await tester.pumpAndSettle();

          expect(find.text('Key One Details'), findsOneWidget);
          expect(find.text('Key Two Details'), findsNothing);
        }
      }

      await tester.pumpWidget(buildFrame());
      testMasterChildren();
      await testOpenDetailsPage(false);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await testOpenDetailsPage(true);
    },
  );
}
