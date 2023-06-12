// Copyright 2014 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

/// A Stream that will emit the same values as the stream returned by [future]
/// once [future] completes.
///
/// If [future] completes to an error, the return value will emit that error
/// and then close.
///
/// If [broadcast] is true, this will be a broadcast stream. This assumes that
/// the stream returned by [future] will be a broadcast stream as well.
/// [broadcast] defaults to false.
///
/// # Example
///
/// This class is useful when you need to retrieve some object via a `Future`,
/// then return a `Stream` from that object:
///
///     var futureOfStream = getResource().then((resource) => resource.stream);
///     return FutureStream(futureOfStream);
class FutureStream<T> extends Stream<T> {
  FutureStream(Future<Stream<T>> future, {bool broadcast = false}) {
    _future = future.then(_identity, onError: (e, stackTrace) {
      // Since [controller] is synchronous, it's likely that emitting an error
      // will cause it to be cancelled before we call close.
      _controller?.addError(e, stackTrace);
      _controller?.close();
      _controller = null;
    });

    if (broadcast == true) {
      _controller = StreamController.broadcast(
          sync: true, onListen: _onListen, onCancel: _onCancel);
    } else {
      _controller = StreamController(
          sync: true, onListen: _onListen, onCancel: _onCancel);
    }
  }

  static T _identity<T>(T t) => t;

  late final Future<Stream<T>> _future;
  StreamController<T>? _controller;
  StreamSubscription<T>? _subscription;

  void _onListen() {
    _future.then((stream) {
      if (_controller == null) return;
      _subscription = stream.listen(_controller!.add,
          onError: _controller!.addError, onDone: _controller!.close);
    });
  }

  void _onCancel() {
    _subscription?.cancel();
    _subscription = null;
    _controller = null;
  }

  @override
  StreamSubscription<T> listen(void onData(T event)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _controller!.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  bool get isBroadcast => _controller?.stream.isBroadcast ?? false;
}
