// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:isolate';
import 'package:meta/meta.dart';

import 'constants.dart';
import 'isolates.dart' as isolates;

/// The dart:io implementation of [isolate.compute].
Future<R> compute<Q, R>(isolates.ComputeCallback<Q, R> callback, Q message, { String? debugLabel }) async {
  debugLabel ??= kReleaseMode ? 'compute' : callback.toString();

  final Flow flow = Flow.begin();
  Timeline.startSync('$debugLabel: start', flow: flow);
  final ReceivePort port = ReceivePort();
  Timeline.finishSync();

  final Completer<dynamic> completer = Completer<dynamic>();
  port.listen((dynamic msg) {
    completer.complete(msg);

    Timeline.startSync('$debugLabel: end', flow: Flow.end(flow.id));
    port.close();
    Timeline.finishSync();
  });

  await Isolate.spawn<_IsolateConfiguration<Q, FutureOr<R>>>(
    _spawn,
    _IsolateConfiguration<Q, FutureOr<R>>(
      callback,
      message,
      port.sendPort,
      debugLabel,
      flow.id,
    ),
    errorsAreFatal: true,
    onExit: port.sendPort,
    onError: port.sendPort,
  );

  final dynamic response = await completer.future;

  if(response == null) {
    throw Exception('Isolate exited without result or error.');
  }

  assert(response is List<dynamic>);
  response as List<dynamic>;

  // success; see _spawn, where we wrap the result in a List
  if (response.length == 1) {
    assert(response[0] is R);
    return response[0] as R;
  }

  // error; documented by Isolate.addErrorListener
  assert(response.length == 2);

  final Exception exception = Exception(response[0]);
  final StackTrace stack = StackTrace.fromString(response[1] as String);
  await Future<Never>.error(exception, stack);  
}

@immutable
class _IsolateConfiguration<Q, R> {
  const _IsolateConfiguration(
    this.callback,
    this.message,
    this.resultPort,
    this.debugLabel,
    this.flowId,
  );
  final isolates.ComputeCallback<Q, R> callback;
  final Q message;
  final SendPort resultPort;
  final String debugLabel;
  final int flowId;

  FutureOr<R> apply() => callback(message);
}

Future<void> _spawn<Q, R>(_IsolateConfiguration<Q, FutureOr<R>> configuration) async {
  final R result = await Timeline.timeSync(
    configuration.debugLabel,
    () async {
      final FutureOr<R> applicationResult = await configuration.apply();
      return await applicationResult;
    },
    flow: Flow.step(configuration.flowId),
  );
  Timeline.timeSync(
    '${configuration.debugLabel}: exiting and returning a result', () {},
    flow: Flow.step(configuration.flowId),
  );

  // Wrap in list to ensure our expectations in the main isolate are met.
  // We need to wrap the result in a List because the user provided type R could 
  // also be a List. Meaning, a check `result is R` could return true for what
  // was an error event. (Error event is specified by the dart SDK)
  Isolate.exit(configuration.resultPort, <R>[result]);
}
