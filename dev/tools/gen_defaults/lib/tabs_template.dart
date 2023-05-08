// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class TabsTemplate extends TokenTemplate {
  const TabsTemplate(super.blockName, super.fileName, super.tokens, {
    super.colorSchemePrefix = '_colors.',
    super.textThemePrefix = '_textTheme.',
  });

  @override
  String generate() => '''
class _${blockName}PrimaryDefaultsM3 extends TabBarTheme {
  _${blockName}PrimaryDefaultsM3(this.context)
    : super(indicatorSize: TabBarIndicatorSize.label);

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color? get dividerColor => ${componentColor("md.comp.primary-navigation-tab.divider")};

  @override
  Color? get indicatorColor => ${componentColor("md.comp.primary-navigation-tab.active-indicator")};

  @override
  Color? get labelColor => ${componentColor("md.comp.primary-navigation-tab.with-label-text.active.label-text")};

  @override
  TextStyle? get labelStyle => ${textStyle("md.comp.primary-navigation-tab.with-label-text.label-text")};

  @override
  Color? get unselectedLabelColor => ${componentColor("md.comp.primary-navigation-tab.with-label-text.inactive.label-text")};

  @override
  TextStyle? get unselectedLabelStyle => ${textStyle("md.comp.primary-navigation-tab.with-label-text.label-text")};

  @override
  MaterialStateProperty<Color?> get overlayColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.hovered)) {
          return ${componentColor('md.comp.primary-navigation-tab.active.hover.state-layer')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${componentColor('md.comp.primary-navigation-tab.active.focus.state-layer')};
        }
        if (states.contains(MaterialState.pressed)) {
          return ${componentColor('md.comp.primary-navigation-tab.active.pressed.state-layer')};
        }
        return null;
      }
      if (states.contains(MaterialState.hovered)) {
        return ${componentColor('md.comp.primary-navigation-tab.inactive.hover.state-layer')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${componentColor('md.comp.primary-navigation-tab.inactive.focus.state-layer')};
      }
      if (states.contains(MaterialState.pressed)) {
        return ${componentColor('md.comp.primary-navigation-tab.inactive.pressed.state-layer')};
      }
      return null;
    });
  }

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}

class _${blockName}SecondaryDefaultsM3 extends TabBarTheme {
  _${blockName}SecondaryDefaultsM3(this.context)
    : super(indicatorSize: TabBarIndicatorSize.tab);

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color? get dividerColor => ${componentColor("md.comp.secondary-navigation-tab.divider")};

  @override
  Color? get indicatorColor => ${componentColor("md.comp.primary-navigation-tab.active-indicator")};

  @override
  Color? get labelColor => ${componentColor("md.comp.secondary-navigation-tab.active.label-text")};

  @override
  TextStyle? get labelStyle => ${textStyle("md.comp.secondary-navigation-tab.label-text")};

  @override
  Color? get unselectedLabelColor => ${componentColor("md.comp.secondary-navigation-tab.inactive.label-text")};

  @override
  TextStyle? get unselectedLabelStyle => ${textStyle("md.comp.secondary-navigation-tab.label-text")};

  @override
  MaterialStateProperty<Color?> get overlayColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.hovered)) {
          return ${componentColor('md.comp.secondary-navigation-tab.hover.state-layer')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${componentColor('md.comp.secondary-navigation-tab.focus.state-layer')};
        }
        if (states.contains(MaterialState.pressed)) {
          return ${componentColor('md.comp.secondary-navigation-tab.pressed.state-layer')};
        }
        return null;
      }
      if (states.contains(MaterialState.hovered)) {
        return ${componentColor('md.comp.secondary-navigation-tab.hover.state-layer')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${componentColor('md.comp.secondary-navigation-tab.focus.state-layer')};
      }
      if (states.contains(MaterialState.pressed)) {
        return ${componentColor('md.comp.secondary-navigation-tab.pressed.state-layer')};
      }
      return null;
    });
  }

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}
''';

}
