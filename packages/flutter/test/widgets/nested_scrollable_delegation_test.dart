// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets_app_tester.dart';

void main() {
  group('Nested scrollable delegation', () {
    testWidgets('delegateOverscroll true: inner scroll overscroll is delegated to the parent', (
      WidgetTester tester,
    ) async {
      final outerController = ScrollController();
      addTearDown(outerController.dispose);

      await tester.pumpWidget(
        TestWidgetsApp(
          home: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(delegateOverscroll: true),
            child: SingleChildScrollView(
              controller: outerController,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 100, child: Center(child: Text('Header'))),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: 10,
                      itemBuilder: (BuildContext context, int index) {
                        return SizedBox(
                          height: 100,
                          child: Center(child: Text('DelegateInner $index')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 500, child: Center(child: Text('Footer'))),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.fling(find.text('DelegateInner 1'), const Offset(0, -2000), 3000);
      await tester.pumpAndSettle();
      expect(outerController.offset, greaterThan(0.0));
    });
    testWidgets(
      'delegateOverscroll false: inner scroll overscroll is NOT delegated to the parent',
      (WidgetTester tester) async {
        final outerController = ScrollController();
        addTearDown(outerController.dispose);

        await tester.pumpWidget(
          TestWidgetsApp(
            home: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(delegateOverscroll: false),
              child: SingleChildScrollView(
                controller: outerController,
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 100, child: Center(child: Text('Header'))),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (BuildContext context, int index) {
                          return SizedBox(
                            height: 100,
                            child: Center(child: Text('DelegateInner $index')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 500, child: Center(child: Text('Footer'))),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.fling(find.text('DelegateInner 1'), const Offset(0, -2000), 3000);
        await tester.pumpAndSettle();

        expect(outerController.offset, equals(0.0));
      },
    );

    testWidgets('Overscroll does NOT delegate across different axes', (WidgetTester tester) async {
      final pageController = PageController();
      addTearDown(pageController.dispose);

      await tester.pumpWidget(
        TestWidgetsApp(
          home: PageView(
            controller: pageController,
            children: <Widget>[
              ListView.builder(
                itemCount: 5,
                itemBuilder: (BuildContext context, int index) {
                  return SizedBox(height: 100, child: Text('V-Item $index'));
                },
              ),
              const Center(child: Text('Page 2')),
            ],
          ),
        ),
      );

      expect(pageController.page, 0.0);
      await tester.fling(find.text('V-Item 0'), const Offset(0, -300), 1000);
      await tester.pumpAndSettle();

      await tester.fling(find.text('V-Item 4'), const Offset(0, -300), 1000);
      await tester.pumpAndSettle();

      expect(pageController.page, 0.0);
    });

    testWidgets(
      'Horizontal ListView inside vertical PageView does not trigger page scroll on overscroll',
      (WidgetTester tester) async {
        final pageController = PageController();
        addTearDown(pageController.dispose);

        await tester.pumpWidget(
          TestWidgetsApp(
            home: PageView(
              controller: pageController,
              scrollDirection: Axis.vertical,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    const Text('Page 1'),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (BuildContext context, int index) {
                          return SizedBox(width: 100, child: Center(child: Text('H-$index')));
                        },
                      ),
                    ),
                  ],
                ),
                const Center(child: Text('Page 2')),
              ],
            ),
          ),
        );

        expect(pageController.page, 0.0);
        await tester.fling(find.text('H-0'), const Offset(-300, 0), 1000);
        await tester.pumpAndSettle();

        await tester.fling(find.text('H-4'), const Offset(-100, 0), 1000);
        await tester.pumpAndSettle();

        expect(pageController.page, 0.0);
      },
    );
  });
}
