// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class NavigationBarTemplate extends TokenTemplate {
  const NavigationBarTemplate(super.fileName, super.tokens)
    : super(colorSchemePrefix: '_colors.',
        textThemePrefix: '_textTheme.',
      );

  @override
  String generate() => '''
// Generated version ${tokens["version"]}
class _TokenDefaultsM3 extends NavigationBarThemeData {
  _TokenDefaultsM3(this.context)
      : super(
          height: ${tokens["md.comp.navigation-bar.container.height"]},
          elevation: ${elevation("md.comp.navigation-bar.container")},
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  // With Material 3, the NavigationBar uses an overlay blend for the
  // default color regardless of light/dark mode. This should be handled
  // in the Material widget based off of elevation, but for now we will do
  // it here in the defaults.
  @override Color? get backgroundColor => ElevationOverlay.colorWithOverlay(${componentColor("md.comp.navigation-bar.container")}, _colors.primary, ${elevation("md.comp.navigation-bar.container")});

  @override MaterialStateProperty<IconThemeData?>? get iconTheme {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      return IconThemeData(
        size: ${tokens["md.comp.navigation-bar.icon.size"]},
        color: states.contains(MaterialState.selected)
          ? ${componentColor("md.comp.navigation-bar.active.icon")}
          : ${componentColor("md.comp.navigation-bar.inactive.icon")},
      );
    });
  }

  @override Color? get indicatorColor => ${componentColor("md.comp.navigation-bar.active-indicator")};
  @override ShapeBorder? get indicatorShape => ${shape("md.comp.navigation-bar.active-indicator")};

  @override MaterialStateProperty<TextStyle?>? get labelTextStyle {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
    final TextStyle style = ${textStyle("md.comp.navigation-bar.label-text")}!;
      return style.apply(color: states.contains(MaterialState.selected)
        ? ${componentColor("md.comp.navigation-bar.active.label-text")}
        : ${componentColor("md.comp.navigation-bar.inactive.label-text")}
      );
    });
  }
}
''';
}
