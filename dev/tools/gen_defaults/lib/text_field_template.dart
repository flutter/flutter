// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class TextFieldTemplate extends TokenTemplate {
  const TextFieldTemplate(super.blockName, super.fileName, super.tokens);

  @override
  String generate() => '''
TextStyle? _m3StateInputStyle(BuildContext context) => MaterialStateTextStyle.resolveWith((Set<MaterialState> states) {
  if (states.contains(MaterialState.disabled)) {
    return TextStyle(color: ${textStyle("md.comp.filled-text-field.label-text")}!.color?.withOpacity(0.38));
  }
  return TextStyle(color: ${textStyle("md.comp.filled-text-field.label-text")}!.color);
});

TextStyle _m3InputStyle(BuildContext context) => ${textStyle("md.comp.filled-text-field.label-text")}!;

TextStyle _m3CounterErrorStyle(BuildContext context) =>
  ${textStyle("md.comp.filled-text-field.supporting-text")}!.copyWith(color: ${componentColor('md.comp.filled-text-field.error.supporting-text')});
''';
}
