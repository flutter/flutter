// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class ListTileTemplate extends TokenTemplate {
  const ListTileTemplate(super.blockName, super.fileName, super.tokens);

  @override
  String generate() => '''
class _${blockName}DefaultsM3 extends ListTileThemeData {
  const _${blockName}DefaultsM3(this.context)
    : super(shape: ${shape("md.comp.list.list-item.container")});

  final BuildContext context;

  @override
  Color? get tileColor => ${componentColor("md.comp.list.list-item.container")};

  @override
  TextStyle? get titleTextStyle => ${textStyle("md.comp.list.list-item.label-text")};

  @override
  TextStyle? get subtitleTextStyle => ${textStyle("md.comp.list.list-item.supporting-text")};

  @override
  TextStyle? get leadingAndTrailingTextStyle => ${textStyle("md.comp.list.list-item.trailing-supporting-text")};

  @override
  Color? get selectedColor => ${componentColor('md.comp.list.list-item.selected.trailing-icon')};

  @override
  Color? get iconColor => ${componentColor('md.comp.list.list-item.unselected.trailing-icon')};
}
''';
}
