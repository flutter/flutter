// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class NavigationRailTemplate extends TokenTemplate {
  const NavigationRailTemplate(String fileName, Map<String, dynamic> tokens) : super(fileName, tokens);

  @override
  String generate() => '''
// Generated version ${tokens["version"]}
class _TokenDefaultsM3 extends NavigationRailThemeData {
  _TokenDefaultsM3(BuildContext context)
      : _theme = Theme.of(context),
        _colors = Theme.of(context).colorScheme,
        super(
          elevation: ${elevation("md.comp.navigation-rail.container")},
          groupAlignment: -1,
          labelType: NavigationRailLabelType.none,
          useIndicator: true,
          minWidth: ${tokens["md.comp.navigation-rail.container.width"]},
          minExtendedWidth: 256,
        );

  final ThemeData _theme;
  final ColorScheme _colors;

  @override Color? get backgroundColor => _colors.${color("md.comp.navigation-rail.container")};

  @override TextStyle? get unselectedLabelTextStyle {
    return _theme.textTheme.${textStyle("md.comp.navigation-rail.label-text")}!.copyWith(color: _colors.${color("md.comp.navigation-rail.inactive.focus.label-text")});
  }

  @override TextStyle? get selectedLabelTextStyle {
    return _theme.textTheme.${textStyle("md.comp.navigation-rail.label-text")}!.copyWith(color: _colors.${color("md.comp.navigation-rail.active.focus.label-text")});
  }

  @override IconThemeData? get unselectedIconTheme {
    return IconThemeData(
      size: ${tokens["md.comp.navigation-rail.icon.size"]},
      color: _colors.${color("md.comp.navigation-rail.inactive.icon")},
    );
  }

  @override IconThemeData? get selectedIconTheme {
    return IconThemeData(
      size: ${tokens["md.comp.navigation-rail.icon.size"]},
      color: _colors.${color("md.comp.navigation-rail.active.icon")},
    );
  }

  @override Color? get indicatorColor => _colors.${color("md.comp.navigation-rail.active-indicator")};

}
''';
}
