// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'cssom.dart';

@JS('CSSColorProfileRule')
@staticInterop
class CSSColorProfileRule implements CSSRule {}

extension CSSColorProfileRuleExtension on CSSColorProfileRule {
  external String get name;
  external String get src;
  external String get renderingIntent;
  external String get components;
}
