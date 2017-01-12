// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('GridTile control test', (WidgetTester tester) async {
    Key headerKey = new UniqueKey();
    Key footerKey = new UniqueKey();

    await tester.pumpWidget(new GridTile(
      header: new GridTileBar(
        key: headerKey,
        leading: new Icon(Icons.thumb_up),
        title: new Text('Header'),
        subtitle: new Text('Subtitle'),
        trailing: new Icon(Icons.thumb_up),
      ),
      child: new DecoratedBox(
        decoration: new BoxDecoration(
          backgroundColor: Colors.green[500],
        ),
      ),
      footer: new GridTileBar(
        key: footerKey,
        title: new Text('Footer'),
        backgroundColor: Colors.black38,
      ),
    ));

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Footer'), findsOneWidget);

    expect(tester.getBottomLeft(find.byKey(headerKey)).y,
           lessThan(tester.getTopLeft(find.byKey(footerKey)).y));

    await tester.pumpWidget(new GridTile(child: new Text('Simple')));

    expect(find.text('Simple'), findsOneWidget);
  });
}
