// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can be controlled by ExpansibleController', (WidgetTester tester) async {
    final ExpansibleController controller = ExpansibleController();
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: CupertinoExpansionTile(
            controller: controller,
            title: const Text('Title'),
            child: const Text('Content'),
          ),
        ),
      ),
    );

    expect(controller.isExpanded, isFalse);
    expect(find.text('Content'), findsNothing);

    controller.expand();
    await tester.pump();
    expect(controller.isExpanded, isTrue);
    expect(find.text('Content'), findsOneWidget);

    controller.collapse();
    await tester.pump();
    expect(controller.isExpanded, isFalse);
    expect(find.text('Content'), findsNothing);
  });

  testWidgets('Toggles expansion on tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: CupertinoExpansionTile(title: Text('Title'), child: Text('Content')),
        ),
      ),
    );

    expect(find.text('Content'), findsNothing);

    await tester.tap(find.text('Title'));
    await tester.pump();
    // The child animating its height and a clone fading in.
    expect(find.text('Content'), findsNWidgets(2));

    await tester.tap(find.text('Title'));
    await tester.pump();
    expect(find.text('Content'), findsNothing);
  });

  testWidgets('Animates icon rotation on tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: CupertinoExpansionTile(title: Text('Title'), child: Text('Content')),
        ),
      ),
    );

    final Finder iconFinder = find.text(
      String.fromCharCode(CupertinoIcons.right_chevron.codePoint),
      findRichText: true,
    );
    expect(iconFinder, findsOneWidget);

    expect(tester.getTopLeft(iconFinder).dx, moreOrLessEquals(770.2, epsilon: 0.01));
    expect(tester.getTopLeft(iconFinder).dy, moreOrLessEquals(14.5, epsilon: 0.01));

    await tester.tap(find.text('Title'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(iconFinder).dx, moreOrLessEquals(785.0, epsilon: 0.01));
    expect(tester.getTopLeft(iconFinder).dy, moreOrLessEquals(14.7, epsilon: 0.01));

    await tester.tap(find.text('Title'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(iconFinder).dx, moreOrLessEquals(770.2, epsilon: 0.01));
    expect(tester.getTopLeft(iconFinder).dy, moreOrLessEquals(14.5, epsilon: 0.01));
  });

  testWidgets('Fade transition shows and hides child with animation', (WidgetTester tester) async {
    const Duration infinitesimalDuration = Duration(microseconds: 1);
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: CupertinoExpansionTile(title: Text('Title'), child: Text('Content')),
        ),
      ),
    );

    expect(find.text('Content'), findsNothing);

    await tester.tap(find.text('Title'));
    await tester.pump();

    // Pump until halfway through the animation.
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Content'), findsNWidgets(2));
    expect(find.byType(FadeTransition), findsOneWidget);
    expect(
      tester
          .firstRenderObject<RenderAnimatedOpacity>(
            find.ancestor(of: find.text('Content').last, matching: find.byType(FadeTransition)),
          )
          .opacity
          .value,
      moreOrLessEquals(0.5, epsilon: 0.001),
    );

    // At the end of the animation, the fading content has completely disappeared.
    await tester.pump(const Duration(milliseconds: 150) + infinitesimalDuration);
    expect(find.text('Content'), findsOneWidget);

    await tester.tap(find.text('Title'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300) + infinitesimalDuration);
    expect(find.text('Content'), findsNothing);
  });

  testWidgets('Scroll transition shows and hides child with animation', (
    WidgetTester tester,
  ) async {
    const Duration infinitesimalDuration = Duration(microseconds: 1);
    const double placeholderHeight = 50.0;
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: CupertinoExpansionTile(
            title: Text('Title'),
            transitionMode: ExpansionTileTransitionMode.scroll,
            child: SizedBox(height: placeholderHeight, child: Placeholder()),
          ),
        ),
      ),
    );

    expect(find.text('Content'), findsNothing);
    final double begin = tester.getBottomLeft(find.byType(CupertinoListTile)).dy;

    await tester.tap(find.text('Title'));
    await tester.pump();

    // Pump until halfway through the animation.
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(Placeholder), findsOneWidget);
    // The content does not fade.
    expect(find.byType(FadeTransition), findsNothing);
    expect(
      tester.getBottomLeft(find.byType(Placeholder)).dy,
      moreOrLessEquals(81.5, epsilon: 0.01),
    );

    // Pump until the end of the animation.
    await tester.pump(const Duration(milliseconds: 150) + infinitesimalDuration);
    expect(
      tester.getBottomLeft(find.byType(Placeholder)).dy,
      moreOrLessEquals(begin + placeholderHeight, epsilon: 0.01),
    );
  });

  testWidgets('Nested expansion tile', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: CupertinoPageScaffold(
          child: CupertinoExpansionTile(
            title: Text('Outer'),
            child: CupertinoExpansionTile(title: Text('Inner'), child: Text('Content')),
          ),
        ),
      ),
    );

    expect(find.text('Content'), findsNothing);

    await tester.tap(find.text('Outer'));
    await tester.pumpAndSettle();
    expect(find.text('Content'), findsNothing);

    await tester.tap(find.text('Inner'));
    await tester.pumpAndSettle();
    expect(find.text('Content'), findsOneWidget);

    await tester.tap(find.text('Inner'));
    await tester.pumpAndSettle();
    expect(find.text('Content'), findsNothing);

    await tester.tap(find.text('Outer'));
    await tester.pumpAndSettle();
    expect(find.text('Content'), findsNothing);
  });
}
