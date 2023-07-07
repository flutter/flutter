// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:js/js_util.dart' as js_util;

/// Converts a [data] object into a JS Object of type `T`.
T jsifyAs<T>(Map<String, Object?> data) {
  return js_util.jsify(data) as T;
}
