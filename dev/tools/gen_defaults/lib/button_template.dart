// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class ButtonTemplate extends TokenTemplate {
  const ButtonTemplate(this.tokenGroup, String fileName, Map<String, dynamic> tokens)
    : super(fileName, tokens,
        colorSchemePrefix: '_colors.',
      );

  final String tokenGroup;

  String get _backgroundColor {
    if (tokens.containsKey('$tokenGroup.container.color')) {
      final String enabledColor = color('$tokenGroup.container.color');
      final String? enabledOpacity = opacity('$tokenGroup.container.opacity');
      final String disabledColor = color('$tokenGroup.disabled.container.color');
      final String? disabledOpacity = opacity('$tokenGroup.disabled.container.opacity');
      return '''
  static MaterialStateProperty<Color?>? backgroundColorFor(Color? enabled, Color? disabled) {
    return (enabled == null && disabled == null)
      ? null
      : MaterialStateProperty.resolveWith((Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled))
            return disabled${disabledOpacity != null ? '?.withOpacity($disabledOpacity)' : ''};
          return enabled${enabledOpacity != null ? '?.withOpacity($enabledOpacity)' : ''};
        });
  }

  @override
  MaterialStateProperty<Color?>? get backgroundColor {
    return backgroundColorFor($enabledColor, $disabledColor);
  }''';
    } else {
      return '''
  @override
  MaterialStateProperty<Color?>? get backgroundColor {
    return ButtonStyleButton.allOrNull<Color>(Colors.transparent);
  }''';
    }
  }

  String get _foregroundColor {
    final String enabledColor = color('$tokenGroup.label-text.color');
    final String? enabledOpacity = opacity('$tokenGroup.label-text.opacity');
    final String disabledColor = color('$tokenGroup.disabled.label-text.color');
    final String? disabledOpacity = opacity('$tokenGroup.disabled.label-text.opacity');
    return '''
  static MaterialStateProperty<Color?>? foregroundColorFor(Color? enabled, Color? disabled) {
    return (enabled == null && disabled == null)
      ? null
      : MaterialStateProperty.resolveWith((Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled))
            return disabled${disabledOpacity != null ? '?.withOpacity($disabledOpacity)' : ''};
          return enabled${enabledOpacity != null ? '?.withOpacity($enabledOpacity)' : ''};
        });
  }

  @override
  MaterialStateProperty<Color?>? get foregroundColor {
    return foregroundColorFor($enabledColor, $disabledColor);
  }''';
    }

  String get _overlayColor {
    final String hoverColor = color('$tokenGroup.hover.state-layer.color');
    final String? hoverOpacity = opacity('$tokenGroup.hover.state-layer.opacity');
    final String focusColor = color('$tokenGroup.focus.state-layer.color');
    final String? focusOpacity = opacity('$tokenGroup.focus.state-layer.opacity');
    return '''
  static MaterialStateProperty<Color?>? overlayColorFor(Color? hover, Color? focus) {
    return (hover == null && focus == null)
      ? null
      : MaterialStateProperty.resolveWith((Set<MaterialState> states) {
          if (states.contains(MaterialState.hovered))
            return hover${hoverOpacity != null ? '?.withOpacity($hoverOpacity)' : ''};
          else if (states.contains(MaterialState.focused))
            return focus${focusOpacity != null ? '?.withOpacity($focusOpacity)' : ''};
          else
            return null;
        });
  }

  @override
  MaterialStateProperty<Color?>? get overlayColor {
    return overlayColorFor($hoverColor, $focusColor);
  }''';
  }

  String get _elevation {
    if (tokens.containsKey('$tokenGroup.container.elevation')) {
      return '''
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled))
        return ${elevation("$tokenGroup.disabled.container")};
      else if (states.contains(MaterialState.hovered))
        return ${elevation("$tokenGroup.hover.container")};
      else if (states.contains(MaterialState.focused))
        return ${elevation("$tokenGroup.focus.container")};
      else if (states.contains(MaterialState.pressed))
        return ${elevation("$tokenGroup.pressed.container")};
      return ${elevation("$tokenGroup.container")};
    });''';
    }
    return '''
    return ButtonStyleButton.allOrNull<double>(0.0);''';
  }

  @override
  String generate() => '''
// Generated version ${tokens["version"]}
class _TokenDefaultsM3 extends ButtonStyle {
  _TokenDefaultsM3(this.context);

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  MaterialStateProperty<TextStyle?> get textStyle =>
    MaterialStateProperty.all<TextStyle?>(${textStyle("$tokenGroup.label-text")});

$_backgroundColor

$_foregroundColor

$_overlayColor

  @override
  MaterialStateProperty<Color>? get shadowColor =>
    ButtonStyleButton.allOrNull<Color>(${color("$tokenGroup.container.shadow-color")});

  @override
  MaterialStateProperty<Color>? get surfaceTintColor =>
    ButtonStyleButton.allOrNull<Color>(${color("$tokenGroup.container.surface-tint-layer.color")});

  @override
  MaterialStateProperty<double>? get elevation {
$_elevation
  }

  @override
  MaterialStateProperty<EdgeInsetsGeometry>? get padding {
    final EdgeInsetsGeometry scaledPadding = ButtonStyleButton.scaledPadding(
      const EdgeInsets.symmetric(horizontal: 16),
      const EdgeInsets.symmetric(horizontal: 8),
      const EdgeInsets.symmetric(horizontal: 4),
      MediaQuery.maybeOf(context)?.textScaleFactor ?? 1,
    );

    return ButtonStyleButton.allOrNull<EdgeInsetsGeometry>(scaledPadding);
  }

  @override
  MaterialStateProperty<Size>? get minimumSize =>
    ButtonStyleButton.allOrNull<Size>(const Size(64, ${tokens["$tokenGroup.container.height"]}));

  @override
  MaterialStateProperty<Size>? get fixedSize =>
    ButtonStyleButton.allOrNull<Size>(null);

  @override
  MaterialStateProperty<Size>? get maximumSize =>
    ButtonStyleButton.allOrNull<Size>(Size.infinite);

  @override
  MaterialStateProperty<BorderSide>? get side =>
    ButtonStyleButton.allOrNull<BorderSide>(${border("$tokenGroup.outline")});

  @override
  MaterialStateProperty<OutlinedBorder>? get shape =>
    ButtonStyleButton.allOrNull<OutlinedBorder>(${shape("$tokenGroup.container")});

  @override
  MaterialStateProperty<MouseCursor?>? get mouseCursor {
    return MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      if (states.contains(MaterialState.disabled)) {
        return SystemMouseCursors.basic;
      }
      return SystemMouseCursors.click;
    });
  }

  @override
  VisualDensity? get visualDensity => Theme.of(context).visualDensity;

  @override
  MaterialTapTargetSize? get tapTargetSize => Theme.of(context).materialTapTargetSize;

  @override
  Duration? get animationDuration => kThemeChangeDuration;

  @override
  bool? get enableFeedback => true;

  @override
  AlignmentGeometry? get alignment => Alignment.center;

  @override
  InteractiveInkFeatureFactory? get splashFactory => Theme.of(context).splashFactory;
}
''';
}
