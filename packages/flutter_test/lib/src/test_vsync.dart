// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';

/// A [TickerProvider] that creates a standalone ticker.
///
/// Useful in tests that create an [AnimationController] outside of the widget
/// tree.
class TestVSync implements TickerProvider {
  /// Creates a ticker provider that creates standalone tickers.
  const TestVSync({this.disableAnimations = false});

  /// Whether to disable the animations of tickers create from this picker.
  ///
  /// See also:
  ///
  ///   * [AccessibilityFeatures.disableAnimations], for the setting that controls this flag.
  ///   * [AnimationBehavior], for how animation controllers change when created from tickers with this flag.
  final bool disableAnimations;

  @override
  Ticker createTicker(TickerCallback onTick) => new Ticker(onTick)..disableAnimations = disableAnimations;
}
