// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'cssom.dart';

@JS('CSSLayerBlockRule')
@staticInterop
class CSSLayerBlockRule implements CSSGroupingRule {}

extension CSSLayerBlockRuleExtension on CSSLayerBlockRule {
  external String get name;
}

@JS('CSSLayerStatementRule')
@staticInterop
class CSSLayerStatementRule implements CSSRule {}

extension CSSLayerStatementRuleExtension on CSSLayerStatementRule {
  external JSArray get nameList;
}
