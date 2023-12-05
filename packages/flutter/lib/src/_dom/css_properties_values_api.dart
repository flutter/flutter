// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'cssom.dart';

@JS()
@staticInterop
@anonymous
class PropertyDefinition {
  external factory PropertyDefinition({
    required String name,
    String syntax,
    required bool inherits,
    String initialValue,
  });
}

extension PropertyDefinitionExtension on PropertyDefinition {
  external set name(String value);
  external String get name;
  external set syntax(String value);
  external String get syntax;
  external set inherits(bool value);
  external bool get inherits;
  external set initialValue(String value);
  external String get initialValue;
}

@JS('CSSPropertyRule')
@staticInterop
class CSSPropertyRule implements CSSRule {}

extension CSSPropertyRuleExtension on CSSPropertyRule {
  external String get name;
  external String get syntax;
  external bool get inherits;
  external String? get initialValue;
}
