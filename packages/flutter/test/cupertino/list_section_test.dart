// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows header', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoListSection(
            header: const Text('Header'),
            children: const <Widget>[
              CupertinoListTile(title: Text('CupertinoListTile')),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Header'), findsOneWidget);
  });

  testWidgets('shows footer', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoListSection(
            footer: const Text('Footer'),
            children: const <Widget>[
              CupertinoListTile(title: Text('CupertinoListTile')),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Footer'), findsOneWidget);
  });

  testWidgets('shows long dividers in edge-to-edge section part 1', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoListSection(
            children: const <Widget>[
              CupertinoListTile(title: Text('CupertinoListTile')),
            ],
          ),
        ),
      ),
    );

    // Since the children list is reconstructed with dividers in it, the column
    // retrieved should have 3 items for an input [children] param with 1 child.
    final Column childrenColumn = tester.widget(find.byType(Column).at(1));
    expect(childrenColumn.children.length, 3);
  });

  testWidgets('shows long dividers in edge-to-edge section part 2', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoListSection(
            children: const <Widget>[
              CupertinoListTile(title: Text('CupertinoListTile')),
              CupertinoListTile(title: Text('CupertinoListTile')),
            ],
          ),
        ),
      ),
    );

    // Since the children list is reconstructed with dividers in it, the column
    // retrieved should have 5 items for an input [children] param with 2
    // children. Two long dividers, two rows, and one short divider.
    final Column childrenColumn = tester.widget(find.byType(Column).at(1));
    expect(childrenColumn.children.length, 5);
  });

  testWidgets('does not show long dividers in insetGrouped section part 1', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoListSection.insetGrouped(
            children: const <Widget>[
              CupertinoListTile(title: Text('CupertinoListTile')),
            ],
          ),
        ),
      ),
    );

    // Since the children list is reconstructed without long dividers in it, the
    // column retrieved should have 1 item for an input [children] param with 1
    // child.
    final Column childrenColumn = tester.widget(find.byType(Column).at(1));
    expect(childrenColumn.children.length, 1);
  });

  testWidgets('does not show long dividers in insetGrouped section part 2', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoListSection.insetGrouped(
            children: const <Widget>[
              CupertinoListTile(title: Text('CupertinoListTile')),
              CupertinoListTile(title: Text('CupertinoListTile')),
            ],
          ),
        ),
      ),
    );

    // Since the children list is reconstructed with short dividers in it, the
    // column retrieved should have 3 items for an input [children] param with 2
    // children. Two long dividers, two rows, and one short divider.
    final Column childrenColumn = tester.widget(find.byType(Column).at(1));
    expect(childrenColumn.children.length, 3);
  });

  testWidgets('sets background color for section', (WidgetTester tester) async {
    const Color backgroundColor = CupertinoColors.systemBlue;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: CupertinoListSection(
            backgroundColor: backgroundColor,
            children: const <Widget>[
              CupertinoListTile(title: Text('CupertinoListTile')),
            ],
          ),
        ),
      ),
    );

    final DecoratedBox decoratedBox = tester.widget(find.byType(DecoratedBox).first);
    final BoxDecoration boxDecoration = decoratedBox.decoration as BoxDecoration;
    expect(boxDecoration.color, backgroundColor);
  });

  testWidgets('setting clipBehavior clips children section', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoListSection(
            clipBehavior: Clip.antiAlias,
            children: const <Widget>[
              CupertinoListTile(title: Text('CupertinoListTile')),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(ClipRRect), findsOneWidget);
  });

  testWidgets('not setting clipBehavior does not clip children section', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoListSection(
            children: const <Widget>[
              CupertinoListTile(title: Text('CupertinoListTile')),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(ClipRRect), findsNothing);
  });
}
