// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Options for the adaptive behavior of [AdaptiveWidget].
enum AdaptiveMode {
  /// Always adapt the widget to the current [TargetPlatform].
  adaptive,
  /// Never adapt the widget to the current [TargetPlatform]. Always return
  /// the Material Design widget.
  static,
  /// Adapt the widget to the current [TargetPlatform] if the widget type is
  /// enabled in [ThemeData.adaptiveWidgetTheme].
  theme,
}

/// A [StatelessWidget] that can build different widgets according to the
/// current platform environment depending on the [adaptiveMode].
abstract class AdaptiveWidget extends StatelessWidget {
  const AdaptiveWidget({
    Key key,
    this.adaptiveMode: AdaptiveMode.theme,
  }) : super(key: key);

  final AdaptiveMode adaptiveMode;

  Widget buildMaterialWidget(BuildContext context);

  Widget buildCupertinoWidget(BuildContext context);

  @override
  Widget build(BuildContext context) {
    if (adaptiveMode == AdaptiveMode.static) {
      return buildMaterialWidget(context);
    }

    final ThemeData theme = Theme.of(context);

    if (!theme.adaptiveWidgetTheme.isWidgetAdaptive(runtimeType)) {
      return buildMaterialWidget(context);
    }

    switch (theme.platform) {
      case TargetPlatform.android:
        return buildMaterialWidget(context);
      case TargetPlatform.iOS:
        return buildCupertinoWidget(context);
      case TargetPlatform.fuchsia:
        return buildMaterialWidget(context);
    }
    assert(false);
    return null;
  }
}