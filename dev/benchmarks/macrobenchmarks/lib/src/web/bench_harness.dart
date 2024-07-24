// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'recorder.dart';

class BenchWidgetRecorder extends WidgetRecorder {
  BenchWidgetRecorder() : super(name: benchmarkName);

  static const String benchmarkName = 'bench_widget_recorder';

  @override
  Widget createWidget() {
    // This is intentionally using a simple widget. The benchmark is meant to
    // measure the overhead of the harness, so this method should induce as
    // little work as possible.
    return const SizedBox.expand();
  }
}

class BenchWidgetBuildRecorder extends WidgetBuildRecorder {
  BenchWidgetBuildRecorder() : super(name: benchmarkName);

  static const String benchmarkName = 'bench_widget_build_recorder';

  @override
  Widget createWidget() {
    // This is intentionally using a simple widget. The benchmark is meant to
    // measure the overhead of the harness, so this method should induce as
    // little work as possible.
    return const SizedBox.expand();
  }
}

class BenchRawRecorder extends RawRecorder {
  BenchRawRecorder() : super(name: benchmarkName);

  static const String benchmarkName = 'bench_raw_recorder';

  @override
  void body(Profile profile) {
    profile.record('profile.record', () {
      // This is intentionally empty. The benchmark only measures the overhead
      // of the harness.
    }, reported: true);
  }
}

class BenchSceneBuilderRecorder extends SceneBuilderRecorder {
  BenchSceneBuilderRecorder() : super(name: benchmarkName);

  static const String benchmarkName = 'bench_scene_builder_recorder';

  @override
  void onDrawFrame(ui.SceneBuilder sceneBuilder) {
    // This is intentionally empty. The benchmark only measures the overhead
    // of the harness.
  }
}
