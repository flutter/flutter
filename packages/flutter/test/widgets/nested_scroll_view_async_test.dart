// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:quiver/testing/async.dart';

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.resetEpoch();
  });

  test('NestedScrollView can build sccessfully if mark dirty during warm up frame', () {
    final FakeAsync fakeAsync = FakeAsync();
    fakeAsync.run((FakeAsync async) {
      runApp(
        MaterialApp(
          home: Material(
            child: DefaultTabController(
              length: 1,
              child: NestedScrollView(
                dragStartBehavior: DragStartBehavior.down,
                headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    const SliverPersistentHeader(
                      delegate: TestHeader(),
                    ),
                  ];
                },
                body: SingleChildScrollView(
                  dragStartBehavior: DragStartBehavior.down,
                  child: Container(
                    height: 1000.0,
                    child: const Placeholder(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // Marks element as dirty right before the first draw frame is called.
      // This can happen when engine flush user setting.
      final Element element = find.byType(NestedScrollView, skipOffstage: false).evaluate().single;
      element.markNeedsBuild();
      // Triggers draw frame timer scheduled in scheduleWarmUpFrame.
      fakeAsync.flushTimers();
    });
    // Make sure widget is rebuilt correctly.
    expect(
      find.byType(NestedScrollView, skipOffstage: false).evaluate().single.widget is NestedScrollView,
      isTrue
    );
  });
}

class TestHeader extends SliverPersistentHeaderDelegate {
  const TestHeader();
  @override
  double get minExtent => 100.0;
  @override
  double get maxExtent => 100.0;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return const Placeholder();
  }
  @override
  bool shouldRebuild(TestHeader oldDelegate) => false;
}
