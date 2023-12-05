// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'cssom.dart';

@JS('CSSConditionRule')
@staticInterop
class CSSConditionRule implements CSSGroupingRule {}

extension CSSConditionRuleExtension on CSSConditionRule {
  external String get conditionText;
}

@JS('CSSMediaRule')
@staticInterop
class CSSMediaRule implements CSSConditionRule {}

extension CSSMediaRuleExtension on CSSMediaRule {
  external MediaList get media;
}

@JS('CSSSupportsRule')
@staticInterop
class CSSSupportsRule implements CSSConditionRule {}
