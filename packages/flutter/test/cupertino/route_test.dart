// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Middle auto-populates with title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Placeholder(),
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(
      CupertinoPageRoute<void>(
        title: 'An iPod',
        builder: (BuildContext context) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(),
            child: Placeholder(),
          );
        }
      )
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // There should be a Text widget with the title in the nav bar even though
    // we didn't specify anything in the nav bar constructor.
    expect(find.widgetWithText(CupertinoNavigationBar, 'An iPod'), findsOneWidget);

    // As a title, it should also be centered.
    expect(tester.getCenter(find.text('An iPod')).dx, 400.0);
  });

  testWidgets('Large title auto-populates with title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Placeholder(),
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(
      CupertinoPageRoute<void>(
        title: 'An iPod',
        builder: (BuildContext context) {
          return const CupertinoPageScaffold(
            child: CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverNavigationBar(),
              ],
            ),
          );
        }
      )
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // There should be 2 Text widget with the title in the nav bar. One in the
    // large title position and one in the middle position (though the middle
    // position Text is initially invisible while the sliver is expanded).
    expect(
      find.widgetWithText(CupertinoSliverNavigationBar, 'An iPod'),
      findsNWidgets(2),
    );

    final List<Element> titles = tester.elementList(find.text('An iPod'))
        .toList()
        ..sort((Element a, Element b) {
          final RenderParagraph aParagraph = a.renderObject;
          final RenderParagraph bParagraph = b.renderObject;
          return aParagraph.text.style.fontSize.compareTo(
            bParagraph.text.style.fontSize
          );
        });

    final Iterable<double> opacities = titles.map<double>((Element element) {
      final RenderAnimatedOpacity renderOpacity =
          element.ancestorRenderObjectOfType(const TypeMatcher<RenderAnimatedOpacity>());
      return renderOpacity.opacity.value;
    });

    expect(opacities, <double> [
        0.0, // Initially the smaller font title is invisible.
        1.0, // The larger font title is visible.
    ]);

    // Check that the large font title is at the right spot.
    expect(
      tester.getTopLeft(find.byWidget(titles[1].widget)),
      const Offset(16.0, 54.0),
    );

    // The smaller, initially invisible title, should still be positioned in the
    // center.
    expect(tester.getCenter(find.byWidget(titles[0].widget)).dx, 400.0);
  });

  testWidgets('Leading auto-populates with back button with previous title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Placeholder(),
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(
      CupertinoPageRoute<void>(
        title: 'An iPod',
        builder: (BuildContext context) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(),
            child: Placeholder(),
          );
        }
      )
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    tester.state<NavigatorState>(find.byType(Navigator)).push(
      CupertinoPageRoute<void>(
        title: 'A Phone',
        builder: (BuildContext context) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(),
            child: Placeholder(),
          );
        }
      )
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.widgetWithText(CupertinoNavigationBar, 'A Phone'), findsOneWidget);
    expect(tester.getCenter(find.text('A Phone')).dx, 400.0);

    // Also shows the previous page's title next to the back button.
    expect(find.widgetWithText(CupertinoButton, 'An iPod'), findsOneWidget);
    // 2 paddings + 1 ahem character at font size 34.0.
    expect(tester.getTopLeft(find.text('An iPod')).dx, 8.0 + 34.0 + 6.0);
  });

  testWidgets('Previous title is correct on first transition frame', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Placeholder(),
      ),
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(
      CupertinoPageRoute<void>(
        title: 'An iPod',
        builder: (BuildContext context) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(),
            child: Placeholder(),
          );
        }
      )
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    tester.state<NavigatorState>(find.byType(Navigator)).push(
      CupertinoPageRoute<void>(
        title: 'A Phone',
        builder: (BuildContext context) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(),
            child: Placeholder(),
          );
        }
      )
    );

    // Trigger the route push
    await tester.pump();
    // Draw the first frame.
    await tester.pump();

    // Also shows the previous page's title next to the back button.
    expect(find.widgetWithText(CupertinoButton, 'An iPod'), findsOneWidget);
  });

  testWidgets('Previous title stays up to date with changing routes', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Placeholder(),
      ),
    );

    final CupertinoPageRoute<void> route2 = CupertinoPageRoute<void>(
      title: 'An iPod',
      builder: (BuildContext context) {
        return const CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(),
          child: Placeholder(),
        );
      }
    );

    final CupertinoPageRoute<void> route3 = CupertinoPageRoute<void>(
      title: 'A Phone',
      builder: (BuildContext context) {
        return const CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(),
          child: Placeholder(),
        );
      }
    );

    tester.state<NavigatorState>(find.byType(Navigator)).push(route2);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    tester.state<NavigatorState>(find.byType(Navigator)).push(route3);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    tester.state<NavigatorState>(find.byType(Navigator)).replace(
      oldRoute: route2,
      newRoute: CupertinoPageRoute<void>(
        title: 'An Internet communicator',
        builder: (BuildContext context) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(),
            child: Placeholder(),
          );
        }
      )
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.widgetWithText(CupertinoNavigationBar, 'A Phone'), findsOneWidget);
    expect(tester.getCenter(find.text('A Phone')).dx, 400.0);

    // After swapping the route behind the top one, the previous label changes
    // from An iPod to Back (since An Internet communicator is too long to
    // fit in the back button).
    expect(find.widgetWithText(CupertinoButton, 'Back'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Back')).dx, 8.0 + 34.0 + 6.0);
  });
}
