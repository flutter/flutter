// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../data/icon_button_filled.dart';
import '../data/icon_button_large.dart';
import '../data/icon_button_medium.dart';
import '../data/icon_button_outlined.dart';
import '../data/icon_button_small.dart';
import '../data/icon_button_standard.dart';
import '../data/icon_button_tonal.dart';
import '../data/icon_button_xlarge.dart';
import '../data/icon_button_xsmall.dart';
import 'template.dart';

class IconButtonTemplate extends TokenTemplate {
  const IconButtonTemplate(super.blockName, super.fileName, {super.colorSchemePrefix = '_colors.'});

  @override
  String generate() {
    return '''
${_generateStandardDefaults()}
${_generateFilledDefaults()}
${_generateFilledTonalDefaults()}
${_generateOutlinedDefaults()}
''';
  }

  String _sizeSwitch({
    required String xSmall,
    required String small,
    required String medium,
    required String large,
    required String xLarge,
  }) {
    return '''
switch (buttonSize ?? IconButtonSize.small) {
      IconButtonSize.xSmall => $xSmall,
      IconButtonSize.small => $small,
      IconButtonSize.medium => $medium,
      IconButtonSize.large => $large,
      IconButtonSize.xLarge => $xLarge,
    }''';
  }

  String get _paddingSwitch {
    return _sizeSwitch(
      xSmall: _edgeInsetsSwitch(
        defaultLeading: TokenIconButtonXsmall.defaultLeadingSpace,
        defaultTrailing: TokenIconButtonXsmall.defaultTrailingSpace,
        narrowLeading: TokenIconButtonXsmall.narrowLeadingSpace,
        narrowTrailing: TokenIconButtonXsmall.narrowTrailingSpace,
        wideLeading: TokenIconButtonXsmall.wideLeadingSpace,
        wideTrailing: TokenIconButtonXsmall.wideTrailingSpace,
      ),
      small: _edgeInsetsSwitch(
        defaultLeading: TokenIconButtonSmall.defaultLeadingSpace,
        defaultTrailing: TokenIconButtonSmall.defaultTrailingSpace,
        narrowLeading: TokenIconButtonSmall.narrowLeadingSpace,
        narrowTrailing: TokenIconButtonSmall.narrowTrailingSpace,
        wideLeading: TokenIconButtonSmall.wideLeadingSpace,
        wideTrailing: TokenIconButtonSmall.wideTrailingSpace,
      ),
      medium: _edgeInsetsSwitch(
        defaultLeading: TokenIconButtonMedium.defaultLeadingSpace,
        defaultTrailing: TokenIconButtonMedium.defaultTrailingSpace,
        narrowLeading: TokenIconButtonMedium.narrowLeadingSpace,
        narrowTrailing: TokenIconButtonMedium.narrowTrailingSpace,
        wideLeading: TokenIconButtonMedium.wideLeadingSpace,
        wideTrailing: TokenIconButtonMedium.wideTrailingSpace,
      ),
      large: _edgeInsetsSwitch(
        defaultLeading: TokenIconButtonLarge.defaultLeadingSpace,
        defaultTrailing: TokenIconButtonLarge.defaultTrailingSpace,
        narrowLeading: TokenIconButtonLarge.narrowLeadingSpace,
        narrowTrailing: TokenIconButtonLarge.narrowTrailingSpace,
        wideLeading: TokenIconButtonLarge.wideLeadingSpace,
        wideTrailing: TokenIconButtonLarge.wideTrailingSpace,
      ),
      xLarge: _edgeInsetsSwitch(
        defaultLeading: TokenIconButtonXlarge.defaultLeadingSpace,
        defaultTrailing: TokenIconButtonXlarge.defaultTrailingSpace,
        narrowLeading: TokenIconButtonXlarge.narrowLeadingSpace,
        narrowTrailing: TokenIconButtonXlarge.narrowTrailingSpace,
        wideLeading: TokenIconButtonXlarge.wideLeadingSpace,
        wideTrailing: TokenIconButtonXlarge.wideTrailingSpace,
      ),
    );
  }

