// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';

/// A sink that provides access to all the [events] that have been passed to it.
///
/// See also [ChunkedConversionSink.withCallback].
class AccumulatorSink<T> implements Sink<T> {
  /// An unmodifiable list of events passed to this sink so far.
  List<T> get events => UnmodifiableListView(_events);
  final _events = <T>[];

  /// Whether [close] has been called.
  bool get isClosed => _isClosed;
  var _isClosed = false;

  /// Removes all events from [events].
  ///
  /// This can be used to avoid double-processing events.
  void clear() {
    _events.clear();
  }

  @override
  void add(T event) {
    if (_isClosed) {
      throw StateError("Can't add to a closed sink.");
    }

    _events.add(event);
  }

  @override
  void close() {
    _isClosed = true;
  }
}
