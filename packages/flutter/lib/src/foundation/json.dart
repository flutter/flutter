// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'isolates.dart';
library;

import 'dart:async';
import 'dart:convert';

import 'constants.dart';

const int _kJsonDecodeChunkSize = 16 * 1024;
const int _kJsonDecodeTimeSliceMicroseconds = 2000;

/// Asynchronously decodes the JSON string [source].
///
/// The returned future completes with the same value as [jsonDecode], and
/// [reviver] has the same behavior. If [source] is not valid JSON, the future
/// completes with a [FormatException].
///
/// On native platforms, decoding takes place on the current isolate in small
/// chunks. Between chunks, this function periodically yields to the event loop
/// so that other work, such as producing a frame, can run. This avoids the
/// isolate and result-transfer overhead of [compute].
///
/// The web JSON decoders are considerably slower when used incrementally. On
/// web platforms, this function therefore yields once before using [jsonDecode].
/// A large decode can still block the event loop, but does not pay the much
/// higher cost of the chunked decoder.
///
/// Work within each chunk is synchronous. Processing a large individual token,
/// finalizing a large container, or running a slow [reviver] callback can exceed
/// the target time slice. On native platforms, consider using [compute] when
/// the work must run in parallel or when blocking the current isolate for even
/// a short chunk is unacceptable. For small inputs, [jsonDecode] has less
/// scheduling overhead.
Future<Object?> jsonDecodeAsync(
  String source, {
  Object? Function(Object? key, Object? value)? reviver,
}) async {
  if (kIsWeb) {
    await Future<void>.delayed(Duration.zero);
    return jsonDecode(source, reviver: reviver);
  }

  final resultSink = _JsonResultSink();
  final StringConversionSink decoderSink = JsonDecoder(reviver).startChunkedConversion(resultSink);

  if (source.length <= _kJsonDecodeChunkSize) {
    decoderSink.addSlice(source, 0, source.length, false);
    decoderSink.close();
    return resultSink.value;
  }

  // Adaptive decoding must use elapsed wall-clock time. A fake clock does not
  // advance during synchronous parsing and therefore could not limit a chunk.
  final stopwatch = Stopwatch()..start(); // flutter_ignore: stopwatch (see analyze.dart)
  var start = 0;
  while (start < source.length) {
    final int remaining = source.length - start;
    final int end = start + (remaining < _kJsonDecodeChunkSize ? remaining : _kJsonDecodeChunkSize);
    final bool hasMore = end < source.length;
    decoderSink.addSlice(source, start, end, false);
    start = end;

    if (hasMore && stopwatch.elapsedMicroseconds >= _kJsonDecodeTimeSliceMicroseconds) {
      await Future<void>.delayed(Duration.zero);
      stopwatch.reset();
    }
  }

  decoderSink.close();
  return resultSink.value;
}

// Captures the single value emitted when the chunked JSON decoder is closed.
class _JsonResultSink implements Sink<Object?> {
  late final Object? value;

  @override
  void add(Object? data) {
    value = data;
  }

  @override
  void close() {}
}
