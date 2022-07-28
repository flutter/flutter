// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class TextFieldTemplate extends TokenTemplate {
  const TextFieldTemplate(super.blockName, super.fileName, super.tokens);

  @override
  String generate() => '''
// Generated version ${tokens["version"]}

TextStyle _m3InputStyle(BuildContext context) => ${textStyle("md.comp.filled-text-field.label-text")}!;
''';
}
