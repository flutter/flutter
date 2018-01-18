// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';

/// Signature for the callback passed to [compute].
///
/// {@macro flutter.foundation.compute.types}
///
/// Instances of [ComputeCallback] must be top-level functions or static methods
/// of classes, not closures or instance methods of objects.
///
/// {@macro flutter.foundation.compute.limitations}
typedef R ComputeCallback<Q, R>(Q message);

/// Spawn an isolate, run `callback` on that isolate, passing it `message`, and
/// (eventually) return the value returned by `callback`.
///
/// This is useful for operations that take longer than a few milliseconds, and
/// which would therefore risk skipping frames. For tasks that will only take a
/// few milliseconds, consider [scheduleTask] instead.
///
/// {@template flutter.foundation.compute.types}
/// `Q` is the type of the message that kicks off the computation.
///
/// `R` is the type of the value returned.
/// {@endtemplate}
///
/// The `callback` argument must be a top-level function, not a closure or an
/// instance or static method of a class.
///
/// {@template flutter.foundation.compute.limitations}
/// There are limitations on the values that can be sent and received to and
/// from isolates. These limitations constrain the values of `Q` and `R` that
/// are possible. See the discussion at [SendPort.send].
/// {@endtemplate}
Future<R> compute<Q, R>(ComputeCallback<Q, R> callback, Q message) async {
  final ReceivePort resultPort = new ReceivePort();
  final Isolate isolate = await Isolate.spawn(
    _spawn,
    new _IsolateConfiguration<Q, R>(callback, message, resultPort.sendPort),
    errorsAreFatal: true,
    onExit: resultPort.sendPort,
  );
  final R result = await resultPort.first;
  resultPort.close();
  isolate.kill();
  return result;
}

@immutable
class _IsolateConfiguration<Q, R> {
  const _IsolateConfiguration(this.callback, this.message, this.resultPort);
  final ComputeCallback<Q, R> callback;
  final Q message;
  final SendPort resultPort;
}

void _spawn<Q, R>(_IsolateConfiguration<Q, R> configuration) {
  final R result = configuration.callback(configuration.message);
  configuration.resultPort.send(result);
}
