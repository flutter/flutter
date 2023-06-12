// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';

/// A map from case-insensitive strings to values.
///
/// Much of HTTP is case-insensitive, so this is useful to have pre-defined.
class CaseInsensitiveMap<V> extends CanonicalizedMap<String, String, V> {
  CaseInsensitiveMap() : super((key) => key.toLowerCase());

  CaseInsensitiveMap.from(Map<String, V> other)
      : super.from(other, (key) => key.toLowerCase());
}
