// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class SegmentedButtonTemplate extends TokenTemplate {
  const SegmentedButtonTemplate(super.blockName, super.fileName, super.tokens, {
    super.colorSchemePrefix = '_colors.',
  });

  String _layerOpacity(String layerToken) {
    if (tokens.containsKey(layerToken)) {
      final String? layerValue = tokens[layerToken] as String?;
      if (tokens.containsKey(layerValue)) {
        final String? opacityValue = opacity(layerValue!);
        if (opacityValue != null) {
          return '.withOpacity($opacityValue)';
        }
      }
    }
    return '';
  }

  String _stateColor(String componentToken, String type, String state) {
    final String baseColor = color('$componentToken.$type.$state.state-layer.color', '');
    if (baseColor.isEmpty) {
      return 'null';
    }
    final String opacity = _layerOpacity('$componentToken.$state.state-layer.opacity');
    return '$baseColor$opacity';
  }

  @override
  String generate() => '''
class _SegmentedButtonDefaultsM3 extends SegmentedButtonThemeData {
  _SegmentedButtonDefaultsM3(this.context);

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;

  @override
  MaterialStateProperty<Color?>? get backgroundColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return ${componentColor('md.comp.outlined-segmented-button.disabled')};
      }
      if (states.contains(MaterialState.selected)) {
        return ${componentColor('md.comp.outlined-segmented-button.selected.container')};
      }
      return ${componentColor('md.comp.outlined-segmented-button.unselected.container')};
    });
  }

  @override
  MaterialStateProperty<Color?>? get foregroundColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return ${componentColor('md.comp.outlined-segmented-button.disabled.label-text')};
      }
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.pressed)) {
          return ${componentColor('md.comp.outlined-segmented-button.selected.pressed.label-text')};
        }
        if (states.contains(MaterialState.hovered)) {
          return ${componentColor('md.comp.outlined-segmented-button.selected.hover.label-text')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${componentColor('md.comp.outlined-segmented-button.selected.focus.label-text')};
        }
        return ${componentColor('md.comp.outlined-segmented-button.selected.label-text')};
      } else {
        if (states.contains(MaterialState.pressed)) {
          return ${componentColor('md.comp.outlined-segmented-button.unselected.pressed.label-text')};
        }
        if (states.contains(MaterialState.hovered)) {
          return ${componentColor('md.comp.outlined-segmented-button.unselected.hover.label-text')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${componentColor('md.comp.outlined-segmented-button.unselected.focus.label-text')};
        }
        return ${componentColor('md.comp.outlined-segmented-button.unselected.container')};
      }
    });
  }

  @override
  MaterialStateProperty<Color?>? get overlayColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.hovered)) {
          return ${_stateColor('md.comp.outlined-segmented-button', 'selected', 'hover')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${_stateColor('md.comp.outlined-segmented-button', 'selected', 'focus')};
        }
        if (states.contains(MaterialState.pressed)) {
          return ${_stateColor('md.comp.outlined-segmented-button', 'selected', 'pressed')};
        }
      } else {
        if (states.contains(MaterialState.hovered)) {
          return ${_stateColor('md.comp.outlined-segmented-button', 'unselected', 'hover')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${_stateColor('md.comp.outlined-segmented-button', 'unselected', 'focus')};
        }
        if (states.contains(MaterialState.pressed)) {
          return ${_stateColor('md.comp.outlined-segmented-button', 'unselected', 'pressed')};
        }
      }
      return null;
    });
  }

  @override MaterialStateProperty<TextStyle?>? get textStyle =>
    MaterialStatePropertyAll<TextStyle?>(${textStyle('md.comp.outlined-segmented-button.label-text')});

  @override MaterialStateProperty<double?>? get iconSize =>
    const MaterialStatePropertyAll<double?>(${tokens['md.comp.outlined-segmented-button.with-icon.icon.size']});

  @override
  MaterialStateProperty<OutlinedBorder?>? get segmentShape {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return PartialRectOutlinedBorder(side: BorderSide(color: ${componentColor('md.comp.outlined-segmented-button.disabled.outline')}), top: true, bottom: true);
      }
      return PartialRectOutlinedBorder(side: BorderSide(color: ${componentColor('md.comp.outlined-segmented-button.outline')}), top: true, bottom: true);
    });
  }

  @override
  MaterialStateProperty<OutlinedBorder?>? get startSegmentShape {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return HalfStadiumBorder(side: BorderSide(color: ${componentColor('md.comp.outlined-segmented-button.disabled.outline')}));
      }
      return HalfStadiumBorder(side: BorderSide(color: ${componentColor('md.comp.outlined-segmented-button.outline')}));
    });
  }

  @override
  MaterialStateProperty<OutlinedBorder?>? get endSegmentShape {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return HalfStadiumBorder(roundStart: false, side: BorderSide(color: ${componentColor('md.comp.outlined-segmented-button.disabled.outline')}));
      }
      return HalfStadiumBorder(roundStart: false, side: BorderSide(color: ${componentColor('md.comp.outlined-segmented-button.outline')}));
    });
  }

  @override
  MaterialStateProperty<BorderSide?>? get divider {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return BorderSide(color: ${componentColor('md.comp.outlined-segmented-button.disabled.outline')});
      }
      return BorderSide(color: ${componentColor('md.comp.outlined-segmented-button.outline')});
    });
  }
}
''';
}
