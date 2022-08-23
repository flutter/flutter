// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class IconButtonTemplate extends TokenTemplate {
  const IconButtonTemplate(super.blockName, super.fileName, super.tokens, {
    super.colorSchemePrefix = '_colors.',
  });

  @override
  String generate() => '''
class _${blockName}DefaultsM3 extends ButtonStyle {
  _${blockName}DefaultsM3(this.context)
    : super(
        animationDuration: kThemeChangeDuration,
        enableFeedback: true,
        alignment: Alignment.center,
      );

    final BuildContext context;
    late final ColorScheme _colors = Theme.of(context).colorScheme;

  // No default text style

  @override
  MaterialStateProperty<Color?>? get backgroundColor =>
    ButtonStyleButton.allOrNull<Color>(Colors.transparent);

  @override
  MaterialStateProperty<Color?>? get foregroundColor =>
    MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return ${componentColor('md.comp.icon-button.disabled.icon')};
      }
      if (states.contains(MaterialState.selected)) {
        return ${componentColor('md.comp.icon-button.selected.icon')};
      }
      return ${componentColor('md.comp.icon-button.unselected.icon')};
    });

 @override
  MaterialStateProperty<Color?>? get overlayColor =>
    MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        if (states.contains(MaterialState.hovered)) {
          return ${componentColor('md.comp.icon-button.selected.hover.state-layer')};
        }
        if (states.contains(MaterialState.focused)) {
          return ${componentColor('md.comp.icon-button.selected.focus.state-layer')};
        }
        if (states.contains(MaterialState.pressed)) {
          return ${componentColor('md.comp.icon-button.selected.pressed.state-layer')};
        }
      }
      if (states.contains(MaterialState.hovered)) {
        return ${componentColor('md.comp.icon-button.unselected.hover.state-layer')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${componentColor('md.comp.icon-button.unselected.focus.state-layer')};
      }
      if (states.contains(MaterialState.pressed)) {
        return ${componentColor('md.comp.icon-button.unselected.pressed.state-layer')};
      }
      return null;
    });

  // No default shadow color

  // No default surface tint color

  @override
  MaterialStateProperty<double>? get elevation =>
    ButtonStyleButton.allOrNull<double>(0.0);

  @override
  MaterialStateProperty<EdgeInsetsGeometry>? get padding =>
    ButtonStyleButton.allOrNull<EdgeInsetsGeometry>(const EdgeInsets.all(8.0));

  @override
  MaterialStateProperty<Size>? get minimumSize =>
    ButtonStyleButton.allOrNull<Size>(const Size(${tokens["md.comp.icon-button.state-layer.size"]}, ${tokens["md.comp.icon-button.state-layer.size"]}));

  // No default fixedSize

  @override
  MaterialStateProperty<Size>? get maximumSize =>
    ButtonStyleButton.allOrNull<Size>(Size.infinite);

  @override
  MaterialStateProperty<double>? get iconSize =>
    ButtonStyleButton.allOrNull<double>(${tokens["md.comp.icon-button.icon.size"]});

  // No default side

  @override
  MaterialStateProperty<OutlinedBorder>? get shape =>
    ButtonStyleButton.allOrNull<OutlinedBorder>(${shape("md.comp.icon-button.state-layer")});

  @override
  MaterialStateProperty<MouseCursor?>? get mouseCursor =>
    MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return SystemMouseCursors.basic;
      }
      return SystemMouseCursors.click;
    });

  @override
  VisualDensity? get visualDensity => VisualDensity.standard;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}
''';

}
