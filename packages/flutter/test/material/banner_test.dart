// Copyright 2014 The Flutter Authors. All rights reserved.
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
            TextButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    );

    final Container container = _getContainerFromBanner(tester);
    expect(container.color, color);
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
            TextButton(
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
            TextButton(
              child: const Text('Action 1'),
              onPressed: () { },
            ),
            TextButton(
              child: const Text('Action 2'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    );

    final Offset contentBottomLeft = tester.getBottomLeft(find.text(contentText));
    final Offset actionsTopLeft = tester.getTopLeft(find.byType(OverflowBar));
    expect(contentBottomLeft.dy, lessThan(actionsTopLeft.dy));
    expect(contentBottomLeft.dx, lessThan(actionsTopLeft.dx));
  });

  testWidgets('Actions laid out beside content if only one action', (WidgetTester tester) async {
    const String contentText = 'Content';

    await tester.pumpWidget(
      MaterialApp(
        home: MaterialBanner(
          content: const Text(contentText),
          actions: <Widget>[
            TextButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    );

    final Offset contentBottomLeft = tester.getBottomLeft(find.text(contentText));
    final Offset actionsTopRight = tester.getTopRight(find.byType(OverflowBar));
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
            TextButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    );

    final Offset actionsTopRight = tester.getTopRight(find.byType(OverflowBar));
    final Offset bannerTopRight = tester.getTopRight(find.byType(MaterialBanner));
    expect(actionsTopRight.dx + 8, bannerTopRight.dx); // actions OverflowBar is padded by 8
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
              TextButton(
                child: const Text('Action'),
                onPressed: () { },
              ),
            ],
          ),
        ),
      ),
    );

    final Offset actionsTopLeft = tester.getTopLeft(find.byType(OverflowBar));
    final Offset bannerTopLeft = tester.getTopLeft(find.byType(MaterialBanner));
    expect(actionsTopLeft.dx - 8, bannerTopLeft.dx); // actions OverflowBar is padded by 8
  });

  testWidgets('Actions laid out below content if forced override', (WidgetTester tester) async {
    const String contentText = 'Content';

    await tester.pumpWidget(
      MaterialApp(
        home: MaterialBanner(
          forceActionsBelow: true,
          content: const Text(contentText),
          actions: <Widget>[
            TextButton(
              child: const Text('Action'),
              onPressed: () { },
            ),
          ],
        ),
      ),
    );

    final Offset contentBottomLeft = tester.getBottomLeft(find.text(contentText));
    final Offset actionsTopLeft = tester.getTopLeft(find.byType(OverflowBar));
    expect(contentBottomLeft.dy, lessThan(actionsTopLeft.dy));
    expect(contentBottomLeft.dx, lessThan(actionsTopLeft.dx));
  });

  testWidgets('Action widgets layout', (WidgetTester tester) async {
    // This regression test ensures that the action widgets layout matches what
    // it was, before ButtonBar was replaced by OverflowBar.

    Widget buildFrame(int actionCount, TextDirection textDirection) {
      return MaterialApp(
        home: Directionality(
          textDirection: textDirection,
          child: MaterialBanner(
            content: const SizedBox(width: 100, height: 100),
            actions: List<Widget>.generate(actionCount, (int index) {
              return SizedBox(
                width: 64,
                height: 48,
                key: ValueKey<int>(index),
              );
            }),
          ),
        ),
      );
    }

    final Finder action0 = find.byKey(const ValueKey<int>(0));
    final Finder action1 = find.byKey(const ValueKey<int>(1));
    final Finder action2 = find.byKey(const ValueKey<int>(2));

    // The action coordinates that follow were obtained by running
    // the test code, before ButtonBar was replaced by OverflowBar.

    await tester.pumpWidget(buildFrame(1, TextDirection.ltr));
    expect(tester.getTopLeft(action0), const Offset(728, 28));

    await tester.pumpWidget(buildFrame(1, TextDirection.rtl));
    expect(tester.getTopLeft(action0), const Offset(8, 28));

    await tester.pumpWidget(buildFrame(3, TextDirection.ltr));
    expect(tester.getTopLeft(action0), const Offset(584, 130));
    expect(tester.getTopLeft(action1), const Offset(656, 130));
    expect(tester.getTopLeft(action2), const Offset(728, 130));

    await tester.pumpWidget(buildFrame(3, TextDirection.rtl));
    expect(tester.getTopLeft(action0), const Offset(152, 130));
    expect(tester.getTopLeft(action1), const Offset(80, 130));
    expect(tester.getTopLeft(action2), const Offset(8, 130));
  });

  testWidgets('Action widgets layout with overflow', (WidgetTester tester) async {
    // This regression test ensures that the action widgets layout matches what
    // it was, before ButtonBar was replaced by OverflowBar.

    const int actionCount = 4;
    Widget buildFrame(TextDirection textDirection) {
      return MaterialApp(
        home: Directionality(
          textDirection: textDirection,
          child: MaterialBanner(
            content: const SizedBox(width: 100, height: 100),
            actions: List<Widget>.generate(actionCount, (int index) {
              return SizedBox(
                width: 200,
                height: 10,
                key: ValueKey<int>(index),
              );
            }),
          ),
        ),
      );
    }

    // The action coordinates that follow were obtained by running
    // the test code, before ButtonBar was replaced by OverflowBar.

    await tester.pumpWidget(buildFrame(TextDirection.ltr));
    for (int index = 0; index < actionCount; index += 1) {
      expect(tester.getTopLeft(find.byKey(ValueKey<int>(index))), Offset(592, 134.0 + index * 10));
    }

    await tester.pumpWidget(buildFrame(TextDirection.rtl));
    for (int index = 0; index < actionCount; index += 1) {
      expect(tester.getTopLeft(find.byKey(ValueKey<int>(index))), Offset(8, 134.0 + index * 10));
    }
  });

  testWidgets('[overflowAlignment] test', (WidgetTester tester) async {
    const int actionCount = 4;
    Widget buildFrame(TextDirection textDirection, OverflowBarAlignment overflowAlignment) {
      return MaterialApp(
        home: Directionality(
          textDirection: textDirection,
          child: MaterialBanner(
            overflowAlignment: overflowAlignment,
            content: const SizedBox(width: 100, height: 100),
            actions: List<Widget>.generate(actionCount, (int index) {
              return SizedBox(
                width: 200,
                height: 10,
                key: ValueKey<int>(index),
              );
            }),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(TextDirection.ltr, OverflowBarAlignment.start));
    for (int index = 0; index < actionCount; index += 1) {
      expect(tester.getTopLeft(find.byKey(ValueKey<int>(index))), Offset(8, 134.0 + index * 10));
    }

    await tester.pumpWidget(buildFrame(TextDirection.ltr, OverflowBarAlignment.center));
    for (int index = 0; index < actionCount; index += 1) {
      expect(tester.getTopLeft(find.byKey(ValueKey<int>(index))), Offset(300, 134.0 + index * 10));
    }

    await tester.pumpWidget(buildFrame(TextDirection.ltr, OverflowBarAlignment.end));
    for (int index = 0; index < actionCount; index += 1) {
      expect(tester.getTopLeft(find.byKey(ValueKey<int>(index))), Offset(592, 134.0 + index * 10));
    }
  });
}

Container _getContainerFromBanner(WidgetTester tester) {
  return tester.widget<Container>(find.descendant(of: find.byType(MaterialBanner), matching: find.byType(Container)).first);
}

RenderParagraph _getTextRenderObjectFromDialog(WidgetTester tester, String text) {
  return tester.element<StatelessElement>(find.descendant(of: find.byType(MaterialBanner), matching: find.text(text))).renderObject! as RenderParagraph;
}
