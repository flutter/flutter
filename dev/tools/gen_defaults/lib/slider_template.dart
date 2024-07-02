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
  _${blockName}DefaultsM3({ required this.context });

  final BuildContext context;
  late final ThemeData theme = Theme.of(context);
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  Color? get activeTrackColor => ${componentColor('$tokenGroup.active.track')};

  @override
  Color? get inactiveTrackColor => ${componentColor('$tokenGroup.inactive.track')};

  @override
  Color? get secondaryActiveTrackColor => _colors.primary.withOpacity(0.54);

  @override
  Color? get disabledActiveTrackColor => ${componentColor('$tokenGroup.disabled.active.track')};

  @override
  Color? get disabledInactiveTrackColor => ${componentColor('$tokenGroup.disabled.inactive.track')};

  @override
  Color? get disabledSecondaryActiveTrackColor => _colors.onSurface.withOpacity(0.12);

  @override
  Color? get activeTickMarkColor => _colors.${getToken("$tokenGroup.disabled.stop-indicator.color-selected")};

  @override
  // TODO(tahatesser): Update this hard-coded value to use the correct token value.
  Color? get inactiveTickMarkColor => _colors.primary;

  @override
  Color? get disabledActiveTickMarkColor => ${componentColor('$tokenGroup.disabled.stop-indicator')};

  @override
  Color? get disabledInactiveTickMarkColor => ${componentColor('$tokenGroup.disabled.stop-indicator')};

  @override
  Color? get thumbColor => ${componentColor('$tokenGroup.handle')};

  @override
  Color? get disabledThumbColor => Color.alphaBlend(${componentColor('$tokenGroup.disabled.handle')}, _colors.surface);

  @override
  Color? get overlayColor => Colors.transparent;

  @override
  TextStyle? get valueIndicatorTextStyle => ${textStyle('$tokenGroup.value-indicator.label.label-text')}!.copyWith(
    color: ${componentColor('$tokenGroup.label.label-text')},
  );

  @override
  SliderComponentShape? get valueIndicatorShape => const RoundedRectSliderValueIndicatorShape();

  @override
  SliderComponentShape? get thumbShape => const BarSliderThumbShape();

  @override
  SliderTrackShape? get trackShape => const GappedSliderTrackShape();

  @override
  SliderComponentShape? get overlayShape => const RoundSliderOverlayShape();

  @override
  SliderTickMarkShape? get tickMarkShape => const RoundSliderTickMarkShape(tickMarkRadius: ${getToken("$tokenGroup.stop-indicator.size")} / 2);

  @override
  Color? get valueIndicatorColor => ${componentColor('$tokenGroup.value-indicator.container')};

  @override
  double? get trackHeight => ${getToken("$tokenGroup.active.track.height")};

  @override
  MaterialStateProperty<Size?>? get barThumbSize =>
    MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.pressed)) {
        return const Size(${getToken("$tokenGroup.pressed.handle.width")}, ${getToken("$tokenGroup.handle.height")});
      }
      return const Size(${getToken("$tokenGroup.handle.width")}, ${getToken("$tokenGroup.handle.height")});
    });

  @override
  // TODO(tahatesser): Update this hard-coded value to use the token value when it is available.
  double? get trackGapSize => 6.0;
}
''';

}
