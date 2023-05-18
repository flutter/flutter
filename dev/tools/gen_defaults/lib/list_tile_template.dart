// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class ListTileTemplate extends TokenTemplate {
  const ListTileTemplate(super.blockName, super.fileName, super.tokens, {
    super.colorSchemePrefix = '_colors.',
    super.textThemePrefix = '_textTheme.',
  });

  @override
  String generate() => '''
class _${blockName}DefaultsM3 extends ListTileThemeData {
  _${blockName}DefaultsM3(this.context)
    : super(
        contentPadding: const EdgeInsetsDirectional.only(start: 16.0, end: 24.0),
        minLeadingWidth: 24,
        minVerticalPadding: 8,
        shape: ${shape("md.comp.list.list-item.container")},
      );

  final BuildContext context;
  late final ThemeData _theme = Theme.of(context);
  late final ColorScheme _colors = _theme.colorScheme;
  late final TextTheme _textTheme = _theme.textTheme;

  @override
  Color? get tileColor =>  Colors.transparent;

  @override
  TextStyle? get titleTextStyle => ${textStyle("md.comp.list.list-item.label-text")};

  @override
  TextStyle? get subtitleTextStyle => ${textStyle("md.comp.list.list-item.supporting-text")};

  @override
  TextStyle? get leadingAndTrailingTextStyle => ${textStyle("md.comp.list.list-item.trailing-supporting-text")};

  @override
  Color? get selectedColor => ${componentColor('md.comp.list.list-item.selected.trailing-icon')};

  @override
  Color? get iconColor => ${componentColor('md.comp.list.list-item.trailing-icon')};
}
''';
}
