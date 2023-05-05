// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class DrawerTemplate extends TokenTemplate {
  const DrawerTemplate(super.blockName, super.fileName, super.tokens);

  @override
  String generate() => '''
class _${blockName}DefaultsM3 extends DrawerThemeData {
  const _${blockName}DefaultsM3(this.context)
      : super(elevation: ${elevation("md.comp.navigation-drawer.modal.container")});

  final BuildContext context;

  @override
  Color? get backgroundColor => ${componentColor("md.comp.navigation-drawer.container")};

  @override
  Color? get surfaceTintColor => ${colorOrTransparent("md.comp.navigation-drawer.container.surface-tint-layer.color")};

  @override
  Color? get shadowColor => ${colorOrTransparent("md.comp.navigation-drawer.container.shadow-color")};

  // This don't appear to be tokens for this value, but it is
  // shown in the spec.
  @override
  ShapeBorder? get shape => const RoundedRectangleBorder(
    borderRadius: BorderRadius.horizontal(right: Radius.circular(16.0)),
  );

  // This don't appear to be tokens for this value, but it is
  // shown in the spec.
  @override
  ShapeBorder? get endShape => const RoundedRectangleBorder(
    borderRadius: BorderRadius.horizontal(left: Radius.circular(16.0)),
  );
}
''';
}
