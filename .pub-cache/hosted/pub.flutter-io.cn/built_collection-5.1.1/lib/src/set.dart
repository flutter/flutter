// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:built_collection/src/iterable.dart' show BuiltIterable;
import 'package:built_collection/src/list.dart' show BuiltList;

import 'internal/hash.dart';
import 'internal/copy_on_write_set.dart';
import 'internal/iterables.dart';
import 'internal/null_safety.dart';
import 'internal/unmodifiable_set.dart';

part 'set/built_set.dart';
part 'set/set_builder.dart';

// Internal only, for testing.
class OverriddenHashcodeBuiltSet<T> extends _BuiltSet<T> {
  final int _overridenHashCode;

  OverriddenHashcodeBuiltSet(Iterable iterable, this._overridenHashCode)
      : super.from(iterable);

  @override
  // ignore: hash_and_equals
  int get hashCode => _overridenHashCode;
}
