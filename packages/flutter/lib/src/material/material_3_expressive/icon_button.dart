// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Material 3 Expressive `IconButton`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../button_style.dart';
import '../button_style_button.dart';
import '../color_scheme.dart';
import '../colors.dart';
import '../constants.dart';
import '../icon_button_theme.dart';
import '../ink_well.dart';
import '../material_state.dart';
import '../theme.dart';
import '../theme_data.dart';

enum _IconButtonVariant { standard, filled, filledTonal, outlined }

/// A Material Design 3 Expressive icon button.
///
/// M3 Expressive icon buttons support five size variants ([IconButtonSize]),
/// shape morphing on press and selection, and updated color tokens.
///
/// Use [IconButton] for a standard icon button, [IconButton.filled] for a
/// filled icon button, [IconButton.filledTonal] for a filled tonal icon button,
/// and [IconButton.outlined] for an outlined icon button.
///
/// The [size] parameter controls the button dimensions. If not provided,
/// it defaults to [IconButtonSize.small] (40dp), or the size specified in
/// [IconButtonThemeData.size].
///
/// {@tool dartpad}
/// This sample shows how to use M3E [IconButton] with different sizes.
///
/// ** See code in examples/api/lib/material/icon_button/icon_button.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * <https://m3.material.io/components/icon-buttons/specs>
class IconButton extends ButtonStyleButton {
  /// Creates a Material Design 3 Expressive icon button.
  IconButton({
    super.key,
    super.style,
    super.focusNode,
    super.autofocus = false,
    super.tooltip,
    super.onPressed,
    super.onHover,
    super.onLongPress,
    super.isSelected,
    super.onSelected,
    this.selectedIcon,
    super.statesController,
    required this.icon,
  }) : _variant = _IconButtonVariant.standard,
       super(
         onFocusChange: null,
         clipBehavior: Clip.none,
         child: _IconButtonChild(isSelected: isSelected, icon: icon, selectedIcon: selectedIcon),
       );

  /// Creates a filled Material Design 3 Expressive icon button.
  IconButton.filled({
    super.key,
    super.style,
    super.focusNode,
    super.autofocus = false,
    super.tooltip,
    super.onPressed,
    super.onHover,
    super.onLongPress,
    super.isSelected,
    super.onSelected,
    this.selectedIcon,
    super.statesController,
    required this.icon,
  }) : _variant = _IconButtonVariant.filled,
       super(
         onFocusChange: null,
         clipBehavior: Clip.none,
         child: _IconButtonChild(isSelected: isSelected, icon: icon, selectedIcon: selectedIcon),
       );

  /// Creates a filled tonal Material Design 3 Expressive icon button.
  IconButton.filledTonal({
    super.key,
    super.style,
    super.focusNode,
    super.autofocus = false,
    super.tooltip,
    super.onPressed,
    super.onHover,
    super.onLongPress,
    super.isSelected,
    super.onSelected,
    this.selectedIcon,
    super.statesController,
    required this.icon,
  }) : _variant = _IconButtonVariant.filledTonal,
       super(
         onFocusChange: null,
         clipBehavior: Clip.none,
         child: _IconButtonChild(isSelected: isSelected, icon: icon, selectedIcon: selectedIcon),
       );

  /// Creates an outlined Material Design 3 Expressive icon button.
  IconButton.outlined({
    super.key,
    super.style,
    super.focusNode,
    super.autofocus = false,
    super.tooltip,
    super.onPressed,
    super.onHover,
    super.onLongPress,
    super.isSelected,
    super.onSelected,
    this.selectedIcon,
    super.statesController,
    required this.icon,
  }) : _variant = _IconButtonVariant.outlined,
       super(
         onFocusChange: null,
         clipBehavior: Clip.none,
         child: _IconButtonChild(isSelected: isSelected, icon: icon, selectedIcon: selectedIcon),
       );

  /// The icon to display inside the button.
  ///
  /// The [Icon.size] and [Icon.color] of the icon is configured automatically
  /// based on the [iconSize] and [color] properties of _this_ widget using an
  /// [IconTheme] and therefore should not be explicitly given in the icon
  /// widget.
  ///
  /// See [Icon], [ImageIcon].
  final Widget icon;

