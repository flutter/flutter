// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'theme.dart';

/// A [StatelessWidget] that can build different widgets according to the
/// current platform environment depending on the [adaptiveMode].
class PlatformBuilder extends StatelessWidget {
  const PlatformBuilder({
    Key key,
    @required this.materialWidgetBuilder,
    @required this.cupertinoWidgetBuilder,
    this.themeAdaptiveType,
  }) : super(key: key);

  final WidgetBuilder materialWidgetBuilder;

  final WidgetBuilder cupertinoWidgetBuilder;

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