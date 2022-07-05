// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class DrawerTemplate extends TokenTemplate {
  const DrawerTemplate(super.blockName, super.fileName, super.tokens);

  @override
  String generate() => '''
// Generated version ${tokens["version"]}
class _${blockName}DefaultsM3 extends DrawerThemeData {
  const _${blockName}DefaultsM3(this.context)
    : super(
      elevation: ${elevation('md.comp.navigation-drawer.standard.container')},
      width: ${tokens['md.comp.navigation-drawer.container.width']},
    );

  final BuildContext context;

  @override
  Color? get backgroundColor => ${componentColor('md.comp.navigation-drawer.container')};

  @override
  Color? get surfaceTintColor => ${componentColor('md.comp.navigation-drawer.container.surface-tint-layer')};

  @override
  Color? get scrimColor => Theme.of(context).brightness == Brightness.light ? Theme.of(context).colorScheme.onSurface.withOpacity(0.68) : Colors.black54;

  @override
  ShapeBorder? get shape => ${shape('md.comp.navigation-drawer.bottom.container')};
}''';
}
