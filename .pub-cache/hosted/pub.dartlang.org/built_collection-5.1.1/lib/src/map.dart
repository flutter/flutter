// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'internal/copy_on_write_map.dart';
import 'internal/hash.dart';
import 'internal/null_safety.dart';

part 'map/built_map.dart';
part 'map/map_builder.dart';

// Internal only, for testing.
class OverriddenHashcodeBuiltMap<K, V> extends _BuiltMap<K, V> {
  final int _overrridenHashCode;

  OverriddenHashcodeBuiltMap(map, this._overrridenHashCode)
      : super.copyAndCheckTypes(map.keys, (k) => map[k]);

  @override
  // ignore: hash_and_equals
  int get hashCode => _overrridenHashCode;
}
