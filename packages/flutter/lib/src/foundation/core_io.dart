// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs
import 'dart:async';
import 'dart:developer' show Timeline, Flow;
import 'dart:io';
import 'dart:isolate';

import 'package:meta/meta.dart';

import 'assertions.dart';
import 'constants.dart';
import 'core_stub.dart' as core;
import 'platform.dart';

TargetPlatform get defaultTargetPlatform {
  TargetPlatform result;
  if (Platform.isIOS) {
    result = TargetPlatform.iOS;
  } else if (Platform.isAndroid) {
    result = TargetPlatform.android;
  } else if (Platform.isFuchsia) {
    result = TargetPlatform.fuchsia;
  }
  assert(() {
    if (Platform.environment.containsKey('FLUTTER_TEST'))
      result = TargetPlatform.android;
    return true;
  }());
  if (debugDefaultTargetPlatformOverride != null)
    result = debugDefaultTargetPlatformOverride;
  if (result == null) {
    throw FlutterError(
      'Unknown platform.\n'
      '${Platform.operatingSystem} was not recognized as a target platform. '
      'Consider updating the list of TargetPlatforms to include this platform.'
    );
  }
  return result;
}

const int kMaxUnsignedSMI = 0x3FFFFFFFFFFFFFFF;

class BitField<T extends dynamic> implements core.BitField<T> {
  BitField(this._length)
    : assert(_length <= _smiBits),
      _bits = _allZeros;

  BitField.filled(this._length, bool value)
    : assert(_length <= _smiBits),
      _bits = value ? _allOnes : _allZeros;

  final int _length;
  int _bits;

  static const int _smiBits = 62; // see https://www.dartlang.org/articles/numeric-computation/#smis-and-mints
  static const int _allZeros = 0;
  static const int _allOnes = kMaxUnsignedSMI; // 2^(_kSMIBits+1)-1

  @override
  bool operator [](T index) {
    assert(index.index < _length);
    return (_bits & 1 << index.index) > 0;
  }

  @override
  void operator []=(T index, bool value) {
    assert(index.index < _length);
    if (value)
      _bits = _bits | (1 << index.index);
    else
      _bits = _bits & ~(1 << index.index);
  }

  @override
  void reset([ bool value = false ]) {
    _bits = value ? _allOnes : _allZeros;
  }
}

typedef ComputeCallback<Q, R> = FutureOr<R> Function(Q message);

Future<R> compute<Q, R>(ComputeCallback<Q, R> callback, Q message, { String debugLabel }) async {
  if (!kReleaseMode) {
    debugLabel ??= callback.toString();
  }
  final Flow flow = Flow.begin();
  Timeline.startSync('$debugLabel: start', flow: flow);
  final ReceivePort resultPort = ReceivePort();
  final ReceivePort errorPort = ReceivePort();
  Timeline.finishSync();
  final Isolate isolate = await Isolate.spawn<_IsolateConfiguration<Q, FutureOr<R>>>(
    _spawn,
    _IsolateConfiguration<Q, FutureOr<R>>(
      callback,
      message,
      resultPort.sendPort,
      debugLabel,
      flow.id,
    ),
    errorsAreFatal: true,
    onExit: resultPort.sendPort,
    onError: errorPort.sendPort,
  );
  final Completer<R> result = Completer<R>();
  errorPort.listen((dynamic errorData) {
    assert(errorData is List<dynamic>);
    assert(errorData.length == 2);
    final Exception exception = Exception(errorData[0]);
    final StackTrace stack = StackTrace.fromString(errorData[1]);
    if (result.isCompleted) {
      Zone.current.handleUncaughtError(exception, stack);
    } else {
      result.completeError(exception, stack);
    }
  });
  resultPort.listen((dynamic resultData) {
    assert(resultData == null || resultData is R);
    if (!result.isCompleted)
      result.complete(resultData);
  });
  await result.future;
  Timeline.startSync('$debugLabel: end', flow: Flow.end(flow.id));
  resultPort.close();
  errorPort.close();
  isolate.kill();
  Timeline.finishSync();
  return result.future;
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
  final ComputeCallback<Q, R> callback;
  final Q message;
  final SendPort resultPort;
  final String debugLabel;
  final int flowId;

  R apply() => callback(message);
}

Future<void> _spawn<Q, R>(_IsolateConfiguration<Q, FutureOr<R>> configuration) async {
  R result;
  await Timeline.timeSync(
    '${configuration.debugLabel}',
    () async { result = await configuration.apply(); },
    flow: Flow.step(configuration.flowId),
  );
  Timeline.timeSync(
    '${configuration.debugLabel}: returning result',
    () { configuration.resultPort.send(result); },
    flow: Flow.step(configuration.flowId),
  );
}
