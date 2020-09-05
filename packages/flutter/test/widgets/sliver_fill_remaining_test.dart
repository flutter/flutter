// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {

  // Helpers
  final Widget sliverBox = SliverToBoxAdapter(
    child: Container(
      color: Colors.amber,
      height: 150.0,
      width: 150,
    ),
  );
  Widget boilerplate(
    List<Widget> slivers, {
      ScrollController controller,
      Axis scrollDirection = Axis.vertical,
    }) {
    return MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          scrollDirection: scrollDirection,
          slivers: slivers,
          controller: controller,
        ),
      ),
    );
  }

  group('SliverFillRemaining', () {
    group('hasScrollBody: true, default', () {
      testWidgets('no siblings', (WidgetTester tester) async {
        final ScrollController controller = ScrollController();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              controller: controller,
              slivers: <Widget>[
                SliverFillRemaining(child: Container()),
              ],
            ),
          ),
        );
        expect(
          tester.renderObject<RenderBox>(find.byType(Container)).size.height,
          equals(600.0),
        );

        controller.jumpTo(50.0);
        await tester.pump();
        expect(
          tester.renderObject<RenderBox>(find.byType(Container)).size.height,
          equals(600.0),
        );

        controller.jumpTo(-100.0);
        await tester.pump();
        expect(
          tester.renderObject<RenderBox>(find.byType(Container)).size.height,
          equals(600.0),
        );

        controller.jumpTo(0.0);
        await tester.pump();
        expect(
          tester.renderObject<RenderBox>(find.byType(Container)).size.height,
          equals(600.0),
        );
      });

      testWidgets('one sibling', (WidgetTester tester) async {
        final ScrollController controller = ScrollController();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CustomScrollView(
              controller: controller,
              slivers: <Widget>[
                const SliverToBoxAdapter(child: SizedBox(height: 100.0)),
                SliverFillRemaining(child: Container()),
              ],
            ),
          ),
        );
        expect(
          tester.renderObject<RenderBox>(find.byType(Container)).size.height,
          equals(500.0),
        );

        controller.jumpTo(50.0);
        await tester.pump();
        expect(
          tester.renderObject<RenderBox>(find.byType(Container)).size.height,
          equals(550.0),
        );

        controller.jumpTo(-100.0);
        await tester.pump();
        expect(
          tester.renderObject<RenderBox>(find.byType(Container)).size.height,
          equals(400.0),
        );

        controller.jumpTo(0.0);
        await tester.pump();
        expect(
          tester.renderObject<RenderBox>(find.byType(Container)).size.height,
          equals(500.0),
        );
      });

      testWidgets('scrolls beyond viewportMainAxisExtent', (WidgetTester tester) async {
        final ScrollController controller = ScrollController();
        final List<Widget> slivers = <Widget>[
          sliverBox,
          SliverFillRemaining(
            child: Container(color: Colors.white),
          ),
        ];
        await tester.pumpWidget(boilerplate(slivers, controller: controller));
        expect(controller.offset, 0.0);
        expect(find.byType(Container), findsNWidgets(2));
        controller.jumpTo(150.0);
        await tester.pumpAndSettle();
        expect(controller.offset, 150.0);
        expect(find.byType(Container), findsOneWidget);
      });
    });

    group('hasScrollBody: false', () {
      testWidgets('does not extend past viewportMainAxisExtent', (WidgetTester tester) async {
        final ScrollController controller = ScrollController();
        final List<Widget> slivers = <Widget>[
          sliverBox,
          SliverFillRemaining(
            child: Container(color: Colors.white),
            hasScrollBody: false,
          ),
        ];

        await tester.pumpWidget(boilerplate(slivers, controller: controller));
        expect(controller.offset, 0.0);
        expect(find.byType(Container), findsNWidgets(2));
        controller.jumpTo(150.0);
        await tester.pumpAndSettle();
        expect(controller.offset, 0.0);
        expect(find.byType(Container), findsNWidgets(2));
      });

      testWidgets('child without size is sized by extent', (WidgetTester tester) async {
        final List<Widget> slivers = <Widget>[
          sliverBox,
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(color: Colors.blue),
          ),
        ];

        await tester.pumpWidget(boilerplate(slivers));
        RenderBox box = tester.renderObject<RenderBox>(find.byType(Container).last);
        expect(box.size.height, equals(450));

        await tester.pumpWidget(boilerplate(
          slivers,
          scrollDirection: Axis.horizontal,
        ));
        box = tester.renderObject<RenderBox>(find.byType(Container).last);
        expect(box.size.width, equals(650));
      });

      testWidgets('child with smaller size is sized by extent', (WidgetTester tester) async {
        final GlobalKey key = GlobalKey();
        final List<Widget> slivers = <Widget>[
          sliverBox,
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              key: key,
              color: Colors.blue,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  child: const Text('bottomCenter button'),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ];
        await tester.pumpWidget(boilerplate(slivers));
        expect(
          tester.renderObject<RenderBox>(find.byKey(key)).size.height,
          equals(450),
        );

        // Also check that the button alignment is true to expectations
        final Finder button = find.byType(ElevatedButton);
        expect(tester.getBottomLeft(button).dy, equals(600.0));
        expect(tester.getCenter(button).dx, equals(400.0));

        // Check Axis.horizontal
        await tester.pumpWidget(boilerplate(
          slivers,
          scrollDirection: Axis.horizontal,
        ));
        expect(
          tester.renderObject<RenderBox>(find.byKey(key)).size.width,
          equals(650),
        );
      });

      testWidgets('extent is overridden by child with larger size', (WidgetTester tester) async {
        final List<Widget> slivers = <Widget>[
          sliverBox,
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              color: Colors.blue,
              height: 600,
              width: 1000,
            ),
          ),
        ];
        await tester.pumpWidget(boilerplate(slivers));
        RenderBox box = tester.renderObject<RenderBox>(find.byType(Container).last);
        expect(box.size.height, equals(600));

        await tester.pumpWidget(boilerplate(
          slivers,
          scrollDirection: Axis.horizontal,
        ));
        box = tester.renderObject<RenderBox>(find.byType(Container).last);
        expect(box.size.width, equals(1000));
      });

      testWidgets('extent is overridden by child size if precedingScrollExtent > viewportMainAxisExtent', (WidgetTester tester) async {
        final GlobalKey key = GlobalKey();
        final List<Widget> slivers = <Widget>[
          SliverFixedExtentList(
            itemExtent: 150,
            delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => Container(color: Colors.amber),
              childCount: 5,
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              key: key,
              color: Colors.blue[300],
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: ElevatedButton(
                    child: const Text('center button'),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        ];
        await tester.pumpWidget(boilerplate(slivers));
        await tester.drag(find.byType(Scrollable), const Offset(0.0, -750.0));
        await tester.pump();
        expect(
          tester.renderObject<RenderBox>(find.byKey(key)).size.height,
          equals(148.0),
        );

        // Also check that the button alignment is true to expectations
        final Finder button = find.byType(ElevatedButton);
        expect(tester.getBottomLeft(button).dy, equals(550.0));
        expect(tester.getCenter(button).dx, equals(400.0));
      });

      testWidgets('alignment with a flexible works', (WidgetTester tester) async {
        final GlobalKey key = GlobalKey();
        final List<Widget> slivers = <Widget>[
          sliverBox,
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              key: key,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Flexible(
                  child: Center(child: FlutterLogo(size: 100)),
                  fit: FlexFit.loose,
                ),
                ElevatedButton(
                  child: const Text('Bottom'),
                  onPressed: () {},
                ),
              ]
            ),
          ),
        ];

        await tester.pumpWidget(boilerplate(slivers));
        expect(
          tester.renderObject<RenderBox>(find.byKey(key)).size.height,
          equals(450),
        );

        // Check that the logo alignment is true to expectations
        final Finder logo = find.byType(FlutterLogo);
        expect(
          tester.renderObject<RenderBox>(logo).size,
          const Size(100.0, 100.0),
        );
        expect(tester.getCenter(logo), const Offset(400.0, 351.0));

        // Also check that the button alignment is true to expectations
        final Finder button = find.byType(ElevatedButton);
        expect(
          tester.renderObject<RenderBox>(button).size,
          const Size(116.0, 48.0),
        );
        expect(tester.getBottomLeft(button).dy, equals(600.0));
        expect(tester.getCenter(button).dx, equals(400.0));

        // Overscroll and see that alignment and size is maintained
        await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
        await tester.pump();
        expect(
          tester.renderObject<RenderBox>(find.byKey(key)).size.height,
          equals(450),
        );
        expect(
          tester.renderObject<RenderBox>(logo).size,
          const Size(100.0, 100.0),
        );
        expect(tester.getCenter(logo).dy, lessThan(351.0));
        expect(
          tester.renderObject<RenderBox>(button).size,
          const Size(116.0, 48.0),
        );
        expect(tester.getBottomLeft(button).dy, lessThan(600.0));
        expect(tester.getCenter(button).dx, equals(400.0));
      }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS, TargetPlatform.macOS }));

      group('fillOverscroll: true, relevant platforms', () {
        testWidgets('child without size is sized by extent and overscroll', (WidgetTester tester) async {
          final List<Widget> slivers = <Widget>[
            sliverBox,
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: Container(color: Colors.blue),
            ),
          ];

          // Check size
          await tester.pumpWidget(boilerplate(slivers));
          final RenderBox box1 = tester.renderObject<RenderBox>(find.byType(Container).last);
          expect(box1.size.height, equals(450));

          // Overscroll and check size
          await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
          await tester.pump();
          final RenderBox box2 = tester.renderObject<RenderBox>(find.byType(Container).last);
          expect(box2.size.height, greaterThan(450));

          // Ensure overscroll retracts to original size after releasing gesture
          await tester.pumpAndSettle();
          final RenderBox box3 = tester.renderObject<RenderBox>(find.byType(Container).last);
          expect(box3.size.height, equals(450));
    }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

        testWidgets('child with smaller size is overridden and sized by extent and overscroll', (WidgetTester tester) async {
          final GlobalKey key = GlobalKey();
          final List<Widget> slivers = <Widget>[
            sliverBox,
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: Container(
                key: key,
                color: Colors.blue,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ElevatedButton(
                    child: const Text('bottomCenter button'),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ];
          await tester.pumpWidget(boilerplate(slivers));
          expect(
            tester.renderObject<RenderBox>(find.byKey(key)).size.height,
            equals(450),
          );

          await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
          await tester.pump();
          expect(
            tester.renderObject<RenderBox>(find.byKey(key)).size.height,
            greaterThan(450),
          );

          // Also check that the button alignment is true to expectations, even with
          // child stretching to fill overscroll
          final Finder button = find.byType(ElevatedButton);
          expect(tester.getBottomLeft(button).dy, equals(600.0));
          expect(tester.getCenter(button).dx, equals(400.0));

          // Ensure overscroll retracts to original size after releasing gesture
          await tester.pumpAndSettle();
          expect(
            tester.renderObject<RenderBox>(find.byKey(key)).size.height,
            equals(450),
          );
        }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

        testWidgets('extent is overridden by child size and overscroll if precedingScrollExtent > viewportMainAxisExtent', (WidgetTester tester) async {
          final GlobalKey key = GlobalKey();
          final ScrollController controller = ScrollController();
          final List<Widget> slivers = <Widget>[
            SliverFixedExtentList(
              itemExtent: 150,
              delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) =>
                  Container(color: Colors.amber),
                childCount: 5,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: Container(
                key: key,
                color: Colors.blue[300],
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: ElevatedButton(
                      child: const Text('center button'),
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ),
          ];
          await tester.pumpWidget(boilerplate(slivers, controller: controller));

          // Scroll to the end
          controller.jumpTo(controller.position.maxScrollExtent);
          await tester.pump();
          expect(
            tester.renderObject<RenderBox>(find.byKey(key)).size.height,
            equals(148.0),
          );
          // Check that the button alignment is true to expectations
          final Finder button = find.byType(ElevatedButton);
          expect(tester.getBottomLeft(button).dy, equals(550.0));
          expect(tester.getCenter(button).dx, equals(400.0));

          // Drag for overscroll
          await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
          await tester.pump();
          expect(
            tester.renderObject<RenderBox>(find.byKey(key)).size.height,
            greaterThan(148.0),
          );

          // Check that the button alignment is still centered in stretched child
          expect(tester.getBottomLeft(button).dy, lessThan(550.0));
          expect(tester.getCenter(button).dx, equals(400.0));

          // Ensure overscroll retracts to original size after releasing gesture
          await tester.pumpAndSettle();
          expect(
            tester.renderObject<RenderBox>(find.byKey(key)).size.height,
            equals(148.0),
          );
        }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

        testWidgets('fillOverscroll works when child has no size and precedingScrollExtent > viewportMainAxisExtent', (WidgetTester tester) async {
          final GlobalKey key = GlobalKey();
          final ScrollController controller = ScrollController();
          final List<Widget> slivers = <Widget>[
            SliverFixedExtentList(
              itemExtent: 150,
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Semantics(label: index.toString(), child: Container(color: Colors.amber));
                },
                childCount: 5,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: Container(
                key: key,
                color: Colors.blue,
              ),
            ),
          ];

          await tester.pumpWidget(boilerplate(slivers, controller: controller));

          expect(find.byKey(key), findsNothing);
          expect(
            find.bySemanticsLabel('4'),
            findsNothing,
          );

          // Scroll to bottom
          controller.jumpTo(controller.position.maxScrollExtent);
          await tester.pump();

          // Check item at the end of the list
          expect(find.byKey(key), findsNothing);
          expect(
            find.bySemanticsLabel('4'),
            findsOneWidget,
          );

          // Overscroll
          await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
          await tester.pump();

          // Check for new item at the end of the now overscrolled list
          expect(find.byKey(key), findsOneWidget);
          expect(
            find.bySemanticsLabel('4'),
            findsOneWidget,
          );

          // Ensure overscroll retracts to original size after releasing gesture
          await tester.pumpAndSettle();
          expect(find.byKey(key), findsNothing);
          expect(
            find.bySemanticsLabel('4'),
            findsOneWidget,
          );
        }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

        testWidgets('alignment with a flexible works with fillOverscroll', (WidgetTester tester) async {
          final GlobalKey key = GlobalKey();
          final List<Widget> slivers = <Widget>[
            sliverBox,
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: Column(
                key: key,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Flexible(
                    child: Center(child: FlutterLogo(size: 100)),
                    fit: FlexFit.loose,
                  ),
                  ElevatedButton(
                    child: const Text('Bottom'),
                    onPressed: () {},
                  ),
                ]
              ),
            ),
          ];

          await tester.pumpWidget(boilerplate(slivers));
          expect(
            tester.renderObject<RenderBox>(find.byKey(key)).size.height,
            equals(450),
          );

          // Check that the logo alignment is true to expectations.
          final Finder logo = find.byType(FlutterLogo);
          expect(
            tester.renderObject<RenderBox>(logo).size,
            const Size(100.0, 100.0),
          );
          expect(tester.getCenter(logo), const Offset(400.0, 351.0));

          // Also check that the button alignment is true to expectations.
          final Finder button = find.byType(ElevatedButton);
          expect(
            tester.renderObject<RenderBox>(button).size,
            const Size(116.0, 48.0),
          );
          expect(tester.getBottomLeft(button).dy, equals(600.0));
          expect(tester.getCenter(button).dx, equals(400.0));

          // Overscroll and see that logo alignment shifts to maintain center as
          // container stretches with overscroll, button remains aligned at the
          // bottom.
          await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
          await tester.pump();
          expect(
            tester.renderObject<RenderBox>(find.byKey(key)).size.height,
            greaterThan(450),
          );
          expect(
            tester.renderObject<RenderBox>(logo).size,
            const Size(100.0, 100.0),
          );
          expect(tester.getCenter(logo).dy, lessThan(351.0));
          expect(
            tester.renderObject<RenderBox>(button).size,
            const Size(116.0, 48.0),
          );
          expect(tester.getBottomLeft(button).dy, equals(600.0));
          expect(tester.getCenter(button).dx, equals(400.0));

          // Ensure overscroll retracts to original position when gesture is
          // released.
          await tester.pumpAndSettle();
          expect(
            tester.renderObject<RenderBox>(find.byKey(key)).size.height,
            equals(450),
          );
          expect(
            tester.renderObject<RenderBox>(logo).size,
            const Size(100.0, 100.0),
          );
          expect(tester.getCenter(logo), const Offset(400.0, 351.0));
          expect(
            tester.renderObject<RenderBox>(button).size,
            const Size(116.0, 48.0),
          );
          expect(tester.getBottomLeft(button).dy, equals(600.0));
          expect(tester.getCenter(button).dx, equals(400.0));
        }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));
      });

      group('fillOverscroll: true, is ignored on irrelevant platforms', () {
        // Android/Other scroll physics when hasScrollBody: false, ignores fillOverscroll: true
        testWidgets('child without size is sized by extent', (WidgetTester tester) async {
          final List<Widget> slivers = <Widget>[
            sliverBox,
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: Container(color: Colors.blue),
            ),
          ];
          await tester.pumpWidget(boilerplate(slivers));
          final RenderBox box1 = tester.renderObject<RenderBox>(find.byType(Container).last);
          expect(box1.size.height, equals(450));

          await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
          await tester.pump();
          final RenderBox box2 = tester.renderObject<RenderBox>(find.byType(Container).last);
          expect(box2.size.height, equals(450));
        });

        testWidgets('child with size is overridden and sized by extent', (WidgetTester tester) async {
          final GlobalKey key = GlobalKey();
          final List<Widget> slivers = <Widget>[
            sliverBox,
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: Container(
                key: key,
                color: Colors.blue,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ElevatedButton(
                    child: const Text('bottomCenter button'),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ];
          await tester.pumpWidget(boilerplate(slivers));
          expect(
            tester.renderObject<RenderBox>(find.byKey(key)).size.height,
            equals(450),
          );

          await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
          await tester.pump();
          expect(
            tester.renderObject<RenderBox>(find.byKey(key)).size.height,
            equals(450),
          );

          // Also check that the button alignment is true to expectations
          final Finder button = find.byType(ElevatedButton);
          expect(tester.getBottomLeft(button).dy, equals(600.0));
          expect(tester.getCenter(button).dx, equals(400.0));
        });

        testWidgets('extent is overridden by child size if precedingScrollExtent > viewportMainAxisExtent', (WidgetTester tester) async {
          final GlobalKey key = GlobalKey();
          final ScrollController controller = ScrollController();
          final List<Widget> slivers = <Widget>[
            SliverFixedExtentList(
              itemExtent: 150,
              delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) =>
                  Container(color: Colors.amber),
                childCount: 5,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: Container(
                key: key,
                color: Colors.blue[300],
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: ElevatedButton(
                      child: const Text('center button'),
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ),
          ];
          await tester.pumpWidget(boilerplate(slivers, controller: controller));

          // Scroll to the end
          controller.jumpTo(controller.position.maxScrollExtent);
          await tester.pump();
          expect(
            tester.renderObject<RenderBox>(find.byKey(key)).size.height,
            equals(148.0),
          );

          // Check that the button alignment is true to expectations
          final Finder button = find.byType(ElevatedButton);
          expect(tester.getBottomLeft(button).dy, equals(550.0));
          expect(tester.getCenter(button).dx, equals(400.0));

          await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
          await tester.pump();
          expect(
            tester.renderObject<RenderBox>(find.byKey(key)).size.height,
            equals(148.0),
          );

          // Check that the button alignment is still centered
          expect(tester.getBottomLeft(button).dy, equals(550.0));
          expect(tester.getCenter(button).dx, equals(400.0));
        });

        testWidgets('child has no size and precedingScrollExtent > viewportMainAxisExtent', (WidgetTester tester) async {
          final GlobalKey key = GlobalKey();
          final ScrollController controller = ScrollController();
          final List<Widget> slivers = <Widget>[
            SliverFixedExtentList(
              itemExtent: 150,
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Semantics(label: index.toString(), child: Container(color: Colors.amber));
                },
                childCount: 5,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              fillOverscroll: true,
              child: Container(
                key: key,
                color: Colors.blue,
              ),
            ),
          ];

          await tester.pumpWidget(boilerplate(slivers, controller: controller));

          expect(find.byKey(key), findsNothing);
          expect(
            find.bySemanticsLabel('4'),
            findsNothing,
          );

          // Scroll to bottom
          controller.jumpTo(controller.position.maxScrollExtent);
          await tester.pump();

          // End of list
          expect(find.byKey(key), findsNothing);
          expect(
            find.bySemanticsLabel('4'),
            findsOneWidget,
          );

          // Overscroll
          await tester.drag(find.byType(Scrollable), const Offset(0.0, -50.0));
          await tester.pump();

          expect(find.byKey(key), findsNothing);
          expect(
            find.bySemanticsLabel('4'),
            findsOneWidget,
          );
        });
      });
    });
  });
}
