// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';

void main() {
  testWidgets('Heroes work', (WidgetTester tester) async {
    await tester.pumpWidget(new CupertinoApp(
      home:
        new ListView(
          children: <Widget>[
            const Hero(tag: 'a', child: Text('foo')),
            new Builder(builder: (BuildContext context) {
              return new CupertinoButton(
                child: const Text('next'),
                onPressed: () {
                  Navigator.push(
                    context,
                    new CupertinoPageRoute<void>(
                      builder: (BuildContext context) {
                        return const Hero(tag: 'a', child: Text('foo'));
                      }
                    ),
                  );
                },
              );
            }),
          ],
        )
    ));

    await tester.tap(find.text('next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // During the hero transition, the hero widget is lifted off of both
    // page routes and exists as its own overlay on top of both routes.
    expect(find.widgetWithText(CupertinoPageRoute, 'foo'), findsNothing);
    expect(find.widgetWithText(Navigator, 'foo'), findsOneWidget);
  });
}
