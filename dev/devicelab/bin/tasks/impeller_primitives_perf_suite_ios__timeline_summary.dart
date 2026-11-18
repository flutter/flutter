// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/tasks/perf_tests.dart';

/// Keys are the former task names, which keeps their Skia Perf history.
Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(
    runBenchmarks(<String, TaskFunction>{
      'draw_points_perf_ios__timeline_summary': createDrawPointsPerfTest(),
      'draw_vertices_perf_ios__timeline_summary': createDrawVerticesPerfTest(),
      'draw_atlas_perf_ios__timeline_summary': createDrawAtlasPerfTest(),
      'draw_arcs_all_fill_styles_perf_ios__timeline_summary': createDrawArcsAllFillStylesPerfTest(),
      'draw_arcs_all_stroke_styles_perf_ios__timeline_summary':
          createDrawArcsAllStrokeStylesPerfTest(),
      'rrect_blur_perf_ios__timeline_summary': createRRectBlurPerfTest(enableImpeller: true),
      'static_path_tessellation_perf_ios__timeline_summary': createPathTessellationStaticPerfTest(),
      'dynamic_path_tessellation_perf_ios__timeline_summary':
          createPathTessellationDynamicPerfTest(),
      'static_path_stroke_tessellation_perf_ios__timeline_summary':
          createPathStrokeTessellationStaticPerfTest(),
      'dynamic_path_stroke_tessellation_perf_ios__timeline_summary':
          createPathStrokeTessellationDynamicPerfTest(),
    }),
  );
}