  String _edgeInsetsSwitch({
    required double defaultLeading,
    required double defaultTrailing,
    required double narrowLeading,
    required double narrowTrailing,
    required double wideLeading,
    required double wideTrailing,
  }) {
    return '''
switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const EdgeInsetsDirectional.fromSTEB($narrowLeading, $defaultLeading, $narrowTrailing, $defaultTrailing),
        IconButtonWidth.standard => const EdgeInsetsDirectional.fromSTEB($defaultLeading, $defaultLeading, $defaultTrailing, $defaultTrailing),
        IconButtonWidth.wide => const EdgeInsetsDirectional.fromSTEB($wideLeading, $defaultLeading, $wideTrailing, $defaultTrailing),
      }''';
  }

  String get _minimumSizeSwitch {
    return _sizeSwitch(
      xSmall: _minimumSizeWidthSwitch(
        iconSize: TokenIconButtonXsmall.iconSize,
        height: TokenIconButtonXsmall.containerHeight,
        defaultLeading: TokenIconButtonXsmall.defaultLeadingSpace,
        defaultTrailing: TokenIconButtonXsmall.defaultTrailingSpace,
        narrowLeading: TokenIconButtonXsmall.narrowLeadingSpace,
        narrowTrailing: TokenIconButtonXsmall.narrowTrailingSpace,
        wideLeading: TokenIconButtonXsmall.wideLeadingSpace,
        wideTrailing: TokenIconButtonXsmall.wideTrailingSpace,
      ),
      small: _minimumSizeWidthSwitch(
        iconSize: TokenIconButtonSmall.iconSize,
        height: TokenIconButtonSmall.containerHeight,
        defaultLeading: TokenIconButtonSmall.defaultLeadingSpace,
        defaultTrailing: TokenIconButtonSmall.defaultTrailingSpace,
        narrowLeading: TokenIconButtonSmall.narrowLeadingSpace,
        narrowTrailing: TokenIconButtonSmall.narrowTrailingSpace,
        wideLeading: TokenIconButtonSmall.wideLeadingSpace,
        wideTrailing: TokenIconButtonSmall.wideTrailingSpace,
      ),
      medium: _minimumSizeWidthSwitch(
        iconSize: TokenIconButtonMedium.iconSize,
        height: TokenIconButtonMedium.containerHeight,
        defaultLeading: TokenIconButtonMedium.defaultLeadingSpace,
        defaultTrailing: TokenIconButtonMedium.defaultTrailingSpace,
        narrowLeading: TokenIconButtonMedium.narrowLeadingSpace,
        narrowTrailing: TokenIconButtonMedium.narrowTrailingSpace,
        wideLeading: TokenIconButtonMedium.wideLeadingSpace,
        wideTrailing: TokenIconButtonMedium.wideTrailingSpace,
      ),
      large: _minimumSizeWidthSwitch(
        iconSize: TokenIconButtonLarge.iconSize,
        height: TokenIconButtonLarge.containerHeight,
        defaultLeading: TokenIconButtonLarge.defaultLeadingSpace,
        defaultTrailing: TokenIconButtonLarge.defaultTrailingSpace,
        narrowLeading: TokenIconButtonLarge.narrowLeadingSpace,
        narrowTrailing: TokenIconButtonLarge.narrowTrailingSpace,
        wideLeading: TokenIconButtonLarge.wideLeadingSpace,
        wideTrailing: TokenIconButtonLarge.wideTrailingSpace,
      ),
      xLarge: _minimumSizeWidthSwitch(
        iconSize: TokenIconButtonXlarge.iconSize,
        height: TokenIconButtonXlarge.containerHeight,
        defaultLeading: TokenIconButtonXlarge.defaultLeadingSpace,
        defaultTrailing: TokenIconButtonXlarge.defaultTrailingSpace,
        narrowLeading: TokenIconButtonXlarge.narrowLeadingSpace,
        narrowTrailing: TokenIconButtonXlarge.narrowTrailingSpace,
        wideLeading: TokenIconButtonXlarge.wideLeadingSpace,
        wideTrailing: TokenIconButtonXlarge.wideTrailingSpace,
      ),
    );
  }

  String _minimumSizeWidthSwitch({
    required double iconSize,
    required double height,
    required double defaultLeading,
    required double defaultTrailing,
    required double narrowLeading,
    required double narrowTrailing,
    required double wideLeading,
    required double wideTrailing,
  }) {
    return '''
switch (buttonWidth ?? IconButtonWidth.standard) {
        IconButtonWidth.narrow => const Size(${iconSize + narrowLeading + narrowTrailing}, $height),
        IconButtonWidth.standard => const Size(${iconSize + defaultLeading + defaultTrailing}, $height),
        IconButtonWidth.wide => const Size(${iconSize + wideLeading + wideTrailing}, $height),
      }''';
  }