  /// The icon to display inside the button when [isSelected] is true.
  ///
  /// If this is null, [icon] is used for both selected and unselected states.
  final Widget? selectedIcon;

  final _IconButtonVariant _variant;

  /// A static convenience method that constructs an icon button [ButtonStyle]
  /// given simple values.
  static ButtonStyle styleFrom({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? shadowColor,
    Color? surfaceTintColor,
    Color? overlayColor,
    double? elevation,
    Size? minimumSize,
    Size? fixedSize,
    Size? maximumSize,
    double? iconSize,
    BorderSide? side,
    OutlinedBorder? shape,
    EdgeInsetsGeometry? padding,
    MouseCursor? enabledMouseCursor,
    MouseCursor? disabledMouseCursor,
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
    Duration? animationDuration,
    bool? enableFeedback,
    AlignmentGeometry? alignment,
    InteractiveInkFeatureFactory? splashFactory,
    IconButtonWidth? iconButtonWidth,
  }) {
    final Color? overlayFallback = overlayColor ?? foregroundColor;
    WidgetStateProperty<Color?>? overlayColorProp;
    if ((hoverColor ?? focusColor ?? highlightColor ?? overlayFallback) != null) {
      overlayColorProp = switch (overlayColor) {
        Color(a: 0.0) => WidgetStatePropertyAll<Color>(overlayColor),
        _ => WidgetStateProperty<Color?>.fromMap(<WidgetState, Color?>{
          WidgetState.pressed: highlightColor ?? overlayFallback?.withOpacity(0.1),
          WidgetState.hovered: hoverColor ?? overlayFallback?.withOpacity(0.08),
          WidgetState.focused: focusColor ?? overlayFallback?.withOpacity(0.1),
        }),
      };
    }

    return ButtonStyle(
      backgroundColor: ButtonStyleButton.defaultColor(backgroundColor, disabledBackgroundColor),
      foregroundColor: ButtonStyleButton.defaultColor(foregroundColor, disabledForegroundColor),
      overlayColor: overlayColorProp,
      shadowColor: ButtonStyleButton.allOrNull<Color>(shadowColor),
      surfaceTintColor: ButtonStyleButton.allOrNull<Color>(surfaceTintColor),
      elevation: ButtonStyleButton.allOrNull<double>(elevation),
      padding: ButtonStyleButton.allOrNull<EdgeInsetsGeometry>(padding),
      minimumSize: ButtonStyleButton.allOrNull<Size>(minimumSize),
      fixedSize: ButtonStyleButton.allOrNull<Size>(fixedSize),
      maximumSize: ButtonStyleButton.allOrNull<Size>(maximumSize),
      iconSize: ButtonStyleButton.allOrNull<double>(iconSize),
      side: ButtonStyleButton.allOrNull<BorderSide>(side),
      shape: ButtonStyleButton.allOrNull<OutlinedBorder>(shape),
      mouseCursor: disabledMouseCursor == null && enabledMouseCursor == null
          ? null
          : WidgetStateProperty<MouseCursor?>.fromMap(<WidgetStatesConstraint, MouseCursor?>{
              WidgetState.disabled: disabledMouseCursor,
              WidgetState.any: enabledMouseCursor,
            }),
      visualDensity: visualDensity,
      tapTargetSize: tapTargetSize,
      animationDuration: animationDuration,
      enableFeedback: enableFeedback,
      alignment: alignment,
      splashFactory: splashFactory,
      iconButtonWidth: iconButtonWidth,
    );
  }

  /// Resolves the effective [IconButtonSize] from widget, theme, and defaults.
  IconButtonSize _resolveSize(BuildContext context) {
    return style?.size ?? IconButtonTheme.of(context).style?.size ?? IconButtonSize.small;
  }

  /// Resolves the effective [IconButtonWidth] from widget, theme, and defaults.
  IconButtonWidth _resolveWidth(BuildContext context) {
    return style?.iconButtonWidth ??
        IconButtonTheme.of(context).style?.iconButtonWidth ??
        IconButtonWidth.standard;
  }

