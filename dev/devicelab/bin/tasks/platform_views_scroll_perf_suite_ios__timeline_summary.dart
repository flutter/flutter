// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/tasks/perf_tests.dart';

/// Keys are the former task names, which keeps their Skia Perf history.
/// No cooldown: each is a minute of light scrolling with a rebuild between.
Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(
    runBenchmarks(<String, TaskFunction>{
      'platform_views_scroll_perf_ad_banners__timeline_summary':
          createUiKitViewScrollPerfAdBannersTest(enableImpeller: true),
      'platform_views_scroll_perf_bottom_ad_banner__timeline_summary':
          createUiKitViewScrollPerfBottomAdBannerTest(enableImpeller: true),
      'platform_views_scroll_perf_non_intersecting_impeller_ios__timeline_summary':
          createUiKitViewScrollPerfNonIntersectingTest(enableImpeller: true),
    }),
  );
}
