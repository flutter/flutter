// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class SearchBarTemplate extends TokenTemplate {
  const SearchBarTemplate(
    super.blockName,
    super.fileName,
    super.tokens, {
    super.colorSchemePrefix = '_colors.',
    super.textThemePrefix = '_textTheme.',
  });

  String _surfaceTint() {
    final String? color = colorOrTransparent(
      'md.comp.search-bar.container.surface-tint-layer.color',
    );
    final surfaceTintColor = 'MaterialStatePropertyAll<Color>($color);';
    if (color == 'Colors.transparent') {
      return 'const $surfaceTintColor';
    }
    return surfaceTintColor;
  }

  @override
  String generate() =>
      '''
class _SearchBarDefaultsM3 extends SearchBarThemeData {
  _SearchBarDefaultsM3(this.context);

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  WidgetStateProperty<Color?>? get backgroundColor =>
    MaterialStatePropertyAll<Color>(${componentColor("md.comp.search-bar.container")});

  @override
  WidgetStateProperty<double>? get elevation =>
    const MaterialStatePropertyAll<double>(${elevation("md.comp.search-bar.container")});

  @override
  WidgetStateProperty<Color>? get shadowColor =>
    MaterialStatePropertyAll<Color>(_colors.shadow);

  @override
  WidgetStateProperty<Color>? get surfaceTintColor =>
    ${_surfaceTint()}

  @override
  WidgetStateProperty<Color?>? get overlayColor =>
    WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.pressed)) {
        return ${componentColor("md.comp.search-bar.pressed.state-layer")};
      }
      if (states.contains(WidgetState.hovered)) {
        return ${componentColor("md.comp.search-bar.hover.state-layer")};
      }
      if (states.contains(WidgetState.focused)) {
        return ${colorOrTransparent("md.comp.search-bar.focused.state-layer")};
      }
      return Colors.transparent;
    });

  // No default side

  @override
  WidgetStateProperty<OutlinedBorder>? get shape =>
    const MaterialStatePropertyAll<OutlinedBorder>(${shape('md.comp.search-bar.container', '')});

  @override
  WidgetStateProperty<EdgeInsetsGeometry>? get padding =>
    const MaterialStatePropertyAll<EdgeInsetsGeometry>(EdgeInsets.symmetric(horizontal: 8.0));

  @override
  WidgetStateProperty<TextStyle?> get textStyle =>
    MaterialStatePropertyAll<TextStyle?>(${textStyleWithColor('md.comp.search-bar.input-text')});

  @override
  WidgetStateProperty<TextStyle?> get hintStyle =>
    MaterialStatePropertyAll<TextStyle?>(${textStyleWithColor('md.comp.search-bar.supporting-text')});

  @override
  BoxConstraints get constraints =>
    const BoxConstraints(minWidth: 360.0, maxWidth: 800.0, minHeight: ${getToken('md.comp.search-bar.container.height')});

  @override
  TextCapitalization get textCapitalization => TextCapitalization.none;
}
''';
}
