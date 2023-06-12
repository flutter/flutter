// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async/async.dart';

/// Stream controller allowing to batch events.
class BatchedStreamController<T> {
  static const _defaultBatchDelayMilliseconds = 1000;
  static const _checkDelayMilliseconds = 100;

  final int _batchDelayMilliseconds;

  final StreamController<T> _inputController;
  late StreamQueue<T> _inputQueue;

  final StreamController<List<T>> _outputController;
  final Completer<bool> _completer = Completer<bool>();

  /// Create batched stream controller.
  ///
  /// Collects events from input [sink] and emits them in batches to the
  /// output [stream] every [delay] milliseconds. Keeps the original order.
  BatchedStreamController({
    int delay = _defaultBatchDelayMilliseconds,
  })  : _batchDelayMilliseconds = delay,
        _inputController = StreamController<T>(),
        _outputController = StreamController<List<T>>() {
    _inputQueue = StreamQueue<T>(_inputController.stream);
    unawaited(_batchAndSendEvents());
  }

  /// Sink collecting events.
  StreamSink<T> get sink => _inputController.sink;

  /// Output stream of batch events.
  Stream<List<T>> get stream => _outputController.stream;

  /// Close the controller.
  Future<dynamic> close() async {
    unawaited(_inputController.close());
    return _completer.future.then((value) => _outputController.close());
  }

  /// Send events to the output in a batch every [_batchDelayMilliseconds].
  Future<void> _batchAndSendEvents() async {
    const duration = Duration(milliseconds: _checkDelayMilliseconds);
    final buffer = <T>[];

    // Batch events every `_batchDelayMilliseconds`.
    //
    // Note that events might arrive at random intervals, so collecting
    // a predetermined number of events to send in a batch might delay
    // the batch indefinitely.  Instead, check for new events every
    // `_checkDelayMilliseconds` to make sure batches are sent in regular
    // intervals.
    var lastSendTime = DateTime.now().millisecondsSinceEpoch;
    while (await _hasEventOrTimeOut(duration)) {
      if (await _hasEventDuring(duration)) {
        buffer.add(await _inputQueue.next);
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now > lastSendTime + _batchDelayMilliseconds) {
        lastSendTime = now;
        if (buffer.isNotEmpty) {
          _outputController.sink.add(List.from(buffer));
          buffer.clear();
        }
      }
    }

    if (buffer.isNotEmpty) {
      _outputController.sink.add(List.from(buffer));
    }
    _completer.complete(true);
  }

  Future<bool> _hasEventOrTimeOut(Duration duration) =>
      _inputQueue.hasNext.timeout(duration, onTimeout: () => true);

  Future<bool> _hasEventDuring(Duration duration) =>
      _inputQueue.hasNext.timeout(duration, onTimeout: () => false);
}
