// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:gallery/benchmarks/gallery_automator.dart';

import 'package:macrobenchmarks/src/web/recorder.dart';

/// A recorder that measures frame building durations for the Gallery.
class GalleryRecorder extends WidgetRecorder {
  GalleryRecorder({
    @required this.benchmarkName,
    this.shouldRunPredicate,
    this.testScrollsOnly = false,
  }) : assert(testScrollsOnly || shouldRunPredicate != null),
       super(name: benchmarkName, useCustomWarmUp: true);

  /// The name of the gallery benchmark to be run.
  final String benchmarkName;

  /// A function that accepts the name of a demo and returns whether we should
  /// run this demo in this benchmark.
  final bool Function(String) shouldRunPredicate;

  /// Whether this benchmark only tests scrolling.
  final bool testScrollsOnly;

  /// Whether we should continue recording.
  @override
  bool shouldContinue() => !_finished || profile.shouldContinue();

  GalleryAutomator _galleryAutomator;
  bool get _finished => _galleryAutomator?.finished ?? false;

  /// Creates the [GalleryAutomator] widget.
  @override
  Widget createWidget() {
    _galleryAutomator = GalleryAutomator(
      benchmarkName: benchmarkName,
      shouldRunPredicate: shouldRunPredicate,
      testScrollsOnly: testScrollsOnly,
      stopWarmingUpCallback: profile.stopWarmingUp,
    );
    return _galleryAutomator.createWidget();
  }
}
