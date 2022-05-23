// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show AccessibilityFeatures, SemanticsUpdateBuilder;

import 'package:flutter/foundation.dart';

import 'debug.dart';

export 'dart:ui' show AccessibilityFeatures;

/// The glue between the semantics layer and the Flutter engine.
// TODO(zanderso): move the remaining semantic related bindings here.
mixin SemanticsBinding on BindingBase {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    _accessibilityFeatures = platformDispatcher.accessibilityFeatures;
  }

  /// The current [SemanticsBinding], if one has been created.
  ///
  /// Provides access to the features exposed by this mixin. The binding must
  /// be initialized before using this getter; this is typically done by calling
  /// [runApp] or [WidgetsFlutterBinding.ensureInitialized].
  static SemanticsBinding get instance => BindingBase.checkInstance(_instance);
  static SemanticsBinding? _instance;

  /// Called when the platform accessibility features change.
  ///
  /// See [dart:ui.PlatformDispatcher.onAccessibilityFeaturesChanged].
  @protected
  void handleAccessibilityFeaturesChanged() {
    _accessibilityFeatures = platformDispatcher.accessibilityFeatures;
  }

  /// Creates an empty semantics update builder.
  ///
  /// The caller is responsible for filling out the semantics node updates.
  ///
  /// This method is used by the [SemanticsOwner] to create builder for all its
  /// semantics updates.
  ui.SemanticsUpdateBuilder createSemanticsUpdateBuilder() {
    return ui.SemanticsUpdateBuilder();
  }

  /// The currently active set of [AccessibilityFeatures].
  ///
  /// This is initialized the first time [runApp] is called and updated whenever
  /// a flag is changed.
  ///
  /// To listen to changes to accessibility features, create a
  /// [WidgetsBindingObserver] and listen to
  /// [WidgetsBindingObserver.didChangeAccessibilityFeatures].
  ui.AccessibilityFeatures get accessibilityFeatures => _accessibilityFeatures;
  late ui.AccessibilityFeatures _accessibilityFeatures;

  /// The platform is requesting that animations be disabled or simplified.
  ///
  /// This setting can be overridden for testing or debugging by setting
  /// [debugSemanticsDisableAnimations].
  bool get disableAnimations {
    bool value = _accessibilityFeatures.disableAnimations;
    assert(() {
      if (debugSemanticsDisableAnimations != null)
        value = debugSemanticsDisableAnimations!;
      return true;
    }());
    return value;
  }
}
