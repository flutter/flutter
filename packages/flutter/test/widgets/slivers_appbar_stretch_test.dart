// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('SliverAppBar - Stretch', () {
    testWidgets('fills overscroll', (WidgetTester tester) async {
      const Key anchor = Key('drag');
      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              const SliverAppBar(
                stretch: true,
                expandedHeight: 100.0,
              ),
              SliverToBoxAdapter(
                child: Container(
                  key: anchor,
                  height: 800,
                )
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 800,
                )
              ),
            ],
          ),
        ),
      );

      final RenderSliverScrollingPersistentHeader header = tester.renderObject(
        find.byType(SliverAppBar)
      );
      expect(header.child.size.height, equals(100.0));
      await slowDrag(tester, anchor, const Offset(0.0, 100));
      expect(header.child.size.height, equals(200.0));
    });

    testWidgets('does not stretch without overscroll physics', (WidgetTester tester) async {
      const Key anchor = Key('drag');
      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: <Widget>[
              const SliverAppBar(
                stretch: true,
                expandedHeight: 100.0,
              ),
              SliverToBoxAdapter(
                child: Container(
                  key: anchor,
                  height: 800,
                )
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 800,
                )
              ),
            ],
          ),
        ),
      );

      final RenderSliverScrollingPersistentHeader header = tester.renderObject(
        find.byType(SliverAppBar)
      );
      expect(header.child.size.height, equals(100.0));
      await slowDrag(tester, anchor, const Offset(0.0, 100.0));
      expect(header.child.size.height, equals(100.0));
    });

    testWidgets('default trigger offset', (WidgetTester tester) async {
      bool didTrigger = false;
      const Key anchor = Key('drag');
      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverAppBar(
                stretch: true,
                expandedHeight: 100.0,
                onStretchTrigger: () {
                  didTrigger = true;
                  return;
                },
              ),
              SliverToBoxAdapter(
                child: Container(
                  key: anchor,
                  height: 800,
                )
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 800,
                )
              ),
            ],
          ),
        ),
      );

      await slowDrag(tester, anchor, const Offset(0.0, 50.0));
      expect(didTrigger, isFalse);
      await tester.pumpAndSettle();
      await slowDrag(tester, anchor, const Offset(0.0, 150.0));
      expect(didTrigger, isTrue);
    });

    testWidgets('custom trigger offset', (WidgetTester tester) async {
      bool didTrigger = false;
      const Key anchor = Key('drag');
      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverAppBar(
                stretch: true,
                expandedHeight: 100.0,
                stretchTriggerOffset: 150.0,
                onStretchTrigger: () {
                  didTrigger = true;
                  return;
                },
              ),
              SliverToBoxAdapter(
                child: Container(
                  key: anchor,
                  height: 800,
                )
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 800,
                )
              ),
            ],
          ),
        ),
      );

      await slowDrag(tester, anchor, const Offset(0.0, 100.0));
      await tester.pumpAndSettle();
      expect(didTrigger, isFalse);
      await slowDrag(tester, anchor, const Offset(0.0, 300.0));
      expect(didTrigger, isTrue);
    });

    testWidgets('stretch callback not triggered without overscroll physics', (WidgetTester tester) async {
      bool didTrigger = false;
      const Key anchor = Key('drag');
      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: <Widget>[
              SliverAppBar(
                stretch: true,
                expandedHeight: 100.0,
                stretchTriggerOffset: 150.0,
                onStretchTrigger: () {
                  didTrigger = true;
                  return;
                },
              ),
              SliverToBoxAdapter(
                child: Container(
                  key: anchor,
                  height: 800,
                )
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 800,
                )
              ),
            ],
          ),
        ),
      );

      await slowDrag(tester, anchor, const Offset(0.0, 100.0));
      await tester.pumpAndSettle();
      expect(didTrigger, isFalse);
      await slowDrag(tester, anchor, const Offset(0.0, 300.0));
      expect(didTrigger, isFalse);
    });

    testWidgets('asserts stretch != null', (WidgetTester tester) async {
      expect(
        () {
          return MaterialApp(
            home: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: <Widget>[
                SliverAppBar(
                  stretch: null,
                  expandedHeight: 100.0,
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: 800,
                  )
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: 800,
                  )
                ),
              ],
            ),
          );
        },
        throwsAssertionError,
      );
    });

    testWidgets('asserts reasonable trigger offset', (WidgetTester tester) async {
      expect(
        () {
          return MaterialApp(
            home: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: <Widget>[
                SliverAppBar(
                  stretch: true,
                  expandedHeight: 100.0,
                  stretchTriggerOffset: -150.0,
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: 800,
                  )
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: 800,
                  )
                ),
              ],
            ),
          );
        },
        throwsAssertionError,
      );
    });
  });

  group('SliverAppBar - Stretch, Pinned', () {
    testWidgets('fills overscroll', (WidgetTester tester) async {
      const Key anchor = Key('drag');
      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              const SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: 100.0,
              ),
              SliverToBoxAdapter(
                child: Container(
                  key: anchor,
                  height: 800,
                )
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 800,
                )
              ),
            ],
          ),
        ),
      );
      final RenderSliverPinnedPersistentHeader header = tester.renderObject(
        find.byType(SliverAppBar)
      );
      expect(header.child.size.height, equals(100.0));
      await slowDrag(tester, anchor, const Offset(0.0, 100));
      expect(header.child.size.height, equals(200.0));
    });

    testWidgets('does not stretch without overscroll physics', (WidgetTester tester) async {
      const Key anchor = Key('drag');
      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: <Widget>[
              const SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: 100.0,
              ),
              SliverToBoxAdapter(
                child: Container(
                  key: anchor,
                  height: 800,
                )
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 800,
                )
              ),
            ],
          ),
        ),
      );
      final RenderSliverPinnedPersistentHeader header = tester.renderObject(
        find.byType(SliverAppBar)
      );
      expect(header.child.size.height, equals(100.0));
      await slowDrag(tester, anchor, const Offset(0.0, 100));
      expect(header.child.size.height, equals(100.0));
    });
  });

  group('SliverAppBar - Stretch, Floating', () {
    testWidgets('fills overscroll', (WidgetTester tester) async {
      const Key anchor = Key('drag');
      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              const SliverAppBar(
                floating: true,
                stretch: true,
                expandedHeight: 100.0,
              ),
              SliverToBoxAdapter(
                child: Container(
                  key: anchor,
                  height: 800,
                )
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 800,
                )
              ),
            ],
          ),
        ),
      );
      final RenderSliverFloatingPersistentHeader header = tester.renderObject(
        find.byType(SliverAppBar)
      );
      expect(header.child.size.height, equals(100.0));
      await slowDrag(tester, anchor, const Offset(0.0, 100));
      expect(header.child.size.height, equals(200.0));
    });

    testWidgets('does not fill overscroll without proper physics', (WidgetTester tester) async {
      const Key anchor = Key('drag');
      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: <Widget>[
              const SliverAppBar(
                floating: true,
                stretch: true,
                expandedHeight: 100.0,
              ),
              SliverToBoxAdapter(
                child: Container(
                  key: anchor,
                  height: 800,
                )
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 800,
                )
              ),
            ],
          ),
        ),
      );
      final RenderSliverFloatingPersistentHeader header = tester.renderObject(
        find.byType(SliverAppBar)
      );
      expect(header.child.size.height, equals(100.0));
      await slowDrag(tester, anchor, const Offset(0.0, 100));
      expect(header.child.size.height, equals(100.0));
    });
  });

  group('SliverAppBar - Stretch, Floating, Pinned', () {
    testWidgets('fills overscroll', (WidgetTester tester) async {
      const Key anchor = Key('drag');
      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              const SliverAppBar(
                floating: true,
                pinned: true,
                stretch: true,
                expandedHeight: 100.0,
              ),
              SliverToBoxAdapter(
                child: Container(
                  key: anchor,
                  height: 800,
                )
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 800,
                )
              ),
            ],
          ),
        ),
      );
      final RenderSliverFloatingPinnedPersistentHeader header = tester.renderObject(
        find.byType(SliverAppBar)
      );
      expect(header.child.size.height, equals(100.0));
      await slowDrag(tester, anchor, const Offset(0.0, 100));
      expect(header.child.size.height, equals(200.0));
    });

    testWidgets('does not fill overscroll without proper physics', (WidgetTester tester) async {
      const Key anchor = Key('drag');
      await tester.pumpWidget(
        MaterialApp(
          home: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: <Widget>[
              const SliverAppBar(
                pinned: true,
                floating: true,
                stretch: true,
                expandedHeight: 100.0,
              ),
              SliverToBoxAdapter(
                child: Container(
                  key: anchor,
                  height: 800,
                )
              ),
              SliverToBoxAdapter(
                child: Container(
                  height: 800,
                )
              ),
            ],
          ),
        ),
      );
      final RenderSliverFloatingPinnedPersistentHeader header = tester.renderObject(
        find.byType(SliverAppBar)
      );
      expect(header.child.size.height, equals(100.0));
      await slowDrag(tester, anchor, const Offset(0.0, 100));
      expect(header.child.size.height, equals(100.0));
    });
  });
}

Future<void> slowDrag(WidgetTester tester, Key widget, Offset offset) async {
  final Offset target = tester.getCenter(find.byKey(widget));
  final TestGesture gesture = await tester.startGesture(target);
  await gesture.moveBy(offset);
  await tester.pump(const Duration(milliseconds: 10));
  await gesture.up();
}
