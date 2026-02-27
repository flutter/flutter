// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class IconButtonTemplate extends TokenTemplate {
  const IconButtonTemplate(
    this.tokenGroup,
    super.blockName,
    super.fileName,
    super.tokens, {
    super.colorSchemePrefix = '_colors.',
  });

  final String tokenGroup;

  String _backgroundColor() {
    switch (tokenGroup) {
      case 'md.comp.filled-icon-button':
      case 'md.comp.filled-tonal-icon-button':
        return '''

    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ${componentColor('$tokenGroup.disabled.container')};
      }
      if (states.contains(WidgetState.selected)) {
        return ${componentColor('$tokenGroup.selected.container')};
      }
      if (toggleable) { // toggleable but unselected case
        return ${componentColor('$tokenGroup.unselected.container')};
      }
      return ${componentColor('$tokenGroup.container')};
    })''';
      case 'md.comp.outlined-icon-button':
        return '''

    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        if (states.contains(WidgetState.selected)) {
          return ${componentColor('$tokenGroup.disabled.selected.container')};
        }
        return Colors.transparent;
      }
      if (states.contains(WidgetState.selected)) {
        return ${componentColor('$tokenGroup.selected.container')};
      }
      return Colors.transparent;
    })''';
    }
    return '''

    const MaterialStatePropertyAll<Color?>(Colors.transparent)''';
  }

  String _foregroundColor() {
    switch (tokenGroup) {
      case 'md.comp.filled-icon-button':
      case 'md.comp.filled-tonal-icon-button':
        return '''

    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ${componentColor('$tokenGroup.disabled.icon')};
      }
      if (states.contains(WidgetState.selected)) {
        return ${componentColor('$tokenGroup.toggle.selected.icon')};
      }
      if (toggleable) { // toggleable but unselected case
        return ${componentColor('$tokenGroup.toggle.unselected.icon')};
      }
      return ${componentColor('$tokenGroup.icon')};
    })''';
      case 'md.comp.outlined-icon-button':
      case 'md.comp.icon-button':
        return '''

    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return ${componentColor('$tokenGroup.disabled.icon')};
      }
      if (states.contains(WidgetState.selected)) {
        return ${componentColor('$tokenGroup.selected.icon')};
      }
      return ${componentColor('$tokenGroup.unselected.icon')};
    })''';
    }
    return '''

    const MaterialStatePropertyAll<Color?>(Colors.transparent)''';
  }

  String _overlayColor() {
    switch (tokenGroup) {
      case 'md.comp.filled-icon-button':
      case 'md.comp.filled-tonal-icon-button':
        return '''

    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return ${componentColor('$tokenGroup.toggle.selected.pressed.state-layer')}.withOpacity(${opacity('$tokenGroup.pressed.state-layer.opacity')});
        }
        if (states.contains(WidgetState.hovered)) {
          return ${componentColor('$tokenGroup.toggle.selected.hover.state-layer')}.withOpacity(${opacity('$tokenGroup.hover.state-layer.opacity')});
        }
        if (states.contains(WidgetState.focused)) {
          return ${componentColor('$tokenGroup.toggle.selected.focus.state-layer')}.withOpacity(${opacity('$tokenGroup.focus.state-layer.opacity')});
        }
      }
      if (toggleable) { // toggleable but unselected case
        if (states.contains(WidgetState.pressed)) {
          return ${componentColor('$tokenGroup.toggle.unselected.pressed.state-layer')}.withOpacity(${opacity('$tokenGroup.pressed.state-layer.opacity')});
        }
        if (states.contains(WidgetState.hovered)) {
          return ${componentColor('$tokenGroup.toggle.unselected.hover.state-layer')}.withOpacity(${opacity('$tokenGroup.hover.state-layer.opacity')});
        }
        if (states.contains(WidgetState.focused)) {
          return ${componentColor('$tokenGroup.toggle.unselected.focus.state-layer')}.withOpacity(${opacity('$tokenGroup.focus.state-layer.opacity')});
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return ${componentColor('$tokenGroup.pressed.state-layer')};
      }
      if (states.contains(WidgetState.hovered)) {
        return ${componentColor('$tokenGroup.hover.state-layer')};
      }
      if (states.contains(WidgetState.focused)) {
        return ${componentColor('$tokenGroup.focus.state-layer')};
      }
      return Colors.transparent;
    })''';
      case 'md.comp.outlined-icon-button':
        return '''
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return ${componentColor('$tokenGroup.selected.pressed.state-layer')}.withOpacity(${opacity('$tokenGroup.pressed.state-layer.opacity')});
        }
        if (states.contains(WidgetState.hovered)) {
          return ${componentColor('$tokenGroup.selected.hover.state-layer')}.withOpacity(${opacity('$tokenGroup.hover.state-layer.opacity')});
        }
        if (states.contains(WidgetState.focused)) {
          return ${componentColor('$tokenGroup.selected.focus.state-layer')}.withOpacity(${opacity('$tokenGroup.focus.state-layer.opacity')});
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return ${componentColor('$tokenGroup.unselected.pressed.state-layer')}.withOpacity(${opacity('$tokenGroup.pressed.state-layer.opacity')});
      }
      if (states.contains(WidgetState.hovered)) {
        return ${componentColor('$tokenGroup.unselected.hover.state-layer')}.withOpacity(${opacity('$tokenGroup.hover.state-layer.opacity')});
      }
      if (states.contains(WidgetState.focused)) {
        return ${componentColor('$tokenGroup.unselected.focus.state-layer')}.withOpacity(${opacity('$tokenGroup.focus.state-layer.opacity')});
      }
      return Colors.transparent;
    })''';
      case 'md.comp.icon-button':
        return '''

    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        if (states.contains(WidgetState.pressed)) {
          return ${componentColor('$tokenGroup.selected.pressed.state-layer')};
        }
        if (states.contains(WidgetState.hovered)) {
          return ${componentColor('$tokenGroup.selected.hover.state-layer')};
        }
        if (states.contains(WidgetState.focused)) {
          return ${componentColor('$tokenGroup.selected.focus.state-layer')};
        }
      }
      if (states.contains(WidgetState.pressed)) {
        return ${componentColor('$tokenGroup.unselected.pressed.state-layer')};
      }
      if (states.contains(WidgetState.hovered)) {
        return ${componentColor('$tokenGroup.unselected.hover.state-layer')};
      }
      if (states.contains(WidgetState.focused)) {
        return ${componentColor('$tokenGroup.unselected.focus.state-layer')};
      }
      return Colors.transparent;
    })''';
    }
    return '''

    const MaterialStatePropertyAll<Color?>(Colors.transparent)''';
  }

  String _minimumSize() {
    if (tokenAvailable('$tokenGroup.container.height') &&
        tokenAvailable('$tokenGroup.container.width')) {
      return '''

    const MaterialStatePropertyAll<Size>(Size(${getToken('$tokenGroup.container.width')}, ${getToken('$tokenGroup.container.height')}))''';
    } else {
      return '''

    const MaterialStatePropertyAll<Size>(Size(40.0, 40.0))''';
    }
  }

  String _shape() {
    if (tokenAvailable('$tokenGroup.container.shape')) {
      return '''

    const MaterialStatePropertyAll<OutlinedBorder>(${shape("$tokenGroup.container", "")})''';
    } else {
      return '''

    const MaterialStatePropertyAll<OutlinedBorder>(${shape("$tokenGroup.state-layer", "")})''';
    }
  }

  String _side() {
    if (tokenAvailable('$tokenGroup.unselected.outline.color')) {
      return '''

    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return null;
      } else {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: ${componentColor('$tokenGroup.disabled.unselected.outline')});
        }
        return BorderSide(color: ${componentColor('$tokenGroup.unselected.outline')});
      }
    })''';
    }
    return ''' null''';
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
  _${blockName}DefaultsM3(this.context, this.toggleable)
    : super(
        animationDuration: kThemeChangeDuration,
        enableFeedback: true,
        alignment: Alignment.center,
      );

  final BuildContext context;
  final bool toggleable;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  // No default text style

  @override
  WidgetStateProperty<Color?>? get backgroundColor =>${_backgroundColor()};

  @override
  WidgetStateProperty<Color?>? get foregroundColor =>${_foregroundColor()};

 @override
  WidgetStateProperty<Color?>? get overlayColor =>${_overlayColor()};

  @override
  WidgetStateProperty<double>? get elevation =>
    const MaterialStatePropertyAll<double>(0.0);

  @override
  WidgetStateProperty<Color>? get shadowColor =>
    ${_elevationColor("$tokenGroup.container.shadow-color")};

  @override
  WidgetStateProperty<Color>? get surfaceTintColor =>
    ${_elevationColor("$tokenGroup.container.surface-tint-layer.color")};

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
    const MaterialStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.all(8.0));

  @override
  WidgetStateProperty<Size>? get minimumSize =>${_minimumSize()};

  // No default fixedSize

  @override
  WidgetStateProperty<Size>? get maximumSize =>
    const MaterialStatePropertyAll<Size>(Size.infinite);

  @override
  WidgetStateProperty<double>? get iconSize =>
    const MaterialStatePropertyAll<double>(${getToken("$tokenGroup.icon.size")});

  @override
  WidgetStateProperty<BorderSide?>? get side =>${_side()};

  @override
  WidgetStateProperty<OutlinedBorder>? get shape =>${_shape()};

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