  @override
  ButtonStyle defaultStyleOf(BuildContext context) {
    final IconButtonSize effectiveSize = _resolveSize(context);
    final IconButtonWidth effectiveWidth = _resolveWidth(context);
    final ButtonStyle style = switch (_variant) {
      _IconButtonVariant.filled => _FilledIconButtonDefaultsM3E(
        context,
        isSelected != null,
        effectiveSize,
        effectiveWidth,
      ),
      _IconButtonVariant.filledTonal => _FilledTonalIconButtonDefaultsM3E(
        context,
        isSelected != null,
        effectiveSize,
        effectiveWidth,
      ),
      _IconButtonVariant.outlined => _OutlinedIconButtonDefaultsM3E(
        context,
        isSelected != null,
        effectiveSize,
        effectiveWidth,
      ),
      _IconButtonVariant.standard => _IconButtonDefaultsM3E(
        context,
        isSelected != null,
        effectiveSize,
        effectiveWidth,
      ),
    };
    return style;
  }

  @override
  ButtonStyle? themeStyleOf(BuildContext context) {
    final IconThemeData iconTheme = IconTheme.of(context);
    final isDefaultSize = iconTheme.size == const IconThemeData.fallback().size;
    final bool isDefaultColor = identical(iconTheme.color, switch (Theme.brightnessOf(context)) {
      Brightness.light => kDefaultIconDarkColor,
      Brightness.dark => kDefaultIconLightColor,
    });

    final ButtonStyle iconThemeStyle = IconButton.styleFrom(
      foregroundColor: isDefaultColor ? null : iconTheme.color,
      iconSize: isDefaultSize ? null : iconTheme.size,
    );

    final ButtonStyle themeStyle =
        IconButtonTheme.of(context).style?.merge(iconThemeStyle) ?? iconThemeStyle;
    return themeStyle;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('tooltip', tooltip, defaultValue: null, quoted: false));
    properties.add(ObjectFlagProperty<VoidCallback>('onPressed', onPressed, ifNull: 'disabled'));
    properties.add(ObjectFlagProperty<ValueChanged<bool>>('onHover', onHover, ifNull: 'disabled'));
    properties.add(
      ObjectFlagProperty<VoidCallback>('onLongPress', onLongPress, ifNull: 'disabled'),
    );
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode, defaultValue: null));

    properties.add(DiagnosticsProperty<ButtonStyle>('style', style, defaultValue: null));
  }
}

class _IconButtonChild extends StatelessWidget {
  const _IconButtonChild({
    required this.isSelected,
    required this.icon,
    required this.selectedIcon,
  });

  final bool? isSelected;
  final Widget icon;
  final Widget? selectedIcon;

  @override
  Widget build(BuildContext context) {
    final Widget effectiveIcon = (isSelected ?? false) && selectedIcon != null
        ? selectedIcon!
        : icon;
    return Semantics(selected: isSelected, child: effectiveIcon);
  }
}

// BEGIN GENERATED TOKEN PROPERTIES - IconButtonM3E

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   packages/flutter/lib/src/material/gen_defaults/bin/gen_defaults.dart.

// dart format off
class _IconButtonDefaultsM3E extends ButtonStyle {
  _IconButtonDefaultsM3E(this.context, this.toggleable, this.buttonSize, this.buttonWidth)
    : super(
        animationDuration: kThemeChangeDuration,
        enableFeedback: true,
        alignment: Alignment.center,
      );

