// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_style.src.rule.type_argument;

import '../chunk.dart';
import 'rule.dart';

/// Rule for splitting a list of type arguments or type parameters. Type
/// parameters split a little differently from normal value argument lists. In
/// particular, this tries harder to avoid splitting before the first type
/// argument since that looks stranger with `<...>` than it does with `(...)`.
///
/// The values for a rule for `n` arguments are:
///
/// * `0`: No splits at all.
/// * `1 ... n`: Split before one argument, starting from the last.
/// * `n + 1`: Split before all arguments.
///
/// If there is only one type argument, the last two cases collapse and there
/// are only two values.
class TypeArgumentRule extends Rule {
  /// The chunks prior to each positional type argument.
  final List<Chunk> _arguments = [];

  @override
  int get cost => Cost.typeArgument;

  @override
  int get numValues => _arguments.length == 1 ? 2 : _arguments.length + 2;

  /// Remembers [chunk] as containing the split that occurs right before a type
  /// argument in the list.
  void beforeArgument(Chunk chunk) {
    _arguments.add(chunk);
  }

  @override
  bool isSplit(int value, Chunk chunk) {
    // Don't split at all.
    if (value == Rule.unsplit) return false;

    // Split before every argument.
    if (value == numValues - 1) return true;

    // Split before a single argument. Try later arguments before earlier ones
    // to try to keep as much on the first line as possible.
    return chunk == _arguments[_arguments.length - value];
  }

  @override
  String toString() => 'TypeArg${super.toString()}';
}
