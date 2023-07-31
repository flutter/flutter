// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'internal/copy_on_write_map.dart';

import 'internal/hash.dart';
import 'internal/null_safety.dart';
import 'list.dart';

part 'list_multimap/built_list_multimap.dart';
part 'list_multimap/list_multimap_builder.dart';

// Internal only, for testing.
class OverriddenHashcodeBuiltListMultimap<K, V>
    extends _BuiltListMultimap<K, V> {
  final int _overridenHashCode;

  OverriddenHashcodeBuiltListMultimap(map, this._overridenHashCode)
      : super.copy(map.keys, (k) => map[k]);

  @override
  // ignore: hash_and_equals
  int get hashCode => _overridenHashCode;
}
