// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Builds different widgets according to the current platform environment.
///
/// When specified, [themeAdaptiveType] can be used to selectively adapt
/// to the platform only if an ancestor [Theme] specified the widget type
/// in [ThemeData.adaptiveWidgetTheme].
///
/// See also:
///
///  * [AdaptiveWidgetThemeData.bundled], for a list of Material Design widgets
///    that can adapt using Cupertino widgets on iOS.
class PlatformBuilder extends StatelessWidget {
  /// Create a [PlatformBuilder] that will call either [materialWidgetBuilder]
  /// or [cupertinoWidgetBuilder] depending on the running platform.
  ///
  /// The parameters [materialWidgetBuilder] and [cupertinoWidgetBuilder] must
  /// not be null.
  const PlatformBuilder({
    Key key,
    @required this.materialWidgetBuilder,
    @required this.cupertinoWidgetBuilder,
    this.themeAdaptiveType,
  }) : assert(materialWidgetBuilder != null),
       assert(cupertinoWidgetBuilder != null),
       super(key: key);

  /// A [WidgetBuilder] called when the [PlatformBuilder] should build for
  /// Android or Fuchsia or shouldn't adapt.
  final WidgetBuilder materialWidgetBuilder;

  /// A [WidgetBuilder] called when the [PlatformBuilder] should adapt using
  /// Cupertino widgets on iOS.
  final WidgetBuilder cupertinoWidgetBuilder;

  /// A [Type] that can be used to let this [PlatformBuilder] only adapt when
  /// that [Type] is specified in an ancestor [Theme] via
  /// [ThemeData.adaptiveWidgetTheme].
  final Type themeAdaptiveType;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (themeAdaptiveType != null
        && !theme.adaptiveWidgetTheme.isWidgetAdaptive(themeAdaptiveType)) {
      return materialWidgetBuilder(context);
    }

    switch (theme.platform) {
      case TargetPlatform.android:
        return materialWidgetBuilder(context);
      case TargetPlatform.iOS:
        return cupertinoWidgetBuilder(context);
      case TargetPlatform.fuchsia:
        return materialWidgetBuilder(context);
    }
    assert(false);
    return null;
  }
}