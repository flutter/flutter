// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'constants.dart';
import 'isolates.dart' as isolates;

void _void() {}

/// The dart:io implementation of [isolate.compute].
Future<R> compute<Q, R>(isolates.ComputeCallback<Q, R> callback, Q message, { String? debugLabel }) async {
  debugLabel ??= kReleaseMode ? 'compute' : callback.toString();

  final Flow flow = Flow.begin();
  final int flowId = flow.id;

  Timeline.timeSync('$debugLabel: start', _void, flow: flow);

  // We need to be explicit about which variables the closure captures because
  // it may inadvertently capture Flow which cannot be sent over a SendPort
  final R result = await Isolate.run(_fn(callback, message, flowId, debugLabel));

  Timeline.timeSync('$debugLabel: end', _void, flow: Flow.end(flowId));

  return result;
}

FutureOr<R> Function() _fn<Q, R>(isolates.ComputeCallback<Q, R> callback, Q message, int flowId, String debugLabel) {
  return () {
    return Timeline.timeSync(
      debugLabel,
      () => callback(message),
      flow: Flow.step(flowId)
    );
  };
}
