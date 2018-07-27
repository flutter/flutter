// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('GridTile control test', (WidgetTester tester) async {
    final Key headerKey = new UniqueKey();
    final Key footerKey = new UniqueKey();

    await tester.pumpWidget(new MaterialApp(
      home: new GridTile(
        header: new GridTileBar(
          key: headerKey,
          leading: const Icon(Icons.thumb_up),
          title: const Text('Header'),
          subtitle: const Text('Subtitle'),
          trailing: const Icon(Icons.thumb_up),
        ),
        child: new DecoratedBox(
          decoration: new BoxDecoration(
            color: Colors.green[500],
          ),
        ),
        footer: new GridTileBar(
          key: footerKey,
          title: const Text('Footer'),
          backgroundColor: Colors.black38,
        ),
      ),
    ));

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Footer'), findsOneWidget);

    expect(tester.getBottomLeft(find.byKey(headerKey)).dy,
           lessThan(tester.getTopLeft(find.byKey(footerKey)).dy));

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: const GridTile(child: const Text('Simple')),
      ),
    );

    expect(find.text('Simple'), findsOneWidget);
  });
}
