// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show AccessibilityFeatures, window;

import 'package:flutter/foundation.dart';

export 'dart:ui' show AccessibilityFeatures;

/// The glue between the semantics layer and the Flutter engine.
// TODO(jonahwilliams): move the remaining semantic related bindings here.
class SemanticsBinding extends BindingBase {
  // This class is intended to be used as a mixin, and should not be
  // extended directly.
  factory SemanticsBinding._() => null;

  /// The current [SemanticsBinding], if one has been created.
  static SemanticsBinding get instance => _instance;
  static SemanticsBinding _instance;

  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    _accessibilityFeatures = new ValueNotifier<ui.AccessibilityFeatures>(ui.window.accessibilityFeatures);
  }

  /// Called when the platform accessibility features change.
  ///
  /// See [Window.onAccessibilityFeaturesChanged].
  @protected
  void handleAccessibilityFeaturesChanged() {
    _accessibilityFeatures.value = ui.window.accessibilityFeatures;
  }

  /// The currently active set of [AccessibilityFeatures].
  ///
  /// This is initialized the first time [runApp] is called and updated whenever
  /// a flag is changed.
  ///
  /// To listen to changes to accessibility features, create a
  /// [WidgetsBindingObserver] and listen to [didChangeAccessibilityFeatures].
  ValueListenable<ui.AccessibilityFeatures> get accessibilityFeatures => _accessibilityFeatures;
  ValueNotifier<ui.AccessibilityFeatures> _accessibilityFeatures;
}