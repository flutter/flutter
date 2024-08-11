// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// A generic destination for data.
///
/// Multiple data values can be put into a sink, and when no more data is
/// available, the sink should be closed.
///
/// This is a generic interface that other data receivers can implement.
abstract interface class Sink<T> {
  /// Adds [data] to the sink.
  ///
  /// Must not be called after a call to [close].
  void add(T data);

  /// Closes the sink.
  ///
  /// The [add] method must not be called after this method.
  ///
  /// Calling this method more than once is allowed, but does nothing.
  void close();
}
