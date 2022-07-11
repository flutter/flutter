// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//   This file is run as part of a reduced test set in CI on Mac and Windows
//   machines.
@Tags(<String>['reduced-test-set'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SliverDecoration creates, paints, and disposes BoxPainter', (WidgetTester tester) async {
    final TestDecoration decoration = TestDecoration();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: <Widget>[
            SliverDecoration(
              decoration: decoration,
              sliver: const SliverToBoxAdapter(
                child: SizedBox(width: 100, height: 100),
              ),
            )
          ],
        )
      )
    ));

    expect(decoration.painters, hasLength(1));
    expect(decoration.painters.last.lastConfiguration!.size, const Size(800, 100));
    expect(decoration.painters.last.lastOffset, Offset.zero);
    expect(decoration.painters.last.disposed, false);

    await tester.pumpWidget(const SizedBox());

    expect(decoration.painters, hasLength(1));
    expect(decoration.painters.last.disposed, true);
  });

  testWidgets('SliverDecoration can update box painter', (WidgetTester tester) async {
    final TestDecoration decorationA = TestDecoration();
    final TestDecoration decorationB = TestDecoration();

    Decoration activateDecoration = decorationA;
    late void Function(void Function()) localSetState;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder:(BuildContext context, void Function(void Function()) setState) {
            localSetState = setState;
            return CustomScrollView(
              slivers: <Widget>[
                SliverDecoration(
                  decoration: activateDecoration,
                  sliver: const SliverToBoxAdapter(
                    child: SizedBox(width: 100, height: 100),
                  ),
                )
              ],
            );
          },
        )
      )
    ));

    expect(decorationA.painters, hasLength(1));
    expect(decorationA.painters.last.paintCount, 1);
    expect(decorationB.painters, hasLength(0));

    localSetState(() {
      activateDecoration = decorationB;
    });
    await tester.pump();

    expect(decorationA.painters, hasLength(1));
    expect(decorationB.painters, hasLength(1));
    expect(decorationB.painters.last.paintCount, 1);
  });

  testWidgets('SliverDecoration can update DecorationPosition', (WidgetTester tester) async {
    final TestDecoration decoration = TestDecoration();

    DecorationPosition activePosition = DecorationPosition.foreground;
    late void Function(void Function()) localSetState;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder:(BuildContext context, void Function(void Function()) setState) {
            localSetState = setState;
            return CustomScrollView(
              slivers: <Widget>[
                SliverDecoration(
                  decoration: decoration,
                  position: activePosition,
                  sliver: const SliverToBoxAdapter(
                    child: SizedBox(width: 100, height: 100),
                  ),
                )
              ],
            );
          },
        )
      )
    ));

    expect(decoration.painters, hasLength(1));
    expect(decoration.painters.last.paintCount, 1);

    localSetState(() {
      activePosition = DecorationPosition.background;
    });
    await tester.pump();

    expect(decoration.painters, hasLength(1));
    expect(decoration.painters.last.paintCount, 2);
  });

  testWidgets('SliverDecoration golden test', (WidgetTester tester) async {
    const BoxDecoration decoration = BoxDecoration(
      color: Colors.blue,
    );

    final Key backgroundKey = UniqueKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RepaintBoundary(
          key: backgroundKey,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverDecoration(
                decoration: decoration,
                sliver: SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed(<Widget>[
                      Container(
                        height: 100,
                        color: Colors.red,
                      ),
                      Container(
                        height: 100,
                        color: Colors.yellow,
                      ),
                      Container(
                        height: 100,
                        color: Colors.red,
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    ));

    await expectLater(find.byKey(backgroundKey), matchesGoldenFile('decorated_sliver.moon.background.png'));

    final Key foregroundKey = UniqueKey();
     await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RepaintBoundary(
          key: foregroundKey,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverDecoration(
                decoration: decoration,
                position: DecorationPosition.foreground,
                sliver: SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed(<Widget>[
                      Container(
                        height: 100,
                        color: Colors.red,
                      ),
                      Container(
                        height: 100,
                        color: Colors.yellow,
                      ),
                      Container(
                        height: 100,
                        color: Colors.red,
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    ));

    await expectLater(find.byKey(foregroundKey), matchesGoldenFile('decorated_sliver.moon.foreground.png'));
  });
}

class TestDecoration extends Decoration {
  final List<TestBoxPainter> painters = <TestBoxPainter>[];

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    final TestBoxPainter painter = TestBoxPainter();
    painters.add(painter);
    return painter;
  }
}

class TestBoxPainter extends BoxPainter {
  Offset? lastOffset;
  ImageConfiguration? lastConfiguration;
  bool disposed = false;
  int paintCount = 0;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    lastOffset = offset;
    lastConfiguration = configuration;
    paintCount += 1;
  }

  @override
  void dispose() {
    assert(!disposed);
    disposed = true;
    super.dispose();
  }
}
