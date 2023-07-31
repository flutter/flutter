// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// Simple delegating wrapper around a [Stream].
///
/// Subclasses can override individual methods, or use this to expose only the
/// [Stream] methods of a subclass.
///
/// Note that this is identical to [StreamView] in `dart:async`. It's provided
/// under this name for consistency with other `Delegating*` classes.
class DelegatingStream<T> extends StreamView<T> {
  DelegatingStream(super.stream);

  /// Creates a wrapper which throws if [stream]'s events aren't instances of
  /// `T`.
  ///
  /// This soundly converts a [Stream] to a `Stream<T>`, regardless of its
  /// original generic type, by asserting that its events are instances of `T`
  /// whenever they're provided. If they're not, the stream throws a
  /// [TypeError].
  @Deprecated('Use stream.cast instead')
  static Stream<T> typed<T>(Stream stream) => stream.cast();
}
