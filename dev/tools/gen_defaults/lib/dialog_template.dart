// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class DialogTemplate extends TokenTemplate {
  const DialogTemplate(String fileName, Map<String, dynamic> tokens) : super(fileName, tokens);

  @override
  String generate() => '''
// Generated version ${tokens["version"]}
class _TokenDefaultsM3 extends DialogTheme {
  _TokenDefaultsM3(this.context)
    : _colors = Theme.of(context).colorScheme,
      _textTheme = Theme.of(context).textTheme,
      super(
        alignment: Alignment.center,
        elevation: ${elevation("md.comp.dialog.container")},
        shape: ${shape("md.comp.dialog.container")},
      );

  final BuildContext context;
  final ColorScheme _colors;
  final TextTheme _textTheme;

  // TODO(darrenaustin): overlay should be handled by Material widget: https://github.com/flutter/flutter/issues/9160
  @override
  Color? get backgroundColor => ElevationOverlay.colorWithOverlay(_colors.${color("md.comp.dialog.container")}, _colors.primary, ${elevation("md.comp.dialog.container")});

  @override
  TextStyle? get titleTextStyle => _textTheme.${textStyle("md.comp.dialog.subhead")};

  @override
  TextStyle? get contentTextStyle => _textTheme.${textStyle("md.comp.dialog.supporting-text")};
}
''';
}
