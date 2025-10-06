// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// NOTE: originally from package:devtools_app_shared

import 'package:flutter/widgets.dart';

import '../utils/color_utils.dart';
import 'theme.dart';

export '_ide_theme_desktop.dart'
    if (dart.library.js_interop) '_ide_theme_web.dart';

/// The type of embedding for this DevTools instance.
///
/// The embed mode will be specified by the IDE or tool that is embedding
/// DevTools by setting query parameters in the DevTools URI.
///
/// 'embedMode=many' => EmbedMode.embedMany, which means that many DevTools
/// screens will be embedded in this view. This will result in the top level
/// tab bar being present. Any screens that should be hidden in this mode will
/// be specified by the 'hide' query parameter.
///
/// 'embedMode=one' => EmbedMode.embedOne, which means that a single DevTools
/// screen will be embedded in this view. This will result in the top level tab
/// bar being hidden, and only the screen specified by the URI path will be
/// shown.
enum EmbedMode {
  embedOne,
  embedMany,
  none;

  static EmbedMode fromArgs(Map<String, String?> args) {
    final embedMode = args[_embedModeKey];
    if (embedMode != null) {
      return switch (embedMode) {
        _embedModeManyValue => EmbedMode.embedMany,
        _embedModeOneValue => EmbedMode.embedOne,
        _ => EmbedMode.none,
      };
    }

    return EmbedMode.none;
  }

  static const _embedModeKey = 'embedMode';
  static const _embedModeOneValue = 'one';
  static const _embedModeManyValue = 'many';

  bool get embedded =>
      this == EmbedMode.embedOne || this == EmbedMode.embedMany;
}

/// IDE-supplied theming.
final class IdeTheme {
  const IdeTheme({
    this.backgroundColor,
    this.foregroundColor,
    this.embedMode = EmbedMode.none,
    bool? isDarkMode,
  }) : _isDarkMode = isDarkMode;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final EmbedMode embedMode;
  final bool? _isDarkMode;

  bool get embedded => embedMode.embedded;

  bool get isDarkMode => _isDarkMode ?? useDarkThemeAsDefault;

  /// Whether the IDE specified the DevTools color theme.
  ///
  /// If this returns false, that means the
  /// [IdeThemeQueryParams.devToolsThemeKey] query parameter was not passed to
  /// DevTools from the IDE.
  bool get ideSpecifiedTheme => _isDarkMode != null;
}

extension type IdeThemeQueryParams(Map<String, String?> params) {
  Color? get backgroundColor => tryParseColor(params[backgroundColorKey]);

  Color? get foregroundColor => tryParseColor(params[foregroundColorKey]);

  EmbedMode get embedMode => EmbedMode.fromArgs(params);

  bool get darkMode => params[devToolsThemeKey] != lightThemeValue;

  static const backgroundColorKey = 'backgroundColor';
  static const foregroundColorKey = 'foregroundColor';
  static const devToolsThemeKey = 'theme';
  static const lightThemeValue = 'light';
  static const darkThemeValue = 'dark';
}
