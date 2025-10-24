// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class ButtonTemplate extends TokenTemplate {
  const ButtonTemplate(
    this.tokenGroup,
    super.blockName,
    super.fileName,
    super.tokens, {
    super.colorSchemePrefix = '_colors.',
  });

  final String tokenGroup;

  String _backgroundColor() {
    if (tokenAvailable('$tokenGroup.container.color')) {
      return '''

    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ${componentColor('$tokenGroup.disabled.container')};
      }
      return ${componentColor('$tokenGroup.container')};
    })''';
    }
    return '''

    const MaterialStatePropertyAll<Color>(Colors.transparent)''';
  }

  String _elevation() {
    if (tokenAvailable('$tokenGroup.container.elevation')) {
      return '''

    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ${elevation("$tokenGroup.disabled.container")};
      }
      if (states.contains(WidgetState.pressed)) {
        return ${elevation("$tokenGroup.pressed.container")};
      }
      if (states.contains(WidgetState.hovered)) {
        return ${elevation("$tokenGroup.hover.container")};
      }
      if (states.contains(WidgetState.focused)) {
        return ${elevation("$tokenGroup.focus.container")};
      }
      return ${elevation("$tokenGroup.container")};
    })''';
    }
    return '''

    const MaterialStatePropertyAll<double>(0.0)''';
  }

  String _elevationColor(String token) {
    if (tokenAvailable(token)) {
      return 'MaterialStatePropertyAll<Color>(${color(token)})';
    } else {
      return 'const MaterialStatePropertyAll<Color>(Colors.transparent)';
    }
  }

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
    MaterialStatePropertyAll<TextStyle?>(${textStyle("$tokenGroup.label-text")});

  @override
  WidgetStateProperty<Color?>? get backgroundColor =>${_backgroundColor()};

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ${componentColor('$tokenGroup.disabled.label-text')};
      }
      return ${componentColor('$tokenGroup.label-text')};
    });

  @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return ${componentColor('$tokenGroup.pressed.state-layer')};
      }
      if (states.contains(WidgetState.hovered)) {
        return ${componentColor('$tokenGroup.hover.state-layer')};
      }
      if (states.contains(WidgetState.focused)) {
        return ${componentColor('$tokenGroup.focus.state-layer')};
      }
      return null;
    });

  @override
  WidgetStateProperty<Color>? get shadowColor =>
    ${_elevationColor("$tokenGroup.container.shadow-color")};

  @override
  WidgetStateProperty<Color>? get surfaceTintColor =>
    ${_elevationColor("$tokenGroup.container.surface-tint-layer.color")};

  @override
  WidgetStateProperty<double>? get elevation =>${_elevation()};

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
    MaterialStatePropertyAll<EdgeInsetsGeometry>(_scaledPadding(context));

  @override
  WidgetStateProperty<Size>? get minimumSize =>
    const MaterialStatePropertyAll<Size>(Size(64.0, ${getToken("$tokenGroup.container.height")}));

  // No default fixedSize

  @override
  WidgetStateProperty<double>? get iconSize =>
    const MaterialStatePropertyAll<double>(${getToken("$tokenGroup.with-icon.icon.size")});

  @override
  WidgetStateProperty<Color>? get iconColor {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ${color('$tokenGroup.with-icon.disabled.icon.color')}.withOpacity(${opacity("$tokenGroup.with-icon.disabled.icon.opacity")});
      }
      if (states.contains(WidgetState.pressed)) {
        return ${color('$tokenGroup.with-icon.pressed.icon.color')};
      }
      if (states.contains(WidgetState.hovered)) {
        return ${color('$tokenGroup.with-icon.hover.icon.color')};
      }
      if (states.contains(WidgetState.focused)) {
        return ${color('$tokenGroup.with-icon.focus.icon.color')};
      }
      return ${color('$tokenGroup.with-icon.icon.color')};
    });
  }

  @override
  WidgetStateProperty<Size>? get maximumSize =>
    const MaterialStatePropertyAll<Size>(Size.infinite);

${tokenAvailable("$tokenGroup.outline.color") ? '''
  @override
  WidgetStateProperty<BorderSide>? get side =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return ${border("$tokenGroup.disabled.outline")};
    }
    if (states.contains(WidgetState.focused)) {
      return ${border('$tokenGroup.focus.outline')};
    }
    return ${border("$tokenGroup.outline")};
  });''' : '''
  // No default side'''}

  @override
  WidgetStateProperty<OutlinedBorder>? get shape =>
    const MaterialStatePropertyAll<OutlinedBorder>(${shape("$tokenGroup.container", '')});

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
