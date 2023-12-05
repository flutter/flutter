// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'css_conditional.dart';

@JS('CSSContainerRule')
@staticInterop
class CSSContainerRule implements CSSConditionRule {}

extension CSSContainerRuleExtension on CSSContainerRule {
  external String get containerName;
  external String get containerQuery;
}
