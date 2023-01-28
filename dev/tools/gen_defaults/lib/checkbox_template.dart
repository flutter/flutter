// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class CheckboxTemplate extends TokenTemplate {
  const CheckboxTemplate(super.blockName, super.fileName, super.tokens, {
    super.colorSchemePrefix = '_colors.',
  });

  @override
  String generate() => '''
class _${blockName}DefaultsM3 extends CheckboxThemeData {
  _${blockName}DefaultsM3(BuildContext context)
    : _theme = Theme.of(context),
      _colors = Theme.of(context).colorScheme;

  final ThemeData _theme;
  final ColorScheme _colors;

  @override
  MaterialStateProperty<Color> get fillColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return ${componentColor('md.comp.checkbox.selected.disabled.container')};
      }
      if (states.contains(MaterialState.error)) {
        return ${componentColor('md.comp.checkbox.unselected.error.outline')};
      }
      if (states.contains(MaterialState.selected)) {
        return ${componentColor('md.comp.checkbox.selected.container')};
      }
      if (states.contains(MaterialState.pressed)) {
        return ${componentColor('md.comp.checkbox.unselected.pressed.outline')};
      }
      if (states.contains(MaterialState.hovered)) {
        return ${componentColor('md.comp.checkbox.unselected.hover.outline')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${componentColor('md.comp.checkbox.unselected.focus.outline')};
      }
      return ${componentColor('md.comp.checkbox.unselected.outline')};
    });
  }

  @override
  MaterialStateProperty<Color> get checkColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        if (states.contains(MaterialState.selected)) {
          return ${componentColor('md.comp.checkbox.selected.disabled.icon')};
        }
        return Colors.transparent; // No icons available when the checkbox is unselected.
      }
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.error)) {
          return ${componentColor('md.comp.checkbox.selected.error.icon')};
        }
        return ${componentColor('md.comp.checkbox.selected.icon')};
      }
      return Colors.transparent; // No icons available when the checkbox is unselected.
    });
  }

  @override
  MaterialStateProperty<Color> get overlayColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.error)) {
        if (states.contains(MaterialState.pressed)) {
          return ${componentColor('md.comp.checkbox.error.pressed.state-layer')};
        }
        if (states.contains(MaterialState.hovered)) {
          return ${componentColor('md.comp.checkbox.error.hover.state-layer')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${componentColor('md.comp.checkbox.error.focus.state-layer')}.withOpacity(0.12);
        }
      }
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.pressed)) {
          return ${componentColor('md.comp.checkbox.selected.pressed.state-layer')};
        }
        if (states.contains(MaterialState.hovered)) {
          return ${componentColor('md.comp.checkbox.selected.hover.state-layer')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${componentColor('md.comp.checkbox.selected.focus.state-layer')};
        }
        return Colors.transparent;
      }
      if (states.contains(MaterialState.pressed)) {
        return ${componentColor('md.comp.checkbox.unselected.pressed.state-layer')};
      }
      if (states.contains(MaterialState.hovered)) {
        return ${componentColor('md.comp.checkbox.unselected.hover.state-layer')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${componentColor('md.comp.checkbox.unselected.focus.state-layer')};
      }
      return Colors.transparent;
    });
  }

  @override
  double get splashRadius => ${tokens['md.comp.checkbox.state-layer.size']} / 2;

  @override
  MaterialTapTargetSize get materialTapTargetSize => _theme.materialTapTargetSize;

  @override
  VisualDensity get visualDensity => _theme.visualDensity;
}
''';
}
