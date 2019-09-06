// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Custom background color respected', (WidgetTester tester) async {
    const Color color = Colors.pink;
    await tester.pumpWidget(
      MaterialApp(
        home: MaterialBanner(
          backgroundColor: color,
          content: const Text('I am a banner'),
          actions: <Widget>[
            FlatButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    );

    final Container container = _getContainerFromBanner(tester);
    expect(container.decoration, const BoxDecoration(color: color));
  });

  testWidgets('Custom content TextStyle respected', (WidgetTester tester) async {
    const String contentText = 'Content';
    const TextStyle contentTextStyle = TextStyle(color: Colors.pink);
    await tester.pumpWidget(
      MaterialApp(
        home: MaterialBanner(
          contentTextStyle: contentTextStyle,
          content: const Text(contentText),
          actions: <Widget>[
            FlatButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    );

    final RenderParagraph content = _getTextRenderObjectFromDialog(tester, contentText);
    expect(content.text.style, contentTextStyle);
  });

  testWidgets('Actions laid out below content if more than one action', (WidgetTester tester) async {
    const String contentText = 'Content';

    await tester.pumpWidget(
      MaterialApp(
        home: MaterialBanner(
          content: const Text(contentText),
          actions: <Widget>[
            FlatButton(
              child: const Text('Action 1'),
              onPressed: () { },
            ),
            FlatButton(
              child: const Text('Action 2'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    );

    final Offset contentBottomLeft = tester.getBottomLeft(find.text(contentText));
    final Offset actionsTopRight = tester.getTopLeft(find.byType(ButtonBar));
    expect(contentBottomLeft.dy, lessThan(actionsTopRight.dy));
    expect(contentBottomLeft.dx, greaterThan(actionsTopRight.dx));
  });

  testWidgets('Actions laid out beside content if only one action', (WidgetTester tester) async {
    const String contentText = 'Content';

    await tester.pumpWidget(
      MaterialApp(
        home: MaterialBanner(
          content: const Text(contentText),
          actions: <Widget>[
            FlatButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    );

    final Offset contentBottomLeft = tester.getBottomLeft(find.text(contentText));
    final Offset actionsTopRight = tester.getTopRight(find.byType(ButtonBar));
    expect(contentBottomLeft.dy, greaterThan(actionsTopRight.dy));
    expect(contentBottomLeft.dx, lessThan(actionsTopRight.dx));
  });

  // Regression test for https://github.com/flutter/flutter/issues/39574
  testWidgets('Single action laid out beside content but aligned to the trailing edge', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MaterialBanner(
          content: const Text('Content'),
          actions: <Widget>[
            FlatButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    );

    final Offset actionsTopRight = tester.getTopRight(find.byType(ButtonBar));
    final Offset bannerTopRight = tester.getTopRight(find.byType(MaterialBanner));
    expect(actionsTopRight.dx, bannerTopRight.dx);
  });

  // Regression test for https://github.com/flutter/flutter/issues/39574
  testWidgets('Single action laid out beside content but aligned to the trailing edge - RTL', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
        textDirection: TextDirection.rtl,
          child: MaterialBanner(
            content: const Text('Content'),
            actions: <Widget>[
              FlatButton(
                child: const Text('Action'),
                onPressed: () { },
              ),
            ],
          ),
        ),
      ),
    );

    final Offset actionsTopLeft = tester.getTopLeft(find.byType(ButtonBar));
    final Offset bannerTopLeft = tester.getTopLeft(find.byType(MaterialBanner));
    expect(actionsTopLeft.dx, bannerTopLeft.dx);
  });

  testWidgets('Actions laid out below content if forced override', (WidgetTester tester) async {
    const String contentText = 'Content';

    await tester.pumpWidget(
      MaterialApp(
        home: MaterialBanner(
          forceActionsBelow: true,
          content: const Text(contentText),
          actions: <Widget>[
            FlatButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    );

    final Offset contentBottomLeft = tester.getBottomLeft(find.text(contentText));
    final Offset actionsTopRight = tester.getTopLeft(find.byType(ButtonBar));
    expect(contentBottomLeft.dy, lessThan(actionsTopRight.dy));
    expect(contentBottomLeft.dx, greaterThan(actionsTopRight.dx));
  });
}

Container _getContainerFromBanner(WidgetTester tester) {
  return tester.widget<Container>(find.descendant(of: find.byType(MaterialBanner), matching: find.byType(Container)).first);
}

RenderParagraph _getTextRenderObjectFromDialog(WidgetTester tester, String text) {
  return tester.element<StatelessElement>(find.descendant(of: find.byType(MaterialBanner), matching: find.text(text))).renderObject;
}
