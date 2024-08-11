// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch, unsafeCast;
import "dart:_string" show JSStringImpl;
import 'dart:_js_helper' as js;

@patch
class int {
  @patch
  static int parse(String source,
      {int? radix, @deprecated int onError(String source)?}) {
    int? value = tryParse(source, radix: radix);
    if (value != null) return value;
    if (onError != null) return onError(source);
    throw new FormatException(source);
  }

  @patch
  static int? tryParse(String source, {int? radix}) {
    // TODO(omersa): JS's `parseInt` is not compatible, copy dart2js's
    // implementation.
    if (radix == null) {
      return js
          .JS<double>('(s) => parseInt(s)',
              unsafeCast<JSStringImpl>(source).toExternRef)
          .toInt();
    } else {
      return js
          .JS<double>('(s, r) => parseInt(s, r)',
              unsafeCast<JSStringImpl>(source).toExternRef, radix.toDouble())
          .toInt();
    }
  }
}
