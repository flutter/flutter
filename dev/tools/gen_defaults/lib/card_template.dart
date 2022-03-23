// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class CardTemplate extends TokenTemplate {
  const CardTemplate(String fileName, Map<String, dynamic> tokens)
      : super(fileName, tokens);

  @override
  String generate() => '''
// Generated version ${tokens["version"]}
class _TokenDefaultsM3 extends CardTheme {
  const _TokenDefaultsM3(this.context)
    : super(
        clipBehavior: Clip.none,
        elevation: ${elevation("md.comp.elevated-card.container")},
        margin: const EdgeInsets.all(4.0),
        shape: ${shape("md.comp.elevated-card.container")},
      );

  final BuildContext context;

  @override
  Color? get color => Theme.of(context).colorScheme.${color("md.comp.elevated-card.container")};

  @override
  Color? get shadowColor => Theme.of(context).colorScheme.${tokens["md.comp.elevated-card.container.shadow-color"]};

  @override
  Color? get surfaceTintColor => Theme.of(context).colorScheme.${tokens["md.comp.elevated-card.container.surface-tint-layer.color"]};
}
''';
}
