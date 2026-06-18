// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// A [PreviewThemeData] that applies Material [ThemeData] to a preview.
///
/// NOTE: this interface is not stable and **will change**.
final class MaterialPreviewThemeData extends PreviewThemeData {
  /// Creates a [MaterialPreviewThemeData] that applies Material [ThemeData] to a preview.
  const MaterialPreviewThemeData({this.light, this.dark});

  /// The Material [ThemeData] to apply when light mode is enabled.
  final ThemeData? light;

  /// The Material [ThemeData] to apply when dark mode is enabled.
  final ThemeData? dark;

  @override
  Widget apply(BuildContext context, Widget child) {
    final Brightness brightness = MediaQuery.platformBrightnessOf(context);
    final ThemeData? theme = brightness == Brightness.light ? light : dark;
    if (theme != null) {
      return Theme(data: theme, child: child);
    }
    return child;
  }
}
