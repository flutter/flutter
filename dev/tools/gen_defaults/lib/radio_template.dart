// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class RadioTemplate extends TokenTemplate {
  const RadioTemplate(
    super.blockName,
    super.fileName,
    super.tokens, {
    super.colorSchemePrefix = '_colors.',
  });

  @override
  String generate() =>
      '''
class _RadioDefaultsM3 extends RadioThemeData {
  _RadioDefaultsM3(this.context);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;

  @override
  WidgetStateProperty<Color> get fillColor {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.disabled)) {
          return ${componentColor('md.comp.radio-button.disabled.selected.icon')};
        }
        if (states.contains(WidgetState.pressed)) {
          return ${componentColor('md.comp.radio-button.selected.pressed.icon')};
        }
        if (states.contains(WidgetState.hovered)) {
          return ${componentColor('md.comp.radio-button.selected.hover.icon')};
        }
        if (states.contains(WidgetState.focused)) {
          return ${componentColor('md.comp.radio-button.selected.focus.icon')};
        }
        return ${componentColor('md.comp.radio-button.selected.icon')};
      }
      if (states.contains(WidgetState.disabled)) {
        return ${componentColor('md.comp.radio-button.disabled.unselected.icon')};
      }
      if (states.contains(WidgetState.pressed)) {
        return ${componentColor('md.comp.radio-button.unselected.pressed.icon')};
      }
      if (states.contains(WidgetState.hovered)) {
        return ${componentColor('md.comp.radio-button.unselected.hover.icon')};
      }
      if (states.contains(WidgetState.focused)) {
        return ${componentColor('md.comp.radio-button.unselected.focus.icon')};
      }
      return ${componentColor('md.comp.radio-button.unselected.icon')};
    });
  }

  @override
  WidgetStateProperty<Color> get overlayColor {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return ${componentColor('md.comp.radio-button.selected.pressed.state-layer')};
        }
        if (states.contains(WidgetState.hovered)) {
          return ${componentColor('md.comp.radio-button.selected.hover.state-layer')};
        }
        if (states.contains(WidgetState.focused)) {
          return ${componentColor('md.comp.radio-button.selected.focus.state-layer')};
        }
        return Colors.transparent;
      }
      if (states.contains(WidgetState.pressed)) {
        return ${componentColor('md.comp.radio-button.unselected.pressed.state-layer')};
      }
      if (states.contains(WidgetState.hovered)) {
        return ${componentColor('md.comp.radio-button.unselected.hover.state-layer')};
      }
      if (states.contains(WidgetState.focused)) {
        return ${componentColor('md.comp.radio-button.unselected.focus.state-layer')};
      }
      return Colors.transparent;
    });
  }

  @override
  MaterialTapTargetSize get materialTapTargetSize => _theme.materialTapTargetSize;

  @override
  VisualDensity get visualDensity => _theme.visualDensity;

  @override
  WidgetStateProperty<Color> get backgroundColor =>
      WidgetStateProperty.all<Color>(Colors.transparent);
}
''';
}
