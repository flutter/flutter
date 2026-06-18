// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// A [PreviewThemeData] that applies Cupertino [CupertinoThemeData] to a preview.
///
/// NOTE: this interface is not stable and **will change**.
final class CupertinoPreviewThemeData extends PreviewThemeData {
  /// Creates a [CupertinoPreviewThemeData] that applies Cupertino [CupertinoThemeData] to a preview.
  const CupertinoPreviewThemeData({this.light, this.dark});

  /// The Cupertino [CupertinoThemeData] to apply when light mode is enabled.
  final CupertinoThemeData? light;

  /// The Cupertino [CupertinoThemeData] to apply when dark mode is enabled.
  final CupertinoThemeData? dark;

  @override
  Widget apply(BuildContext context, Widget child) {
    final Brightness brightness = MediaQuery.platformBrightnessOf(context);
    final CupertinoThemeData? theme = brightness == Brightness.light ? light : dark;
    if (theme != null) {
      return CupertinoTheme(data: theme, child: child);
    }
    return child;
  }
}
