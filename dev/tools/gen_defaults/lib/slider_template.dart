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
  _${blockName}DefaultsM3(this.context)
    : _colors = Theme.of(context).colorScheme,
      super(trackHeight: ${tokens['$tokenGroup.active.track.height']});

  final BuildContext context;
  final ColorScheme _colors;

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
  Color? get overlayColor => MaterialStateColor.resolveWith((Set<MaterialState> states) {
    if (states.contains(MaterialState.hovered)) {
      return ${componentColor('$tokenGroup.hover.state-layer')};
    }
    if (states.contains(MaterialState.focused)) {
      return ${componentColor('$tokenGroup.focus.state-layer')};
    }
    if (states.contains(MaterialState.dragged)) {
      return ${componentColor('$tokenGroup.pressed.state-layer')};
    }

    return Colors.transparent;
  });

  @override
  TextStyle? get valueIndicatorTextStyle => ${textStyle('$tokenGroup.label.label-text')}!.copyWith(
    color: ${componentColor('$tokenGroup.label.label-text')},
  );

  @override
  SliderComponentShape? get valueIndicatorShape => const DropSliderValueIndicatorShape();
}
''';

}
