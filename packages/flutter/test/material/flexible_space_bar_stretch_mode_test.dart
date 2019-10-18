// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

final Key blockKey = UniqueKey();
const double expandedAppbarHeight = 250.0;
final Key appbarContainerKey = UniqueKey();

void main() {
  testWidgets('FlexibleSpaceBar stretch mode default zoomBackground', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            key: blockKey,
            slivers: <Widget>[
              SliverAppBar(
                expandedHeight: expandedAppbarHeight,
                pinned: true,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    key: appbarContainerKey,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: Container(height: 10000.0)),
            ],
          ),
        ),
      ),
    );

    final Finder appbarContainer = find.byKey(appbarContainerKey);
    final Size sizeBeforeScroll = tester.getSize(appbarContainer);
    await slowDrag(tester, blockKey, const Offset(0.0, 100.0));
    final Size sizeAfterScroll = tester.getSize(appbarContainer);

    expect(sizeBeforeScroll.height, lessThan(sizeAfterScroll.height));
  });

  testWidgets('FlexibleSpaceBar stretch mode blurBackground', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            key: blockKey,
            slivers: <Widget>[
              SliverAppBar(
                expandedHeight: expandedAppbarHeight,
                pinned: true,
                stretch: true,
                flexibleSpace: RepaintBoundary(
                  child: FlexibleSpaceBar(
                    stretchModes: const <StretchMode>[StretchMode.blurBackground],
                    background: Container(
                      child: Row(
                        children: <Widget>[
                          Expanded(child: Container(color: Colors.red)),
                          Expanded(child:Container(color: Colors.blue)),
                        ],
                      )
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: Container(height: 10000.0)),
            ],
          ),
        ),
      ),
    );

    await slowDrag(tester, blockKey, const Offset(0.0, 100.0));
    await expectLater(
      find.byType(FlexibleSpaceBar),
      matchesGoldenFile('flexible_space_bar_stretch_mode.blur_background.png'),
    );

  });
//
//  testWidgets('FlexibleSpaceBar stretch mode fadeTitle', (WidgetTester tester) async {
//    await tester.pumpWidget(
//      MaterialApp(
//        home: Scaffold(
//          body: CustomScrollView(
//            physics: const BouncingScrollPhysics(),
//            key: blockKey,
//            slivers: <Widget>[
//              SliverAppBar(
//                expandedHeight: expandedAppbarHeight,
//                pinned: true,
//                stretch: true,
//                flexibleSpace: FlexibleSpaceBar(
//                  stretchModes: const <StretchMode>[StretchMode.fadeTitle],
//                  background: Container(key: appbarContainerKey),
//                  title: const Text('Title'),
//                ),
//              ),
//              SliverToBoxAdapter(child: Container(height: 10000.0)),
//            ],
//          ),
//        ),
//      ),
//    );
//
////    final Finder appbarContainer = find.byKey(appbarContainerKey);
////    final Offset topBeforeScroll = tester.getTopLeft(appbarContainer);
////    await slowDrag(tester, blockKey, const Offset(0.0, -100.0));
////    final Offset topAfterScroll = tester.getTopLeft(appbarContainer);
////
////    expect(topBeforeScroll.dy, equals(0.0));
////    expect(topAfterScroll.dy, lessThan(10.0));
////    expect(topAfterScroll.dy, greaterThan(-50.0));
//  });
//
//  testWidgets('FlexibleSpaceBar stretch mode ignored for non-overscroll physics', (WidgetTester tester) async {
//    await tester.pumpWidget(
//      MaterialApp(
//        home: Scaffold(
//          body: CustomScrollView(
//            physics: const ClampingScrollPhysics(),
//            key: blockKey,
//            slivers: <Widget>[
//              SliverAppBar(
//                expandedHeight: expandedAppbarHeight,
//                stretch: true,
//                pinned: true,
//                flexibleSpace: FlexibleSpaceBar(
//                  stretchModes: const <StretchMode>[StretchMode.blurBackground],
//                  background: Container(
//                    key: appbarContainerKey,
//                  ),
//                ),
//              ),
//              SliverToBoxAdapter(child: Container(height: 10000.0)),
//            ],
//          ),
//        ),
//      ),
//    );
//
////    final Finder appbarContainer = find.byKey(appbarContainerKey);
////    final Offset topBeforeScroll = tester.getTopLeft(appbarContainer);
////    await slowDrag(tester, blockKey, const Offset(0.0, -100.0));
////    final Offset topAfterScroll = tester.getTopLeft(appbarContainer);
////
////    expect(topBeforeScroll.dy, equals(0.0));
////    expect(topAfterScroll.dy, lessThan(10.0));
////    expect(topAfterScroll.dy, greaterThan(-50.0));
//  });
}

Future<void> slowDrag(WidgetTester tester, Key widget, Offset offset) async {
  final Offset target = tester.getCenter(find.byKey(widget));
  final TestGesture gesture = await tester.startGesture(target);
  await gesture.moveBy(offset);
  await tester.pump(const Duration(milliseconds: 10));
  await gesture.up();
}
