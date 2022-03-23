// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class NavigationBarTemplate extends TokenTemplate {
  const NavigationBarTemplate(String fileName, Map<String, dynamic> tokens)
      : super(fileName, tokens);

  @override
  String generate() => '''
// Generated version ${tokens["version"]}
class _TokenDefaultsM3 extends NavigationBarThemeData {
  _TokenDefaultsM3(BuildContext context)
      : _theme = Theme.of(context),
        _colors = Theme.of(context).colorScheme,
        super(
          height: ${tokens["md.comp.navigation-bar.container.height"]},
          elevation: ${elevation("md.comp.navigation-bar.container")},
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        );

  final ThemeData _theme;
  final ColorScheme _colors;

  // With Material 3, the NavigationBar uses an overlay blend for the
  // default color regardless of light/dark mode. This should be handled
  // in the Material widget based off of elevation, but for now we will do
  // it here in the defaults.
  @override Color? get backgroundColor => ElevationOverlay.colorWithOverlay(_colors.${color("md.comp.navigation-bar.container")}, _colors.primary, ${elevation("md.comp.navigation-bar.container")});

  @override MaterialStateProperty<IconThemeData?>? get iconTheme {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      return IconThemeData(
        size: ${tokens["md.comp.navigation-bar.icon.size"]},
        color: states.contains(MaterialState.selected)
          ? _colors.${color("md.comp.navigation-bar.active.icon")}
          : _colors.${color("md.comp.navigation-bar.inactive.icon")},
      );
    });
  }

  @override Color? get indicatorColor => _colors.${color("md.comp.navigation-bar.active-indicator")};
  @override ShapeBorder? get indicatorShape => ${shape("md.comp.navigation-bar.active-indicator")};

  @override MaterialStateProperty<TextStyle?>? get labelTextStyle {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
    final TextStyle style = _theme.textTheme.${textStyle("md.comp.navigation-bar.label-text")}!;
      return style.apply(color: states.contains(MaterialState.selected)
        ? _colors.${color("md.comp.navigation-bar.active.label-text")}
        : _colors.${color("md.comp.navigation-bar.inactive.label-text")}
      );
    });
  }
}
''';
}
