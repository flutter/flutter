// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../data/button_elevated.dart';
import 'template.dart';

class ElevatedButtonTemplate extends TokenTemplate {
  const ElevatedButtonTemplate(
    super.blockName,
    super.fileName, {
    super.colorSchemePrefix = '_colors.',
  });

  @override
  String generate() =>
      '''
class _${blockName}DefaultsM3 extends ButtonStyle {
  _${blockName}DefaultsM3(this.context)
   : super(
       animationDuration: kThemeChangeDuration,
       enableFeedback: true,
       alignment: Alignment.center,
     );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  WidgetStateProperty<TextStyle?> get textStyle =>
    MaterialStatePropertyAll<TextStyle?>(Theme.of(context).textTheme.labelLarge);

  @override
  WidgetStateProperty<Color?>? get backgroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ${componentColor(TokenButtonElevated.disabledContainerColor, TokenButtonElevated.disabledContainerOpacity)};
      }
      return ${color(TokenButtonElevated.containerColor)};
    });

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ${componentColor(TokenButtonElevated.disabledLabelTextColor, TokenButtonElevated.disabledLabelTextOpacity)};
      }
      return ${color(TokenButtonElevated.labelTextColor)};
    });

  @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return ${componentColor(TokenButtonElevated.pressedStateLayerColor, TokenButtonElevated.pressedStateLayerOpacity)};
      }
      if (states.contains(WidgetState.hovered)) {
        return ${componentColor(TokenButtonElevated.hoveredStateLayerColor, TokenButtonElevated.hoveredStateLayerOpacity)};
      }
      if (states.contains(WidgetState.focused)) {
        return ${componentColor(TokenButtonElevated.focusedStateLayerColor, TokenButtonElevated.focusedStateLayerOpacity)};
      }
      return null;
    });

  @override
  WidgetStateProperty<Color>? get shadowColor =>
    MaterialStatePropertyAll<Color>(${color(TokenButtonElevated.containerShadowColor)});

  @override
  WidgetStateProperty<Color>? get surfaceTintColor =>
    const MaterialStatePropertyAll<Color>(Colors.transparent);

  @override
  WidgetStateProperty<double>? get elevation =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ${TokenButtonElevated.disabledContainerElevation};
      }
      if (states.contains(WidgetState.pressed)) {
        return ${TokenButtonElevated.pressedContainerElevation};
      }
      if (states.contains(WidgetState.focused)) {
        return ${TokenButtonElevated.focusedContainerElevation};
      }
      return ${TokenButtonElevated.containerElevation};
    });

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
    MaterialStatePropertyAll<EdgeInsetsGeometry>(_scaledPadding(context));

  @override
  WidgetStateProperty<Size>? get minimumSize =>
    const MaterialStatePropertyAll<Size>(Size(64.0, 40.0));

  // No default fixedSize

  @override
  WidgetStateProperty<double>? get iconSize =>
    const MaterialStatePropertyAll<double>(18.0);

  @override
  WidgetStateProperty<Color>? get iconColor {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ${componentColor(TokenButtonElevated.disabledIconColor, TokenButtonElevated.disabledIconOpacity)};
      }
      if (states.contains(WidgetState.pressed)) {
        return ${color(TokenButtonElevated.pressedIconColor)};
      }
      if (states.contains(WidgetState.hovered)) {
        return ${color(TokenButtonElevated.hoveredIconColor)};
      }
      if (states.contains(WidgetState.focused)) {
        return ${color(TokenButtonElevated.focusedIconColor)};
      }
      return ${color(TokenButtonElevated.iconColor)};
    });
  }

  @override
  WidgetStateProperty<Size>? get maximumSize =>
    const MaterialStatePropertyAll<Size>(Size.infinite);

  // No default side

  @override
  WidgetStateProperty<OutlinedBorder>? get shape =>
    const MaterialStatePropertyAll<OutlinedBorder>(StadiumBorder());

  @override
  WidgetStateProperty<MouseCursor?>? get mouseCursor => WidgetStateMouseCursor.adaptiveClickable;

  @override
  VisualDensity? get visualDensity => Theme.of(context).visualDensity;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}
''';
}
