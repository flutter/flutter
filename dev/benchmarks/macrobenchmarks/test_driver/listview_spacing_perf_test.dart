// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:macrobenchmarks/common.dart';

import 'util.dart';

Future<void> _scrollList(FlutterDriver driver) async {
  final SerializableFinder scrollable = find.byValueKey(kListViewSpacingScrollableKey);
  for (var i = 0; i < 20; i++) {
    await driver.scroll(scrollable, 0, -600, const Duration(milliseconds: 250));
  }
  await driver.tap(find.pageBack());
}

void main() {
  macroPerfTest(
    'listview_spacing_perf',
    kListViewSpacingRouteName,
    pageDelay: const Duration(seconds: 1),
    driverOps: _scrollList,
  );
  macroPerfTest(
    'listview_separated_perf',
    kListViewSeparatedRouteName,
    pageDelay: const Duration(seconds: 1),
    driverOps: _scrollList,
  );
  macroPerfTest(
    'listview_spacing_varied_extent_perf',
    kListViewSpacingVariedExtentRouteName,
    pageDelay: const Duration(seconds: 1),
    driverOps: _scrollList,
  );
  macroPerfTest(
    'listview_separated_varied_extent_perf',
    kListViewSeparatedVariedExtentRouteName,
    pageDelay: const Duration(seconds: 1),
    driverOps: _scrollList,
  );
}

