// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'result.dart';
import 'capture_sink.dart';

/// A stream transformer that captures a stream of events into [Result]s.
///
/// The result of the transformation is a stream of [Result] values and no
/// error events. Exposed by [Result.captureStream].
class CaptureStreamTransformer<T> extends StreamTransformerBase<T, Result<T>> {
  const CaptureStreamTransformer();

  @override
  Stream<Result<T>> bind(Stream<T> source) =>
      Stream<Result<T>>.eventTransformed(
          source, (sink) => CaptureSink<T>(sink));
}
