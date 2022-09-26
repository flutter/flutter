// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class DividerTemplate extends TokenTemplate {
  const DividerTemplate(super.blockName, super.fileName, super.tokens, {
    super.colorSchemePrefix = '_colors.',
    super.textThemePrefix = '_textTheme.'
  });

  @override
  String generate() => '''
class _${blockName}DefaultsM3 extends DividerThemeData {
  _${blockName}DefaultsM3(this.context) : super(thickness: ${tokens["md.comp.divider.thickness"]});

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override Color? get color => ${componentColor("md.comp.divider")};
}
''';
}