  String get _iconSizeSwitch {
    return _sizeSwitch(
      xSmall: '${TokenIconButtonXsmall.iconSize}',
      small: '${TokenIconButtonSmall.iconSize}',
      medium: '${TokenIconButtonMedium.iconSize}',
      large: '${TokenIconButtonLarge.iconSize}',
      xLarge: '${TokenIconButtonXlarge.iconSize}',
    );
  }

  String get _outlineWidthSwitch {
    return _sizeSwitch(
      xSmall: '${TokenIconButtonXsmall.outlinedOutlineWidth}',
      small: '${TokenIconButtonSmall.outlinedOutlineWidth}',
      medium: '${TokenIconButtonMedium.outlinedOutlineWidth}',
      large: '${TokenIconButtonLarge.outlinedOutlineWidth}',
      xLarge: '${TokenIconButtonXlarge.outlinedOutlineWidth}',
    );
  }

  String get _containerShapeSwitch {
    return _sizeSwitch(
      xSmall: shape(TokenIconButtonXsmall.containerShapeRound),
      small: shape(TokenIconButtonSmall.containerShapeRound),
      medium: shape(TokenIconButtonMedium.containerShapeRound),
      large: shape(TokenIconButtonLarge.containerShapeRound),
      xLarge: shape(TokenIconButtonXlarge.containerShapeRound),
    );
  }

  String get _pressedShapeSwitch {
    return _sizeSwitch(
      xSmall: shape(TokenIconButtonXsmall.pressedContainerShape),
      small: shape(TokenIconButtonSmall.pressedContainerShape),
      medium: shape(TokenIconButtonMedium.pressedContainerShape),
      large: shape(TokenIconButtonLarge.pressedContainerShape),
      xLarge: shape(TokenIconButtonXlarge.pressedContainerShape),
    );
  }

  String get _selectedShapeSwitch {
    return _sizeSwitch(
      xSmall: shape(TokenIconButtonXsmall.selectedContainerShapeRound),
      small: shape(TokenIconButtonSmall.selectedContainerShapeRound),
      medium: shape(TokenIconButtonMedium.selectedContainerShapeRound),
      large: shape(TokenIconButtonLarge.selectedContainerShapeRound),
      xLarge: shape(TokenIconButtonXlarge.selectedContainerShapeRound),
    );
  }

  String get _sizeDependentProperties {
    return '''
  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
    MaterialStatePropertyAll<EdgeInsetsGeometry>($_paddingSwitch);

  @override
  WidgetStateProperty<Size>? get minimumSize =>
    MaterialStatePropertyAll<Size>($_minimumSizeSwitch);

  @override
  WidgetStateProperty<Size>? get maximumSize =>
    const MaterialStatePropertyAll<Size>(Size.infinite);

  @override
  WidgetStateProperty<double>? get iconSize =>
    MaterialStatePropertyAll<double>($_iconSizeSwitch);

  @override
  WidgetStateProperty<OutlinedBorder>? get shape =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return $_pressedShapeSwitch;
      }
      if (states.contains(WidgetState.selected)) {
        return $_selectedShapeSwitch;
      }
      return $_containerShapeSwitch;
    });
''';
  }

  String _generateStandardDefaults() {
    return '''
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
        return ${componentColor(TokenIconButtonStandard.disabledIconColor, TokenIconButtonStandard.disabledIconOpacity)};
      }
      if (states.contains(WidgetState.selected)) {
        return ${color(TokenIconButtonStandard.selectedIconColor)};
      }
      return ${color(TokenIconButtonStandard.iconColor)};
    });

  @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return ${componentColor(TokenIconButtonStandard.selectedPressedStateLayerColor, TokenIconButtonStandard.pressedStateLayerOpacity)};
        }
        if (states.contains(WidgetState.hovered)) {
          return ${componentColor(TokenIconButtonStandard.selectedHoveredStateLayerColor, TokenIconButtonStandard.hoveredStateLayerOpacity)};
        }
        if (states.contains(WidgetState.focused)) {
          return ${componentColor(TokenIconButtonStandard.selectedFocusedStateLayerColor, TokenIconButtonStandard.focusedStateLayerOpacity)};
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return ${componentColor(TokenIconButtonStandard.pressedStateLayerColor, TokenIconButtonStandard.pressedStateLayerOpacity)};
      }
      if (states.contains(WidgetState.hovered)) {
        return ${componentColor(TokenIconButtonStandard.hoveredStateLayerColor, TokenIconButtonStandard.hoveredStateLayerOpacity)};
      }
      if (states.contains(WidgetState.focused)) {
        return ${componentColor(TokenIconButtonStandard.focusedStateLayerColor, TokenIconButtonStandard.focusedStateLayerOpacity)};
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

$_sizeDependentProperties

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
''';
  }

