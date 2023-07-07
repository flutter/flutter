// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_util' as js_util;

/// A utility that shims dart:js_util to manipulate JavaScript interop objects.
class JsUtil {
  /// Returns true if the object [o] has the property [name].
  bool hasProperty(Object o, Object name) => js_util.hasProperty(o, name);

  /// Returns the value of the property [name] in the object [o].
  dynamic getProperty(Object o, Object name) =>
      js_util.getProperty<dynamic>(o, name);
}
