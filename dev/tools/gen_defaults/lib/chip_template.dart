// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class ChipTemplate extends TokenTemplate {
  const ChipTemplate(super.fileName, super.tokens);

  @override
  String generate() => '''
// Generated version ${tokens["version"]}
class _TokenDefaultsM3 extends ChipThemeData {
  const _TokenDefaultsM3(this.context, bool elevated)
    : super(
        elevation: ${elevation("md.comp.filter-chip.flat.container")},
        pressElevation: elevated
          ? ${elevation("md.comp.filter-chip.elevated.pressed.container")}
          : ${elevation("md.comp.filter-chip.flat.selected.pressed.container")},
        shape: ${shape("md.comp.filter-chip.container")},
        showCheckmark: true,
      );

  final BuildContext context;

  @override
  TextStyle? get labelStyle => ${textStyle("md.comp.filter-chip.label-text")};

  @override
  Color? get backgroundColor => const Color(0x00000000);

  @override
  Color? get shadowColor => ${color("md.comp.filter-chip.container.shadow-color")};

  @override
  @override Color? get surfaceTintColor => ${color("md.comp.navigation-bar.container.surface-tint-layer.color")};

  @override
  Color? get selectedColor => ${componentColor("md.comp.filter-chip.flat.selected.container")};

  @override
  Color? get checkmarkColor => ${color("md.comp.filter-chip.with-icon.selected.icon.color")};

  @override
  Color? get disabledColor => ${color("md.comp.filter-chip.elevated.disabled.container.color")};

  @override
  Color? get deleteIconColor => ${color("md.comp.filter-chip.with-icon.selected.icon.color")};

  @override
  BorderSide? get side => ${border("md.comp.suggestion-chip.flat.outline")};

  @override
  EdgeInsetsGeometry? get padding => const EdgeInsets.all(4.0);

  /// The chip at text scale 1 starts with 8px on each side and as text scaling
  /// gets closer to 2 the label padding is linearly interpolated from 8px to 4px.
  /// Once the widget has a text scaling of 2 or higher than the label padding
  /// remains 4px.
  @override
  EdgeInsetsGeometry? get labelPadding => EdgeInsets.lerp(
    const EdgeInsets.symmetric(horizontal: 8.0),
    const EdgeInsets.symmetric(horizontal: 4.0),
    clampDouble(MediaQuery.of(context).textScaleFactor - 1.0, 0.0, 1.0),
  )!;
}
''';
}