  final BuildContext context;
  final bool toggleable;
  final IconButtonSize? buttonSize;
  final IconButtonWidth? buttonWidth;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  WidgetStateProperty<Color?>? get backgroundColor =>
    const MaterialStatePropertyAll<Color?>(Colors.transparent);

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.primary;
      }
      return _colors.onSurfaceVariant;
    });

  @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.primary.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.primary.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.primary.withOpacity(0.1);
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return _colors.onSurfaceVariant.withOpacity(0.1);
      }
      if (states.contains(WidgetState.hovered)) {
        return _colors.onSurfaceVariant.withOpacity(0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.onSurfaceVariant.withOpacity(0.1);
      }
      return Colors.transparent;
    });

  @override
  WidgetStateProperty<double>? get elevation =>
    const MaterialStatePropertyAll<double>(0.0);

  @override
  WidgetStateProperty<Color>? get shadowColor =>
    const MaterialStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<Color>? get surfaceTintColor =>
    const MaterialStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
    MaterialStatePropertyAll<EdgeInsetsGeometry>(switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(4.0, 6.0, 4.0, 6.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(6.0, 6.0, 6.0, 6.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(10.0, 6.0, 10.0, 6.0),
      },
      IconButtonSize.small => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(4.0, 8.0, 4.0, 8.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(8.0, 8.0, 8.0, 8.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(14.0, 8.0, 14.0, 8.0),
      },
      IconButtonSize.medium => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(12.0, 16.0, 12.0, 16.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 24.0, 16.0),
      },
      IconButtonSize.large => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(16.0, 32.0, 16.0, 32.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(32.0, 32.0, 32.0, 32.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(48.0, 32.0, 48.0, 32.0),
      },
      IconButtonSize.xLarge => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(32.0, 48.0, 32.0, 48.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(48.0, 48.0, 48.0, 48.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(72.0, 48.0, 72.0, 48.0),
      },
    });

  @override
  WidgetStateProperty<Size>? get minimumSize =>
    MaterialStatePropertyAll<Size>(switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(28.0, 32.0),
        IconButtonWidth.standard => const Size(32.0, 32.0),
        IconButtonWidth.wide => const Size(40.0, 32.0),
      },
      IconButtonSize.small => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(32.0, 40.0),
        IconButtonWidth.standard => const Size(40.0, 40.0),
        IconButtonWidth.wide => const Size(52.0, 40.0),
      },
      IconButtonSize.medium => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(48.0, 56.0),
        IconButtonWidth.standard => const Size(56.0, 56.0),
        IconButtonWidth.wide => const Size(72.0, 56.0),
      },
      IconButtonSize.large => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(64.0, 96.0),
        IconButtonWidth.standard => const Size(96.0, 96.0),
        IconButtonWidth.wide => const Size(128.0, 96.0),
      },
      IconButtonSize.xLarge => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(104.0, 136.0),
        IconButtonWidth.standard => const Size(136.0, 136.0),
        IconButtonWidth.wide => const Size(184.0, 136.0),
      },
    });

  @override
  WidgetStateProperty<Size>? get maximumSize =>
    const MaterialStatePropertyAll<Size>(Size.infinite);

  @override
  WidgetStateProperty<double>? get iconSize =>
    MaterialStatePropertyAll<double>(switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => 20.0,
      IconButtonSize.small => 24.0,
      IconButtonSize.medium => 24.0,
      IconButtonSize.large => 32.0,
      IconButtonSize.xLarge => 40.0,
    });

  @override
  WidgetStateProperty<OutlinedBorder>? get shape =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
      IconButtonSize.small => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
      IconButtonSize.medium => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      IconButtonSize.large => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
      IconButtonSize.xLarge => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
    };
      }
      if (states.contains(WidgetState.selected)) {
        return switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      IconButtonSize.small => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      IconButtonSize.medium => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
      IconButtonSize.large => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28.0))),
      IconButtonSize.xLarge => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28.0))),
    };
      }
      return switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => const StadiumBorder(),
      IconButtonSize.small => const StadiumBorder(),
      IconButtonSize.medium => const StadiumBorder(),
      IconButtonSize.large => const StadiumBorder(),
      IconButtonSize.xLarge => const StadiumBorder(),
    };
    });


  @override
  WidgetStateProperty<BorderSide?>? get side => null;

  @override
  WidgetStateProperty<MouseCursor?>? get mouseCursor => WidgetStateMouseCursor.adaptiveClickable;

  @override
  VisualDensity? get visualDensity => VisualDensity.standard;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}