  String _generateFilledDefaults() {
    return '''
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
        return ${componentColor(TokenIconButtonFilled.disabledContainerColor, TokenIconButtonFilled.disabledContainerOpacity)};
      }
      if (states.contains(WidgetState.selected)) {
        return ${color(TokenIconButtonFilled.selectedContainerColor)};
      }
      if (toggleable) {
        return ${color(TokenIconButtonFilled.unselectedContainerColor)};
      }
      return ${color(TokenIconButtonFilled.containerColor)};
    });

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ${componentColor(TokenIconButtonFilled.disabledIconColor, TokenIconButtonFilled.disabledIconOpacity)};
      }
      if (states.contains(WidgetState.selected)) {
        return ${color(TokenIconButtonFilled.selectedIconColor)};
      }
      if (toggleable) {
        return ${color(TokenIconButtonFilled.unselectedIconColor)};
      }
      return ${color(TokenIconButtonFilled.iconColor)};
    });

  @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return ${componentColor(TokenIconButtonFilled.selectedPressedStateLayerColor, TokenIconButtonFilled.pressedStateLayerOpacity)};
        }
        if (states.contains(WidgetState.hovered)) {
          return ${componentColor(TokenIconButtonFilled.selectedHoveredStateLayerColor, TokenIconButtonFilled.hoveredStateLayerOpacity)};
        }
        if (states.contains(WidgetState.focused)) {
          return ${componentColor(TokenIconButtonFilled.selectedFocusedStateLayerColor, TokenIconButtonFilled.focusedStateLayerOpacity)};
        }
      }
      if (toggleable) {
        if (states.contains(WidgetState.pressed)) {
          return ${componentColor(TokenIconButtonFilled.unselectedPressedStateLayerColor, TokenIconButtonFilled.pressedStateLayerOpacity)};
        }
        if (states.contains(WidgetState.hovered)) {
          return ${componentColor(TokenIconButtonFilled.unselectedHoveredStateLayerColor, TokenIconButtonFilled.hoveredStateLayerOpacity)};
        }
        if (states.contains(WidgetState.focused)) {
          return ${componentColor(TokenIconButtonFilled.unselectedFocusedStateLayerColor, TokenIconButtonFilled.focusedStateLayerOpacity)};
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return ${componentColor(TokenIconButtonFilled.pressedStateLayerColor, TokenIconButtonFilled.pressedStateLayerOpacity)};
      }
      if (states.contains(WidgetState.hovered)) {
        return ${componentColor(TokenIconButtonFilled.hoveredStateLayerColor, TokenIconButtonFilled.hoveredStateLayerOpacity)};
      }
      if (states.contains(WidgetState.focused)) {
        return ${componentColor(TokenIconButtonFilled.focusedStateLayerColor, TokenIconButtonFilled.focusedStateLayerOpacity)};
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

$_sizeDependentProperties

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
''';
  }

