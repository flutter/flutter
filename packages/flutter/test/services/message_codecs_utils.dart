// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart' show MethodCall;
import 'package:meta/meta.dart';
import 'package:test/test.dart';

class _IsMethodCall extends Matcher {
  const _IsMethodCall(this.name, this.arguments);

  final String name;
  final dynamic arguments;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! MethodCall)
      return false;
    if (item.method != name)
      return false;
    return _deepEquals(item.arguments, arguments);
  }

  bool _deepEquals(dynamic a, dynamic b) {
    if (a == b)
      return true;
    if (a is List)
      return b is List && _deepEqualsList(a, b);
    if (a is Map)
      return b is Map && _deepEqualsMap(a, b);
    return false;
  }

  bool _deepEqualsList(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length)
      return false;
    for (int i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i]))
        return false;
    }
    return true;
  }

  bool _deepEqualsMap(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
    if (a.length != b.length)
      return false;
    for (dynamic key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key]))
        return false;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    return description
      .add('has method name: ').addDescriptionOf(name)
      .add(' with arguments: ').addDescriptionOf(arguments);
  }
}

/// Returns a matcher that matches [MethodCall] instances with the specified
/// method name and arguments.
///
/// Arguments checking implements deep equality for [List] and [Map] types.
Matcher isMethodCall(String name, {@required dynamic arguments}) {
  return new _IsMethodCall(name, arguments);
}
