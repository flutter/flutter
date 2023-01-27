// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class MenuTemplate extends TokenTemplate {
  const MenuTemplate(super.blockName, super.fileName, super.tokens, {
    super.colorSchemePrefix = '_colors.',
  });

  @override
  String generate() => '''
class _MenuBarDefaultsM3 extends MenuStyle {
  _MenuBarDefaultsM3(this.context)
    : super(
      elevation: const MaterialStatePropertyAll<double?>(${elevation('md.comp.menu.container')}),
      shape: const MaterialStatePropertyAll<OutlinedBorder>(_defaultMenuBorder),
      alignment: AlignmentDirectional.bottomStart,
    );
  static const RoundedRectangleBorder _defaultMenuBorder =
    ${shape('md.comp.menu.container', '')};

  final BuildContext context;

  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  MaterialStateProperty<Color?> get backgroundColor {
    return MaterialStatePropertyAll<Color?>(${componentColor('md.comp.menu.container')});
  }

  @override
  MaterialStateProperty<Color?>? get shadowColor {
    return MaterialStatePropertyAll<Color?>(${color('md.comp.menu.container.shadow-color')});
  }

  @override
  MaterialStateProperty<Color?>? get surfaceTintColor {
    return MaterialStatePropertyAll<Color?>(${componentColor('md.comp.menu.container.surface-tint-layer')});
  }

  @override
  MaterialStateProperty<EdgeInsetsGeometry?>? get padding {
    return MaterialStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsetsDirectional.symmetric(
        horizontal: math.max(
          _kTopLevelMenuHorizontalMinPadding,
          2 + Theme.of(context).visualDensity.baseSizeAdjustment.dx,
        ),
      ),
    );
  }
}

class _MenuButtonDefaultsM3 extends ButtonStyle {
  _MenuButtonDefaultsM3(this.context)
    : super(
      animationDuration: kThemeChangeDuration,
      enableFeedback: true,
      alignment: AlignmentDirectional.centerStart,
    );
  final BuildContext context;

  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  MaterialStateProperty<Color?>? get backgroundColor {
    return ButtonStyleButton.allOrNull<Color>(Colors.transparent);
  }

  // No default shadow color

  // No default surface tint color

  @override
  MaterialStateProperty<double>? get elevation {
    return ButtonStyleButton.allOrNull<double>(0.0);
  }

  @override
  MaterialStateProperty<Color?>? get foregroundColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return ${componentColor('md.comp.menu.list-item.disabled.label-text')};
      }
      if (states.contains(MaterialState.pressed)) {
        return ${componentColor('md.comp.menu.list-item.pressed.label-text')};
      }
      if (states.contains(MaterialState.hovered)) {
        return ${componentColor('md.comp.menu.list-item.hover.label-text')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${componentColor('md.comp.menu.list-item.focus.label-text')};
      }
      return ${componentColor('md.comp.menu.list-item.label-text')};
    });
  }

  @override
  MaterialStateProperty<Color?>? get iconColor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return ${componentColor('md.comp.menu.list-item.with-leading-icon.disabled.leading-icon')};
      }
      if (states.contains(MaterialState.pressed)) {
        return ${componentColor('md.comp.menu.list-item.with-leading-icon.pressed.icon')};
      }
      if (states.contains(MaterialState.hovered)) {
        return ${componentColor('md.comp.menu.list-item.with-leading-icon.hover.icon')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${componentColor('md.comp.menu.list-item.with-leading-icon.focus.icon')};
      }
      return ${componentColor('md.comp.menu.list-item.with-leading-icon.leading-icon')};
    });
  }

  // No default fixedSize

  @override
  MaterialStateProperty<Size>? get maximumSize {
    return ButtonStyleButton.allOrNull<Size>(Size.infinite);
  }

  @override
  MaterialStateProperty<Size>? get minimumSize {
    return ButtonStyleButton.allOrNull<Size>(const Size(64.0, ${tokens['md.comp.menu.list-item.container.height']}));
  }

  @override
  MaterialStateProperty<MouseCursor?>? get mouseCursor {
    return MaterialStateProperty.resolveWith(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return SystemMouseCursors.basic;
        }
        return SystemMouseCursors.click;
      },
    );
  }

  @override
  MaterialStateProperty<Color?>? get overlayColor {
    return MaterialStateProperty.resolveWith(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.pressed)) {
          return ${componentColor('md.comp.menu.list-item.pressed.state-layer')};
        }
        if (states.contains(MaterialState.hovered)) {
          return ${componentColor('md.comp.menu.list-item.hover.state-layer')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${componentColor('md.comp.menu.list-item.focus.state-layer')};
        }
        return Colors.transparent;
      },
    );
  }

  @override
  MaterialStateProperty<EdgeInsetsGeometry>? get padding {
    return ButtonStyleButton.allOrNull<EdgeInsetsGeometry>(_scaledPadding(context));
  }

  // No default side

  @override
  MaterialStateProperty<OutlinedBorder>? get shape {
    return ButtonStyleButton.allOrNull<OutlinedBorder>(const RoundedRectangleBorder());
  }

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  MaterialStateProperty<TextStyle?> get textStyle {
    return MaterialStatePropertyAll<TextStyle?>(${textStyle('md.comp.menu.list-item.label-text')});
  }

  @override
  VisualDensity? get visualDensity => Theme.of(context).visualDensity;

  // The horizontal padding number comes from the spec.
  EdgeInsetsGeometry _scaledPadding(BuildContext context) {
    return ButtonStyleButton.scaledPadding(
      const EdgeInsets.symmetric(horizontal: 12),
      const EdgeInsets.symmetric(horizontal: 8),
      const EdgeInsets.symmetric(horizontal: 4),
      MediaQuery.maybeOf(context)?.textScaleFactor ?? 1,
    );
  }
}

class _MenuDefaultsM3 extends MenuStyle {
  _MenuDefaultsM3(this.context)
    : super(
      elevation: const MaterialStatePropertyAll<double?>(${elevation('md.comp.menu.container')}),
      shape: const MaterialStatePropertyAll<OutlinedBorder>(_defaultMenuBorder),
      alignment: AlignmentDirectional.topEnd,
    );
  static const RoundedRectangleBorder _defaultMenuBorder =
    ${shape('md.comp.menu.container', '')};

  final BuildContext context;

  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  MaterialStateProperty<Color?> get backgroundColor {
    return MaterialStatePropertyAll<Color?>(${componentColor('md.comp.menu.container')});
  }

  @override
  MaterialStateProperty<Color?>? get surfaceTintColor {
    return MaterialStatePropertyAll<Color?>(${componentColor('md.comp.menu.container.surface-tint-layer')});
  }

  @override
  MaterialStateProperty<Color?>? get shadowColor {
    return MaterialStatePropertyAll<Color?>(${color('md.comp.menu.container.shadow-color')});
  }

  @override
  MaterialStateProperty<EdgeInsetsGeometry?>? get padding {
    return MaterialStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsetsDirectional.symmetric(
        vertical: math.max(
          _kMenuVerticalMinPadding,
          2 + Theme.of(context).visualDensity.baseSizeAdjustment.dy,
        ),
      ),
    );
  }
}
''';
}
