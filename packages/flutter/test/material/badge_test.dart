// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';


void main() {
  testWidgets('Large Badge defaults', (WidgetTester tester) async {
    late final ThemeData theme;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Align(
          alignment: Alignment.topLeft,
          child: Builder(
            builder: (BuildContext context) {
              // theme.textTheme is updated when the MaterialApp is built.
              theme = Theme.of(context);
              return const Badge(
                label: Text('0'),
                child: Icon(Icons.add),
              );
            },
          ),
        ),
      ),
    );

    expect(
      tester.renderObject<RenderParagraph>(find.text('0')).text.style,
      theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onError),
    );

    // default badge alignment = AlignmentDirectional(12, -4)
    // default padding = EdgeInsets.symmetric(horizontal: 4)
    // default largeSize = 16
    // '0'.width = 12
    // icon.width = 24

    expect(tester.getSize(find.byType(Badge)), const Size(24, 24)); // default Icon size
    expect(tester.getTopLeft(find.byType(Badge)), Offset.zero);

    // x = alignment.start + padding.left
    // y = alignment.top
    expect(tester.getTopLeft(find.text('0')), const Offset(16, -4));

    final RenderBox box = tester.renderObject(find.byType(Badge));
    // '0'.width = 12
    // L = alignment.start
    // T = alignment.top
    // R = L + '0'.width + padding.width
    // B = T + largeSize, R = largeSize/2
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(12, -4, 32, 12, const Radius.circular(8)), color: theme.colorScheme.error));
  });

  testWidgets('Large Badge defaults with RTL', (WidgetTester tester) async {
    late final ThemeData theme;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.topLeft,
            child: Builder(
              builder: (BuildContext context) {
                // theme.textTheme is updated when the MaterialApp is built.
                theme = Theme.of(context);
                return const Badge(
                  label: Text('0'),
                  child: Icon(Icons.add),
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(
      tester.renderObject<RenderParagraph>(find.text('0')).text.style,
      theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onError),
    );

    // default badge alignment = AlignmentDirectional(12, -4)
    // default padding = EdgeInsets.symmetric(horizontal: 4)
    // default largeSize = 16
    // '0'.width = 12
    // icon.width = 24

    expect(tester.getSize(find.byType(Badge)), const Size(24, 24)); // default Icon size
    expect(tester.getTopLeft(find.byType(Badge)), Offset.zero);

    // x = icon.width - alignment.start - '0'.width - padding.right
    // y = alignment.top
    expect(tester.getTopLeft(find.text('0')), const Offset(-4, -4));

    final RenderBox box = tester.renderObject(find.byType(Badge));
    // L = icon.width - alignment.start - '0.width' - padding.width
    // T = alignment.top
    // R = L + '0.width' + padding.width
    // B = T + largeSize
    // R = largeSize/2
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(-8, -4, 12, 12, const Radius.circular(8)), color: theme.colorScheme.error));
  });

  // Essentially the same as 'Large Badge defaults'
  testWidgets('Badge.count', (WidgetTester tester) async {
    late final ThemeData theme;

    Widget buildFrame(int count) {
      return MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Align(
          alignment: Alignment.topLeft,
          child: Builder(
            builder: (BuildContext context) {
              // theme.textTheme is updated when the MaterialApp is built.
              if (count == 0) {
                theme = Theme.of(context);
              }
              return Badge.count(
                count: count,
                child: const Icon(Icons.add),
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(0));

    expect(
      tester.renderObject<RenderParagraph>(find.text('0')).text.style,
      theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onError),
    );

    // default badge alignment = AlignmentDirectional(12, -4)
    // default padding = EdgeInsets.symmetric(horizontal: 4)
    // default largeSize = 16
    // '0'.width = 12
    // icon.width = 24

    expect(tester.getSize(find.byType(Badge)), const Size(24, 24)); // default Icon size
    expect(tester.getTopLeft(find.byType(Badge)), Offset.zero);

    // x = alignment.start + padding.left
    // y = alignment.top
    expect(tester.getTopLeft(find.text('0')), const Offset(16, -4));

    final RenderBox box = tester.renderObject(find.byType(Badge));
    // '0'.width = 12
    // L = alignment.start
    // T = alignment.top
    // R = L + '0'.width + padding.width
    // B = T + largeSize, R = largeSize/2
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(12, -4, 32, 12, const Radius.circular(8)), color: theme.colorScheme.error));

    await tester.pumpWidget(buildFrame(1000));
    expect(find.text('999+'), findsOneWidget);
  });

  testWidgets('Small Badge defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData.light(useMaterial3: true);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Align(
          alignment: Alignment.topLeft,
          child: Badge(
            child: Icon(Icons.add),
          ),
        ),
      ),
    );

    // default badge location is end=0, top=0
    // default padding = EdgeInsets.symmetric(horizontal: 4)
    // default smallSize = 6
    // icon.width = 24

    expect(tester.getSize(find.byType(Badge)), const Size(24, 24)); // default Icon size
    expect(tester.getTopLeft(find.byType(Badge)), Offset.zero);

    final RenderBox box = tester.renderObject(find.byType(Badge));
    // L = icon.size.width - smallSize
    // T = 0
    // R = icon.size.width
    // B = smallSize
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(18, 0, 24, 6, const Radius.circular(3)), color: theme.colorScheme.error));
  });

  testWidgets('Small Badge RTL defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData.light(useMaterial3: true);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.topLeft,
            child: Badge(
              child: Icon(Icons.add),
            ),
          ),
        ),
      ),
    );

    // default badge location is end=0, top=0
    // default smallSize = 6
    // icon.width = 24

    expect(tester.getSize(find.byType(Badge)), const Size(24, 24)); // default Icon size
    expect(tester.getTopLeft(find.byType(Badge)), Offset.zero);

    final RenderBox box = tester.renderObject(find.byType(Badge));
    // L = 0
    // T = 0
    // R = smallSize
    // B = smallSize
    expect(box, paints..rrect(rrect: RRect.fromLTRBR(0, 0, 6, 6, const Radius.circular(3)), color: theme.colorScheme.error));
  });

  testWidgets('Large Badge textStyle and colors', (WidgetTester tester) async {
    final ThemeData theme = ThemeData.light(useMaterial3: true);
    const Color green = Color(0xff00ff00);
    const Color black = Color(0xff000000);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Align(
          alignment: Alignment.topLeft,
          child: Badge(
            textColor: green,
            backgroundColor: black,
            textStyle: TextStyle(fontSize: 10),
            label: Text('0'),
            child: Icon(Icons.add),
          ),
        ),
      ),
    );

    final TextStyle textStyle = tester.renderObject<RenderParagraph>(find.text('0')).text.style!;
    expect(textStyle.fontSize, 10);
    expect(textStyle.color, green);
    expect(tester.renderObject(find.byType(Badge)), paints..rrect(color: black));
  });

  testWidgets('isLabelVisible', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: const Align(
          alignment: Alignment.topLeft,
          child: Badge(
            label: Text('0'),
            isLabelVisible: false,
            child: Icon(Icons.add),
          ),
        ),
      ),
    );

    expect(find.text('0'), findsNothing);
    expect(find.byType(Icon), findsOneWidget);

    expect(tester.getSize(find.byType(Badge)), const Size(24, 24)); // default Icon size
    expect(tester.getTopLeft(find.byType(Badge)), Offset.zero);
    final RenderBox box = tester.renderObject(find.byType(Badge));
    expect(box, isNot(paints..rrect()));
  });
}
