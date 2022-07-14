// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class DialogTemplate extends TokenTemplate {
  const DialogTemplate(super.fileName, super.tokens)
    : super(colorSchemePrefix: '_colors.',
        textThemePrefix: '_textTheme.'
      );

  @override
  String generate() => '''
// Generated version ${tokens["version"]}
class _TokenDefaultsM3 extends DialogTheme {
  _TokenDefaultsM3(this.context)
    : super(
        alignment: Alignment.center,
        elevation: ${elevation("md.comp.dialog.container")},
        shape: ${shape("md.comp.dialog.container")},
      );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  // TODO(darrenaustin): overlay should be handled by Material widget: https://github.com/flutter/flutter/issues/9160
  @override
  Color? get backgroundColor => ElevationOverlay.colorWithOverlay(${componentColor("md.comp.dialog.container")}, _colors.primary, ${elevation("md.comp.dialog.container")});

  @override
  TextStyle? get titleTextStyle => ${textStyle("md.comp.dialog.subhead")};

  @override
  TextStyle? get contentTextStyle => ${textStyle("md.comp.dialog.supporting-text")};
}
''';
}