class _FilledIconButtonDefaultsM3E extends ButtonStyle {
  _FilledIconButtonDefaultsM3E(this.context, this.toggleable, this.buttonSize, this.buttonWidth)
    : super(
        animationDuration: kThemeChangeDuration,
        enableFeedback: true,
        alignment: Alignment.center,
      );

  final BuildContext context;
  final bool toggleable;
  final IconButtonSize? buttonSize;
  final IconButtonWidth? buttonWidth;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  WidgetStateProperty<Color?>? get backgroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return _colors.onSurface.withOpacity(0.1);
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.primary;
      }
      if (toggleable) {
        return _colors.surfaceContainer;
      }
      return _colors.primary;
    });

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.onPrimary;
      }
      if (toggleable) {
        return _colors.onSurfaceVariant;
      }
      return _colors.onPrimary;
    });

  @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.onPrimary.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onPrimary.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onPrimary.withOpacity(0.1);
        }
      }
      if (toggleable) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.onSurfaceVariant.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onSurfaceVariant.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onSurfaceVariant.withOpacity(0.1);
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return _colors.onPrimary.withOpacity(0.1);
      }
      if (states.contains(WidgetState.hovered)) {
        return _colors.onPrimary.withOpacity(0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.onPrimary.withOpacity(0.1);
      }
      return Colors.transparent;
    });

  @override
  WidgetStateProperty<double>? get elevation =>
    const MaterialStatePropertyAll<double>(0.0);

  @override
  WidgetStateProperty<Color>? get shadowColor =>
    const MaterialStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<Color>? get surfaceTintColor =>
    const MaterialStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
    MaterialStatePropertyAll<EdgeInsetsGeometry>(switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(4.0, 6.0, 4.0, 6.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(6.0, 6.0, 6.0, 6.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(10.0, 6.0, 10.0, 6.0),
      },
      IconButtonSize.small => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(4.0, 8.0, 4.0, 8.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(8.0, 8.0, 8.0, 8.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(14.0, 8.0, 14.0, 8.0),
      },
      IconButtonSize.medium => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(12.0, 16.0, 12.0, 16.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 24.0, 16.0),
      },
      IconButtonSize.large => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(16.0, 32.0, 16.0, 32.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(32.0, 32.0, 32.0, 32.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(48.0, 32.0, 48.0, 32.0),
      },
      IconButtonSize.xLarge => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(32.0, 48.0, 32.0, 48.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(48.0, 48.0, 48.0, 48.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(72.0, 48.0, 72.0, 48.0),
      },
    });

  @override
  WidgetStateProperty<Size>? get minimumSize =>
    MaterialStatePropertyAll<Size>(switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(28.0, 32.0),
        IconButtonWidth.standard => const Size(32.0, 32.0),
        IconButtonWidth.wide => const Size(40.0, 32.0),
      },
      IconButtonSize.small => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(32.0, 40.0),
        IconButtonWidth.standard => const Size(40.0, 40.0),
        IconButtonWidth.wide => const Size(52.0, 40.0),
      },
      IconButtonSize.medium => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(48.0, 56.0),
        IconButtonWidth.standard => const Size(56.0, 56.0),
        IconButtonWidth.wide => const Size(72.0, 56.0),
      },
      IconButtonSize.large => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(64.0, 96.0),
        IconButtonWidth.standard => const Size(96.0, 96.0),
        IconButtonWidth.wide => const Size(128.0, 96.0),
      },
      IconButtonSize.xLarge => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(104.0, 136.0),
        IconButtonWidth.standard => const Size(136.0, 136.0),
        IconButtonWidth.wide => const Size(184.0, 136.0),
      },
    });

  @override
  WidgetStateProperty<Size>? get maximumSize =>
    const MaterialStatePropertyAll<Size>(Size.infinite);

  @override
  WidgetStateProperty<double>? get iconSize =>
    MaterialStatePropertyAll<double>(switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => 20.0,
      IconButtonSize.small => 24.0,
      IconButtonSize.medium => 24.0,
      IconButtonSize.large => 32.0,
      IconButtonSize.xLarge => 40.0,
    });

  @override
  WidgetStateProperty<OutlinedBorder>? get shape =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
      IconButtonSize.small => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
      IconButtonSize.medium => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      IconButtonSize.large => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
      IconButtonSize.xLarge => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
    };
      }
      if (states.contains(WidgetState.selected)) {
        return switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      IconButtonSize.small => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      IconButtonSize.medium => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
      IconButtonSize.large => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28.0))),
      IconButtonSize.xLarge => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28.0))),
    };
      }
      return switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => const StadiumBorder(),
      IconButtonSize.small => const StadiumBorder(),
      IconButtonSize.medium => const StadiumBorder(),
      IconButtonSize.large => const StadiumBorder(),
      IconButtonSize.xLarge => const StadiumBorder(),
    };
    });


  @override
  WidgetStateProperty<BorderSide?>? get side => null;

  @override
  WidgetStateProperty<MouseCursor?>? get mouseCursor => WidgetStateMouseCursor.adaptiveClickable;

  @override
  VisualDensity? get visualDensity => VisualDensity.standard;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}

