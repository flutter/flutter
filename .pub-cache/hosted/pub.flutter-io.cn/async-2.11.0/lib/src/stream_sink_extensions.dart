// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'stream_sink_transformer.dart';
import 'stream_sink_transformer/reject_errors.dart';

/// Extensions on [StreamSink] to make stream transformations more fluent.
extension StreamSinkExtensions<T> on StreamSink<T> {
  /// Transforms a [StreamSink] using [transformer].
  StreamSink<S> transform<S>(StreamSinkTransformer<S, T> transformer) =>
      transformer.bind(this);

  /// Returns a [StreamSink] that forwards to `this` but rejects errors.
  ///
  /// If an error is passed (either by [addError] or [addStream]), the
  /// underlying sink will be closed and the error will be forwarded to the
  /// returned sink's [StreamSink.done] future. Further events will be ignored.
  StreamSink<T> rejectErrors() => RejectErrorsSink(this);
}
