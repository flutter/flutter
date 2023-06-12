// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'result.dart';

/// Used by [Result.captureSink].
class CaptureSink<T> implements EventSink<T> {
  final EventSink<Result<T>> _sink;

  CaptureSink(EventSink<Result<T>> sink) : _sink = sink;

  @override
  void add(T value) {
    _sink.add(Result<T>.value(value));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _sink.add(Result.error(error, stackTrace));
  }

  @override
  void close() {
    _sink.close();
  }
}
