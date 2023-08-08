// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class ChipTemplate extends TokenTemplate {
  const ChipTemplate(super.blockName, super.fileName, super.tokens, {
    super.colorSchemePrefix = '_colors.',
    super.textThemePrefix = '_textTheme.'
  });

  static const String tokenGroup = 'md.comp.assist-chip';
  static const String variant = '.flat';

  @override
  String generate() => '''
class _${blockName}DefaultsM3 extends ChipThemeData {
  _${blockName}DefaultsM3(this.context, this.isEnabled)
    : super(
        elevation: ${elevation("$tokenGroup$variant.container")},
        shape: ${shape("$tokenGroup.container")},
        showCheckmark: true,
      );

  final BuildContext context;
  final bool isEnabled;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  TextStyle? get labelStyle => ${textStyle("$tokenGroup.label-text")};

  @override
  MaterialStateProperty<Color?>? get color => null; // Subclasses override this getter

  @override
  Color? get shadowColor => ${colorOrTransparent("$tokenGroup.container.shadow-color")};

  @override
  Color? get surfaceTintColor => ${colorOrTransparent("$tokenGroup.container.surface-tint-layer.color")};

  @override
  Color? get checkmarkColor => ${color("$tokenGroup.with-icon.selected.icon.color")};

  @override
  Color? get deleteIconColor => ${color("$tokenGroup.with-icon.selected.icon.color")};

  @override
  BorderSide? get side => isEnabled
    ? ${border('$tokenGroup$variant.outline')}
    : ${border('$tokenGroup$variant.disabled.outline')};

  @override
  IconThemeData? get iconTheme => IconThemeData(
    color: isEnabled
      ? ${color("$tokenGroup.with-icon.icon.color")}
      : ${color("$tokenGroup.with-icon.disabled.icon.color")},
    size: ${getToken("$tokenGroup.with-icon.icon.size")},
  );

  @override
  EdgeInsetsGeometry? get padding => const EdgeInsets.all(8.0);

  /// The chip at text scale 1 starts with 8px on each side and as text scaling
  /// gets closer to 2, the label padding is linearly interpolated from 8px to 4px.
  /// Once the widget has a text scaling of 2 or higher than the label padding
  /// remains 4px.
  @override
  EdgeInsetsGeometry? get labelPadding => EdgeInsets.lerp(
    const EdgeInsets.symmetric(horizontal: 8.0),
    const EdgeInsets.symmetric(horizontal: 4.0),
    clampDouble(MediaQuery.textScalerOf(context).textScaleFactor - 1.0, 0.0, 1.0),
  )!;
}
''';
}