  String _generateFilledTonalDefaults() {
    return '''
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
        return ${componentColor(TokenIconButtonTonal.disabledContainerColor, TokenIconButtonTonal.disabledContainerOpacity)};
      }
      if (states.contains(WidgetState.selected)) {
        return ${color(TokenIconButtonTonal.selectedContainerColor)};
      }
      if (toggleable) {
        return ${color(TokenIconButtonTonal.unselectedContainerColor)};
      }
      return ${color(TokenIconButtonTonal.containerColor)};
    });

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ${componentColor(TokenIconButtonTonal.disabledIconColor, TokenIconButtonTonal.disabledIconOpacity)};
      }
      if (states.contains(WidgetState.selected)) {
        return ${color(TokenIconButtonTonal.selectedIconColor)};
      }
      if (toggleable) {
        return ${color(TokenIconButtonTonal.unselectedIconColor)};
      }
      return ${color(TokenIconButtonTonal.iconColor)};
    });

  @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return ${componentColor(TokenIconButtonTonal.selectedPressedStateLayerColor, TokenIconButtonTonal.pressedStateLayerOpacity)};
        }
        if (states.contains(WidgetState.hovered)) {
          return ${componentColor(TokenIconButtonTonal.selectedHoveredStateLayerColor, TokenIconButtonTonal.hoveredStateLayerOpacity)};
        }
        if (states.contains(WidgetState.focused)) {
          return ${componentColor(TokenIconButtonTonal.selectedFocusedStateLayerColor, TokenIconButtonTonal.focusedStateLayerOpacity)};
        }
      }
      if (toggleable) {
        if (states.contains(WidgetState.pressed)) {
          return ${componentColor(TokenIconButtonTonal.unselectedPressedStateLayerColor, TokenIconButtonTonal.pressedStateLayerOpacity)};
        }
        if (states.contains(WidgetState.hovered)) {
          return ${componentColor(TokenIconButtonTonal.unselectedHoveredStateLayerColor, TokenIconButtonTonal.hoveredStateLayerOpacity)};
        }
        if (states.contains(WidgetState.focused)) {
          return ${componentColor(TokenIconButtonTonal.unselectedFocusedStateLayerColor, TokenIconButtonTonal.focusedStateLayerOpacity)};
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return ${componentColor(TokenIconButtonTonal.pressedStateLayerColor, TokenIconButtonTonal.pressedStateLayerOpacity)};
      }
      if (states.contains(WidgetState.hovered)) {
        return ${componentColor(TokenIconButtonTonal.hoveredStateLayerColor, TokenIconButtonTonal.hoveredStateLayerOpacity)};
      }
      if (states.contains(WidgetState.focused)) {
        return ${componentColor(TokenIconButtonTonal.focusedStateLayerColor, TokenIconButtonTonal.focusedStateLayerOpacity)};
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

$_sizeDependentProperties

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
''';
  }

  String _generateOutlinedDefaults() {
    return '''
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
          return ${componentColor(TokenIconButtonOutlined.selectedDisabledContainerColor, TokenIconButtonOutlined.selectedDisabledContainerOpacity)};
        }
        return Colors.transparent;
      }
      if (states.contains(WidgetState.selected)) {
        return ${color(TokenIconButtonOutlined.selectedContainerColor)};
      }
      return Colors.transparent;
    });

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ${componentColor(TokenIconButtonOutlined.disabledIconColor, TokenIconButtonOutlined.disabledIconOpacity)};
      }
      if (states.contains(WidgetState.selected)) {
        return ${color(TokenIconButtonOutlined.selectedIconColor)};
      }
      return ${color(TokenIconButtonOutlined.iconColor)};
    });

  @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return ${componentColor(TokenIconButtonOutlined.selectedPressedStateLayerColor, TokenIconButtonOutlined.pressedStateLayerOpacity)};
        }
        if (states.contains(WidgetState.hovered)) {
          return ${componentColor(TokenIconButtonOutlined.selectedHoveredStateLayerColor, TokenIconButtonOutlined.hoveredStateLayerOpacity)};
        }
        if (states.contains(WidgetState.focused)) {
          return ${componentColor(TokenIconButtonOutlined.selectedFocusedStateLayerColor, TokenIconButtonOutlined.focusedStateLayerOpacity)};
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return ${componentColor(TokenIconButtonOutlined.pressedStateLayerColor, TokenIconButtonOutlined.pressedStateLayerOpacity)};
      }
      if (states.contains(WidgetState.hovered)) {
        return ${componentColor(TokenIconButtonOutlined.hoveredStateLayerColor, TokenIconButtonOutlined.hoveredStateLayerOpacity)};
      }
      if (states.contains(WidgetState.focused)) {
        return ${componentColor(TokenIconButtonOutlined.focusedStateLayerColor, TokenIconButtonOutlined.focusedStateLayerOpacity)};
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

$_sizeDependentProperties

  @override
  WidgetStateProperty<BorderSide?>? get side =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return null;
      }
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(color: ${color(TokenIconButtonOutlined.unselectedDisabledOutlineColor)}, width: $_outlineWidthSwitch);
      }
      return BorderSide(color: ${color(TokenIconButtonOutlined.outlineColor)}, width: $_outlineWidthSwitch);
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
''';
  }
}
