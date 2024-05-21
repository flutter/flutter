// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class SliderTemplate extends TokenTemplate {
  const SliderTemplate(this.tokenGroup, super.blockName, super.fileName, super.tokens, {
    super.colorSchemePrefix = '_colors.',
  });

  final String tokenGroup;

  @override
  String generate() => '''
class _${blockName}DefaultsM3 extends SliderThemeData {
  _${blockName}DefaultsM3({ required this.context, required SliderThemeData sliderTheme })
    : _sliderTheme = sliderTheme;

  final BuildContext context;
  late final ThemeData theme = Theme.of(context);
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  final SliderThemeData _sliderTheme;
  late final bool newShapes = _sliderTheme.use2024SliderShapes ?? false;

  @override
  Color? get activeTrackColor => ${componentColor('$tokenGroup.active.track')};

  @override
  Color? get inactiveTrackColor {
    if (_sliderTheme.trackShape is ExpressiveRoundedRectSliderTrackShape || newShapes) {
      // TODO(tahatesser): Update this hard-coded value to use the latest tokens.
      return _colors.secondaryContainer;
    }
    return ${componentColor('$tokenGroup.inactive.track')};
  }

  @override
  Color? get secondaryActiveTrackColor => _colors.primary.withOpacity(0.54);

  @override
  Color? get disabledActiveTrackColor => ${componentColor('$tokenGroup.disabled.active.track')};

  @override
  Color? get disabledInactiveTrackColor => ${componentColor('$tokenGroup.disabled.inactive.track')};

  @override
  Color? get disabledSecondaryActiveTrackColor => _colors.onSurface.withOpacity(0.12);

  @override
  Color? get activeTickMarkColor => ${componentColor('$tokenGroup.with-tick-marks.active.container')};

  @override
  Color? get inactiveTickMarkColor => ${componentColor('$tokenGroup.with-tick-marks.inactive.container')};

  @override
  Color? get disabledActiveTickMarkColor => ${componentColor('$tokenGroup.with-tick-marks.disabled.container')};

  @override
  Color? get disabledInactiveTickMarkColor => ${componentColor('$tokenGroup.with-tick-marks.disabled.container')};

  @override
  Color? get thumbColor => ${componentColor('$tokenGroup.handle')};

  @override
  Color? get disabledThumbColor => Color.alphaBlend(${componentColor('$tokenGroup.disabled.handle')}, _colors.surface);

  @override
  Color? get overlayColor {
    if ((_sliderTheme.thumbShape is BarSliderThumbShape || newShapes) && theme.brightness != Brightness.dark) {
      // TODO(tahatesser): Update this hard-coded value to use the latest tokens.
      return Colors.transparent;
    }
    return MaterialStateColor.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.dragged)) {
        return ${componentColor('$tokenGroup.pressed.state-layer')};
      }
      if (states.contains(MaterialState.hovered)) {
        return ${componentColor('$tokenGroup.hover.state-layer')};
      }
      if (states.contains(MaterialState.focused)) {
        return ${componentColor('$tokenGroup.focus.state-layer')};
      }

      return Colors.transparent;
    });
  }

  @override
  TextStyle? get valueIndicatorTextStyle => ${textStyle('$tokenGroup.label.label-text')}!.copyWith(
    // TODO(tahatesser): Update this hard-coded value to use the latest tokens.
    color:  _sliderTheme.valueIndicatorShape is RoundedRectSliderValueIndicatorShape || newShapes
      ? _colors.onInverseSurface
      : ${componentColor('$tokenGroup.label.label-text')},
  );

  @override
  SliderComponentShape? get valueIndicatorShape => const DropSliderValueIndicatorShape();

  @override
  Color? get valueIndicatorColor {
    // TODO(tahatesser): Update this hard-coded value to use the latest tokens.
    if (_sliderTheme.valueIndicatorShape is RoundedRectSliderValueIndicatorShape || newShapes) {
      return _colors.inverseSurface;
    }
    return ${componentColor('$tokenGroup.label.container')};
  }

  @override
  double? get trackHeight => _sliderTheme.trackShape is ExpressiveRoundedRectSliderTrackShape || newShapes
    // TODO(tahatesser): Update this hard-coded value to use the latest tokens.
    ? 16.0
    : ${getToken("$tokenGroup.active.track.height")};

  // TODO(tahatesser): Update this hard-coded value to use the latest tokens.
  @override
  Size? get barThumbSize => const Size(4.0, 44.0);

  // TODO(tahatesser): Update this hard-coded value to use the latest tokens.
  @override
  double? get trackGapSize => 6.0;
}
''';

}