class _FilledTonalIconButtonDefaultsM3E extends ButtonStyle {
  _FilledTonalIconButtonDefaultsM3E(this.context, this.toggleable, this.buttonSize, this.buttonWidth)
    : super(
        animationDuration: kThemeChangeDuration,
        enableFeedback: true,
        alignment: Alignment.center,
      );

  final BuildContext context;
  final bool toggleable;
  final IconButtonSize? buttonSize;
  final IconButtonWidth? buttonWidth;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  WidgetStateProperty<Color?>? get backgroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return _colors.onSurface.withOpacity(0.1);
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.secondary;
      }
      if (toggleable) {
        return _colors.secondaryContainer;
      }
      return _colors.secondaryContainer;
    });

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.onSecondary;
      }
      if (toggleable) {
        return _colors.onSecondaryContainer;
      }
      return _colors.onSecondaryContainer;
    });

  @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.onSecondary.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onSecondary.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onSecondary.withOpacity(0.1);
        }
      }
      if (toggleable) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.onSecondaryContainer.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onSecondaryContainer.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onSecondaryContainer.withOpacity(0.1);
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return _colors.onSecondaryContainer.withOpacity(0.1);
      }
      if (states.contains(WidgetState.hovered)) {
        return _colors.onSecondaryContainer.withOpacity(0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.onSecondaryContainer.withOpacity(0.1);
      }
      return Colors.transparent;
    });

  @override
  WidgetStateProperty<double>? get elevation =>
    const MaterialStatePropertyAll<double>(0.0);

  @override
  WidgetStateProperty<Color>? get shadowColor =>
    const MaterialStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<Color>? get surfaceTintColor =>
    const MaterialStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
    MaterialStatePropertyAll<EdgeInsetsGeometry>(switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(4.0, 6.0, 4.0, 6.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(6.0, 6.0, 6.0, 6.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(10.0, 6.0, 10.0, 6.0),
      },
      IconButtonSize.small => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(4.0, 8.0, 4.0, 8.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(8.0, 8.0, 8.0, 8.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(14.0, 8.0, 14.0, 8.0),
      },
      IconButtonSize.medium => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(12.0, 16.0, 12.0, 16.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 24.0, 16.0),
      },
      IconButtonSize.large => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(16.0, 32.0, 16.0, 32.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(32.0, 32.0, 32.0, 32.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(48.0, 32.0, 48.0, 32.0),
      },
      IconButtonSize.xLarge => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(32.0, 48.0, 32.0, 48.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(48.0, 48.0, 48.0, 48.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(72.0, 48.0, 72.0, 48.0),
      },
    });

  @override
  WidgetStateProperty<Size>? get minimumSize =>
    MaterialStatePropertyAll<Size>(switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(28.0, 32.0),
        IconButtonWidth.standard => const Size(32.0, 32.0),
        IconButtonWidth.wide => const Size(40.0, 32.0),
      },
      IconButtonSize.small => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(32.0, 40.0),
        IconButtonWidth.standard => const Size(40.0, 40.0),
        IconButtonWidth.wide => const Size(52.0, 40.0),
      },
      IconButtonSize.medium => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(48.0, 56.0),
        IconButtonWidth.standard => const Size(56.0, 56.0),
        IconButtonWidth.wide => const Size(72.0, 56.0),
      },
      IconButtonSize.large => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(64.0, 96.0),
        IconButtonWidth.standard => const Size(96.0, 96.0),
        IconButtonWidth.wide => const Size(128.0, 96.0),
      },
      IconButtonSize.xLarge => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(104.0, 136.0),
        IconButtonWidth.standard => const Size(136.0, 136.0),
        IconButtonWidth.wide => const Size(184.0, 136.0),
      },
    });

  @override
  WidgetStateProperty<Size>? get maximumSize =>
    const MaterialStatePropertyAll<Size>(Size.infinite);

  @override
  WidgetStateProperty<double>? get iconSize =>
    MaterialStatePropertyAll<double>(switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => 20.0,
      IconButtonSize.small => 24.0,
      IconButtonSize.medium => 24.0,
      IconButtonSize.large => 32.0,
      IconButtonSize.xLarge => 40.0,
    });

  @override
  WidgetStateProperty<OutlinedBorder>? get shape =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
      IconButtonSize.small => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
      IconButtonSize.medium => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      IconButtonSize.large => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
      IconButtonSize.xLarge => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
    };
      }
      if (states.contains(WidgetState.selected)) {
        return switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      IconButtonSize.small => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      IconButtonSize.medium => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
      IconButtonSize.large => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28.0))),
      IconButtonSize.xLarge => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28.0))),
    };
      }
      return switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => const StadiumBorder(),
      IconButtonSize.small => const StadiumBorder(),
      IconButtonSize.medium => const StadiumBorder(),
      IconButtonSize.large => const StadiumBorder(),
      IconButtonSize.xLarge => const StadiumBorder(),
    };
    });


  @override
  WidgetStateProperty<BorderSide?>? get side => null;

  @override
  WidgetStateProperty<MouseCursor?>? get mouseCursor => WidgetStateMouseCursor.adaptiveClickable;

  @override
  VisualDensity? get visualDensity => VisualDensity.standard;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}

