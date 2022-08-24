// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class SwitchTemplate extends TokenTemplate {
  const SwitchTemplate(super.blockName, super.fileName, super.tokens, {
    super.colorSchemePrefix = '_colors.',
  });

  @override
  String generate() => '''
class _${blockName}DefaultsM3 extends SwitchThemeData {
  _${blockName}DefaultsM3(BuildContext context)
      : _colors = Theme.of(context).colorScheme;

  final ColorScheme _colors;

  @override
  MaterialStateProperty<Color> get thumbColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        if (states.contains(MaterialState.selected)) {
          return ${componentColor('md.comp.switch.disabled.selected.handle')};
        }
        return ${componentColor('md.comp.switch.disabled.unselected.handle')};
      }
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.hovered)) {
          return ${componentColor('md.comp.switch.selected.hover.handle')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${componentColor('md.comp.switch.selected.focus.handle')};
        }
        if (states.contains(MaterialState.pressed)) {
          return ${componentColor('md.comp.switch.selected.pressed.handle')};
        }
        return ${componentColor('md.comp.switch.selected.handle')};
      }
      if (states.contains(MaterialState.hovered)) {
        return ${componentColor('md.comp.switch.unselected.hover.handle')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${componentColor('md.comp.switch.unselected.focus.handle')};
      }
      if (states.contains(MaterialState.pressed)) {
        return ${componentColor('md.comp.switch.unselected.pressed.handle')};
      }
      return ${componentColor('md.comp.switch.unselected.handle')};
    });
  }

  @override
  MaterialStateProperty<Color> get trackColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        if (states.contains(MaterialState.selected)) {
          return ${componentColor('md.comp.switch.disabled.selected.track')}.withOpacity(${opacity('md.comp.switch.disabled.track.opacity')});
        }
        return ${componentColor('md.comp.switch.disabled.unselected.track')}.withOpacity(${opacity('md.comp.switch.disabled.track.opacity')});
      }
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.hovered)) {
          return ${componentColor('md.comp.switch.selected.hover.track')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${componentColor('md.comp.switch.selected.focus.track')};
        }
        if (states.contains(MaterialState.pressed)) {
          return ${componentColor('md.comp.switch.selected.pressed.track')};
        }
        return ${componentColor('md.comp.switch.selected.track')};
      }
      if (states.contains(MaterialState.hovered)) {
        return ${componentColor('md.comp.switch.unselected.hover.track')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${componentColor('md.comp.switch.unselected.focus.track')};
      }
      if (states.contains(MaterialState.pressed)) {
        return ${componentColor('md.comp.switch.unselected.pressed.track')};
      }
      return ${componentColor('md.comp.switch.unselected.track')};
    });
  }

  @override
  MaterialStateProperty<Color?> get overlayColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.hovered)) {
          return ${componentColor('md.comp.switch.selected.hover.state-layer')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${componentColor('md.comp.switch.selected.focus.state-layer')};
        }
        if (states.contains(MaterialState.pressed)) {
          return ${componentColor('md.comp.switch.selected.pressed.state-layer')};
        }
        return null;
      }
      if (states.contains(MaterialState.hovered)) {
        return ${componentColor('md.comp.switch.unselected.hover.state-layer')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${componentColor('md.comp.switch.unselected.focus.state-layer')};
      }
      if (states.contains(MaterialState.pressed)) {
        return ${componentColor('md.comp.switch.unselected.pressed.state-layer')};
      }
      return null;
    });
  }

  @override
  double get splashRadius => ${tokens['md.comp.switch.state-layer.size']} / 2;
}

class _SwitchConfigM3 {
  _SwitchConfigM3(this.context)
    : _colors = Theme.of(context).colorScheme;

  BuildContext context;
  final ColorScheme _colors;

  static const double iconSize = ${tokens['md.comp.switch.unselected.icon.size']};
  static const double thumbRadiusWithIcon = ${tokens['md.comp.switch.with-icon.handle.width']} / 2;
  static const double inactiveThumbRadius = ${tokens['md.comp.switch.unselected.handle.width']} / 2;
  static const double activeThumbRadius = ${tokens['md.comp.switch.selected.handle.width']} / 2;
  static const double pressedThumbRadius = ${tokens['md.comp.switch.pressed.handle.width']} / 2;
  static const double trackWidth = ${tokens['md.comp.switch.track.width']};
  static const double trackHeight = ${tokens['md.comp.switch.track.height']};
  static const double trackRadius = ${tokens['md.comp.switch.track.height']} / 2.0;

  static const double switchWidth = trackWidth - 2 * trackRadius + _kSwitchMinSize;
  static const double switchHeight = _kSwitchMinSize + 8.0;
  static const double switchHeightCollapsed = _kSwitchMinSize;

  MaterialStateProperty<Color?> get trackOutlineColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return null;
      }
      if (states.contains(MaterialState.disabled)) {
        return ${componentColor('md.comp.switch.disabled.unselected.track.outline')}.withOpacity(${opacity('md.comp.switch.disabled.track.opacity')});
      }
      return ${componentColor('md.comp.switch.unselected.track.outline')};
    });
  }

  MaterialStateProperty<Color> get iconColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        if (states.contains(MaterialState.selected)) {
          return ${componentColor('md.comp.switch.disabled.selected.icon')};
        }
        return ${componentColor('md.comp.switch.disabled.unselected.icon')};
      }
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.hovered)) {
          return ${componentColor('md.comp.switch.selected.hover.icon')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${componentColor('md.comp.switch.selected.focus.icon')};
        }
        if (states.contains(MaterialState.pressed)) {
          return ${componentColor('md.comp.switch.selected.pressed.icon')};
        }
        return ${componentColor('md.comp.switch.selected.icon')};
      }
      if (states.contains(MaterialState.hovered)) {
        return ${componentColor('md.comp.switch.unselected.hover.icon')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${componentColor('md.comp.switch.unselected.focus.icon')};
      }
      if (states.contains(MaterialState.pressed)) {
        return ${componentColor('md.comp.switch.unselected.pressed.icon')};
      }
      return ${componentColor('md.comp.switch.unselected.icon')};
    });
  }
}
''';

}
