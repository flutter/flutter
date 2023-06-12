// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async/async.dart';

/// Converts [Future], [Iterable], and [Stream] implementations
/// containing [String] to a single [Stream] while ensuring all thrown
/// exceptions are forwarded through the return value.
Stream<String> normalizeGeneratorOutput(Object? value) {
  if (value == null) {
    return const Stream.empty();
  } else if (value is Future) {
    return StreamCompleter.fromFuture(value.then(normalizeGeneratorOutput));
  } else if (value is String) {
    value = [value];
  }

  if (value is Iterable) {
    value = Stream.fromIterable(value);
  }

  if (value is Stream) {
    return value.where((e) => e != null).map((e) {
      if (e is String) {
        return e.trim();
      }

      throw _argError(e as Object);
    }).where((e) => e.isNotEmpty);
  }
  throw _argError(value);
}

ArgumentError _argError(Object value) => ArgumentError(
    'Must be a String or be an Iterable/Stream containing String values. '
    'Found `${Error.safeToString(value)}` (${value.runtimeType}).');
