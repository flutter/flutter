// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class SnackbarTemplate extends TokenTemplate {
  const SnackbarTemplate(super.blockName, super.fileName, super.tokens);

  @override
  String generate() => '''
class _${blockName}DefaultsM3 extends SnackbarThemeData {
  const _${blockName}DefaultsM3(this.context) : super(
??
  );

  final BuildContext context;

  @override
  double get elevation => ${tokens["md.sys.elevation.level3"]};
}
''';
}
