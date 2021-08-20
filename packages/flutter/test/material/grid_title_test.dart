// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GridTile control test', (WidgetTester tester) async {
    final Key headerKey = UniqueKey();
    final Key footerKey = UniqueKey();

    await tester.pumpWidget(MaterialApp(
      home: GridTile(
        header: GridTileBar(
          key: headerKey,
          leading: const Icon(Icons.thumb_up),
          title: const Text('Header'),
          subtitle: const Text('Subtitle'),
          trailing: const Icon(Icons.thumb_up),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.green[500],
          ),
        ),
        footer: GridTileBar(
          key: footerKey,
          title: const Text('Footer'),
          backgroundColor: Colors.black38,
        ),
      ),
    ));

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Footer'), findsOneWidget);

    expect(
      tester.getBottomLeft(find.byKey(headerKey)).dy,
      lessThan(tester.getTopLeft(find.byKey(footerKey)).dy),
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: GridTile(child: Text('Simple')),
      ),
    );

    expect(find.text('Simple'), findsOneWidget);
  });

  testWidgets('GridTile consistent theme', (WidgetTester tester) async {
    final GridTile gridTile = GridTile(
      footer: GridTileBar(
        backgroundColor: Colors.blue,
        trailing: PopupMenuButton<String>(
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<String>(
                value: 'Flutter',
                child: Text('Working a lot harder'),
              ),
              const PopupMenuItem<String>(
                value: 'Dart',
                child: Text('Being a lot smarter'),
              ),
              const PopupMenuItem<String>(
                value: 'iOS',
                child: Text('Being a self-starter'),
              ),
            ];
          },
          icon: const Icon(
            Icons.more_vert,
            size: 28,
          ),
        ),
      ),
      child: const FlutterLogo(
        style: FlutterLogoStyle.horizontal,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: gridTile,
        ),
      ),
    );

    Theme theme = tester.firstWidget(find.byType(Theme));
    expect(theme.data, ThemeData.light());

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: gridTile,
        ),
      ),
    );

    await tester.pumpAndSettle();
    theme = tester.firstWidget(find.byType(Theme));
    expect(theme.data, ThemeData.light());

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: gridTile,
        ),
      ),
    );

    await tester.pumpAndSettle();
    theme = tester.firstWidget(find.byType(Theme));
    expect(theme.data, ThemeData.dark());

    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.light,
        home: Scaffold(
          body: gridTile,
        ),
      ),
    );

    await tester.pumpAndSettle();
    theme = tester.firstWidget(find.byType(Theme));
    expect(theme.data, ThemeData.light());
  });
}
