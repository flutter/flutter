// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class BottomSheetTemplate extends TokenTemplate {
  const BottomSheetTemplate(super.blockName, super.fileName, super.tokens);

  @override
  String generate() => '''
// Generated version ${tokens["version"]}
class _${blockName}DefaultsM3 extends BottomSheetThemeData {
   _${blockName}DefaultsM3(this.context)
    : super();

  final BuildContext context;


  @override
  Color? get color => ${componentColor("md.comp.elevated-card.container")};


}
''';
}
