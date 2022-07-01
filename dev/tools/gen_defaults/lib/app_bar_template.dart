// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class AppBarTemplate extends TokenTemplate {
  const AppBarTemplate(super.fileName, super.tokens)
    : super(
      colorSchemePrefix: '_colors.',
      textThemePrefix: '_textTheme.',
    );

  @override
  String generate() => '''
// Generated version ${tokens["version"]}
class _TokenDefaultsM3 extends AppBarTheme {
  _TokenDefaultsM3(this.context)
    : super(
      elevation: ${elevation('md.comp.top-app-bar.small.container')},
      scrolledUnderElevation: ${elevation('md.comp.top-app-bar.small.on-scroll.container')},
      titleSpacing: NavigationToolbar.kMiddleSpacing,
      toolbarHeight: ${tokens['md.comp.top-app-bar.small.container.height']},
    );

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;
  late final TextTheme _textTheme = _theme.textTheme;

  @override
  Color? get backgroundColor => ${componentColor('md.comp.top-app-bar.small.container')};

  @override
  Color? get foregroundColor => ${color('md.comp.top-app-bar.small.headline.color')};

  @override
  Color? get surfaceTintColor => ${componentColor('md.comp.top-app-bar.small.container.surface-tint-layer')};

  @override
  IconThemeData? get iconTheme => IconThemeData(
    color: ${componentColor('md.comp.top-app-bar.small.leading-icon')},
    size: ${tokens['md.comp.top-app-bar.small.leading-icon.size']},
  );

  @override
  IconThemeData? get actionsIconTheme => IconThemeData(
    color: ${componentColor('md.comp.top-app-bar.small.trailing-icon')},
    size: ${tokens['md.comp.top-app-bar.small.trailing-icon.size']},
  );

  @override
  TextStyle? get toolbarTextStyle => _textTheme.bodyText2;

  @override
  TextStyle? get titleTextStyle => ${textStyle('md.comp.top-app-bar.small.headline')};
}''';
}