class _OutlinedIconButtonDefaultsM3E extends ButtonStyle {
  _OutlinedIconButtonDefaultsM3E(this.context, this.toggleable, this.buttonSize, this.buttonWidth)
    : super(
        animationDuration: kThemeChangeDuration,
        enableFeedback: true,
        alignment: Alignment.center,
      );

  final BuildContext context;
  final bool toggleable;
  final IconButtonSize? buttonSize;
  final IconButtonWidth? buttonWidth;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  WidgetStateProperty<Color?>? get backgroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        if (states.contains(WidgetState.selected)) {
          return _colors.onSurface.withOpacity(0.1);
        }
        return Colors.transparent;
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.inverseSurface;
      }
      return Colors.transparent;
    });

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return _colors.onSurface.withOpacity(0.38);
      }
      if (states.contains(WidgetState.selected)) {
        return _colors.onInverseSurface;
      }
      return _colors.onSurfaceVariant;
    });

  @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return _colors.onInverseSurface.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.onInverseSurface.withOpacity(0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.onInverseSurface.withOpacity(0.1);
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return _colors.onSurfaceVariant.withOpacity(0.1);
      }
      if (states.contains(WidgetState.hovered)) {
        return _colors.onSurfaceVariant.withOpacity(0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return _colors.onSurfaceVariant.withOpacity(0.1);
      }
      return Colors.transparent;
    });

  @override
  WidgetStateProperty<double>? get elevation =>
    const MaterialStatePropertyAll<double>(0.0);

  @override
  WidgetStateProperty<Color>? get shadowColor =>
    const MaterialStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<Color>? get surfaceTintColor =>
    const MaterialStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
    MaterialStatePropertyAll<EdgeInsetsGeometry>(switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(4.0, 6.0, 4.0, 6.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(6.0, 6.0, 6.0, 6.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(10.0, 6.0, 10.0, 6.0),
      },
      IconButtonSize.small => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(4.0, 8.0, 4.0, 8.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(8.0, 8.0, 8.0, 8.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(14.0, 8.0, 14.0, 8.0),
      },
      IconButtonSize.medium => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(12.0, 16.0, 12.0, 16.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 24.0, 16.0),
      },
      IconButtonSize.large => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(16.0, 32.0, 16.0, 32.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(32.0, 32.0, 32.0, 32.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(48.0, 32.0, 48.0, 32.0),
      },
      IconButtonSize.xLarge => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB(32.0, 48.0, 32.0, 48.0),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB(48.0, 48.0, 48.0, 48.0),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB(72.0, 48.0, 72.0, 48.0),
      },
    });

  @override
  WidgetStateProperty<Size>? get minimumSize =>
    MaterialStatePropertyAll<Size>(switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(28.0, 32.0),
        IconButtonWidth.standard => const Size(32.0, 32.0),
        IconButtonWidth.wide => const Size(40.0, 32.0),
      },
      IconButtonSize.small => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(32.0, 40.0),
        IconButtonWidth.standard => const Size(40.0, 40.0),
        IconButtonWidth.wide => const Size(52.0, 40.0),
      },
      IconButtonSize.medium => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(48.0, 56.0),
        IconButtonWidth.standard => const Size(56.0, 56.0),
        IconButtonWidth.wide => const Size(72.0, 56.0),
      },
      IconButtonSize.large => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(64.0, 96.0),
        IconButtonWidth.standard => const Size(96.0, 96.0),
        IconButtonWidth.wide => const Size(128.0, 96.0),
      },
      IconButtonSize.xLarge => switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(104.0, 136.0),
        IconButtonWidth.standard => const Size(136.0, 136.0),
        IconButtonWidth.wide => const Size(184.0, 136.0),
      },
    });

  @override
  WidgetStateProperty<Size>? get maximumSize =>
    const MaterialStatePropertyAll<Size>(Size.infinite);

  @override
  WidgetStateProperty<double>? get iconSize =>
    MaterialStatePropertyAll<double>(switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => 20.0,
      IconButtonSize.small => 24.0,
      IconButtonSize.medium => 24.0,
      IconButtonSize.large => 32.0,
      IconButtonSize.xLarge => 40.0,
    });

  @override
  WidgetStateProperty<OutlinedBorder>? get shape =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
      IconButtonSize.small => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
      IconButtonSize.medium => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      IconButtonSize.large => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
      IconButtonSize.xLarge => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
    };
      }
      if (states.contains(WidgetState.selected)) {
        return switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      IconButtonSize.small => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12.0))),
      IconButtonSize.medium => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
      IconButtonSize.large => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28.0))),
      IconButtonSize.xLarge => const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28.0))),
    };
      }
      return switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => const StadiumBorder(),
      IconButtonSize.small => const StadiumBorder(),
      IconButtonSize.medium => const StadiumBorder(),
      IconButtonSize.large => const StadiumBorder(),
      IconButtonSize.xLarge => const StadiumBorder(),
    };
    });


  @override
  WidgetStateProperty<BorderSide?>? get side =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return null;
      }
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(color: _colors.outlineVariant, width: switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => 1.0,
      IconButtonSize.small => 1.0,
      IconButtonSize.medium => 1.0,
      IconButtonSize.large => 2.0,
      IconButtonSize.xLarge => 3.0,
    });
      }
      return BorderSide(color: _colors.outlineVariant, width: switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => 1.0,
      IconButtonSize.small => 1.0,
      IconButtonSize.medium => 1.0,
      IconButtonSize.large => 2.0,
      IconButtonSize.xLarge => 3.0,
    });
    });

  @override
  WidgetStateProperty<MouseCursor?>? get mouseCursor => WidgetStateMouseCursor.adaptiveClickable;

  @override
  VisualDensity? get visualDensity => VisualDensity.standard;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}

// dart format on
// END GENERATED TOKEN PROPERTIES - IconButtonM3E
