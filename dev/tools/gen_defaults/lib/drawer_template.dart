// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class DrawerTemplate extends TokenTemplate {
  const DrawerTemplate(super.blockName, super.fileName, super.tokens);

  @override
  String generate() => '''
class _${blockName}DefaultsM3 extends DrawerThemeData {
  _${blockName}DefaultsM3(this.context)
      : super(elevation: ${elevation("md.comp.navigation-drawer.modal.container")});

  final BuildContext context;
  late final TextDirection direction = Directionality.of(context);

  @override
  Color? get backgroundColor => ${componentColor("md.comp.navigation-drawer.modal.container")};

  @override
  Color? get surfaceTintColor => ${colorOrTransparent("md.comp.navigation-drawer.container.surface-tint-layer.color")};

  @override
  Color? get shadowColor => ${colorOrTransparent("md.comp.navigation-drawer.container.shadow-color")};

  // There isn't currently a token for this value, but it is shown in the spec,
  // so hard coding here for now.
  @override
  ShapeBorder? get shape => RoundedRectangleBorder(
    borderRadius: const BorderRadiusDirectional.horizontal(
      end: Radius.circular(16.0),
    ).resolve(direction),
  );

  // There isn't currently a token for this value, but it is shown in the spec,
  // so hard coding here for now.
  @override
  ShapeBorder? get endShape => RoundedRectangleBorder(
    borderRadius: const BorderRadiusDirectional.horizontal(
      start: Radius.circular(16.0),
    ).resolve(direction),
  );
}
''';
}
