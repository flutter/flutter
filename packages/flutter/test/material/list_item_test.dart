// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ListTile control test', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new Center(
          child: new ListTile(
            leading: new Icon(Icons.thumb_up),
            title: new Text('Title'),
            subtitle: new Text('Subtitle'),
            trailing: new Icon(Icons.info),
            enabled: false,
          ),
        ),
      ),
    ));

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Subtitle'), findsOneWidget);
  });

  testWidgets('ListTile control test', (WidgetTester tester) async {
    final List<String> titles = <String>[ 'first', 'second', 'third' ];

    await tester.pumpWidget(new MaterialApp(
      home: new Material(
        child: new Builder(
          builder: (BuildContext context) {
            return new ListView(
              children: ListTile.divideTiles(
                context: context,
                tiles: titles.map((String title) => new ListTile(title: new Text(title))),
              ).toList(),
            );
          },
        ),
      ),
    ));

    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsOneWidget);
    expect(find.text('third'), findsOneWidget);
  });
}
