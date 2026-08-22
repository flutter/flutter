// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  test('TwoDimensionalChildBuilderDelegate dispatches memory events', () async {
    await expectLater(
      await memoryEvents(
        () => TwoDimensionalChildBuilderDelegate(builder: (_, _) => null).dispose(),
        TwoDimensionalChildBuilderDelegate,
      ),
      areCreateAndDispose,
    );
  });

  test('SliverChildListDelegate.shouldRebuild returns true when flags change', () {
    final List<Widget> children = <Widget>[const SizedBox()];
    final SliverChildListDelegate delegate1 = SliverChildListDelegate(children, addRepaintBoundaries: true);
    final SliverChildListDelegate delegate2 = SliverChildListDelegate(children, addRepaintBoundaries: false);
    final SliverChildListDelegate delegate3 = SliverChildListDelegate(children, addAutomaticKeepAlives: false);
    final SliverChildListDelegate delegate4 = SliverChildListDelegate(children, addSemanticIndexes: false);
    final SliverChildListDelegate delegate5 = SliverChildListDelegate(children);

    expect(delegate1.shouldRebuild(delegate5), false);
    expect(delegate1.shouldRebuild(delegate2), true);
    expect(delegate1.shouldRebuild(delegate3), true);
    expect(delegate1.shouldRebuild(delegate4), true);
  });
}
