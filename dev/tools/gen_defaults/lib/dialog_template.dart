// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class DialogTemplate extends TokenTemplate {
  const DialogTemplate(super.blockName, super.fileName, super.tokens, {
    super.colorSchemePrefix = '_colors.',
    super.textThemePrefix = '_textTheme.'
  });

  @override
  String generate() => '''
class _${blockName}DefaultsM3 extends DialogTheme {
  _${blockName}DefaultsM3(this.context)
    : super(
        alignment: Alignment.center,
        elevation: ${elevation("md.comp.dialog.container")},
        shape: ${shape("md.comp.dialog.container")},
      );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  Color? get iconColor => _colors.secondary;

  // TODO(darrenaustin): overlay should be handled by Material widget: https://github.com/flutter/flutter/issues/9160
  @override
  Color? get backgroundColor => ElevationOverlay.colorWithOverlay(${componentColor("md.comp.dialog.container")}, _colors.primary, ${elevation("md.comp.dialog.container")});

  @override
  TextStyle? get titleTextStyle => ${textStyle("md.comp.dialog.headline")};

  @override
  TextStyle? get contentTextStyle => ${textStyle("md.comp.dialog.supporting-text")};

  @override
  EdgeInsetsGeometry? get actionsPadding => const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0);
}
''';
}
