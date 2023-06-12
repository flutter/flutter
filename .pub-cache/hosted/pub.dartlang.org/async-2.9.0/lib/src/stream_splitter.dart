// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'future_group.dart';
import 'result/result.dart';

/// A class that splits a single source stream into an arbitrary number of
/// (single-subscription) streams (called "branch") that emit the same events.
///
/// Each branch will emit all the same values and errors as the source stream,
/// regardless of which values have been emitted on other branches. This means
/// that the splitter stores every event that has been emitted so far, which may
/// consume a lot of memory. The user can call [close] to indicate that no more
/// branches will be created, and this memory will be released.
///
/// The source stream is only listened to once a branch is created *and listened
/// to*. It's paused when all branches are paused *or when all branches are
/// canceled*, and resumed once there's at least one branch that's listening and
/// unpaused. It's not canceled unless no branches are listening and [close] has
/// been called.
class StreamSplitter<T> {
  /// The wrapped stream.
  final Stream<T> _stream;

  /// The subscription to [_stream].
  ///
  /// This will be `null` until a branch has a listener.
  StreamSubscription<T>? _subscription;

  /// The buffer of events or errors that have already been emitted by
  /// [_stream].
  final _buffer = <Result<T>>[];

  /// The controllers for branches that are listening for future events from
  /// [_stream].
  ///
  /// Once a branch is canceled, it's removed from this list. When [_stream] is
  /// done, all branches are removed.
  final _controllers = <StreamController<T>>{};

  /// A group of futures returned by [close].
  ///
  /// This is used to ensure that [close] doesn't complete until all
  /// [StreamController.close] and [StreamSubscription.cancel] calls complete.
  final _closeGroup = FutureGroup();

  /// Whether [_stream] is done emitting events.
  var _isDone = false;

  /// Whether [close] has been called.
  var _isClosed = false;

  /// Splits [stream] into [count] identical streams.
  ///
  /// [count] defaults to 2. This is the same as creating [count] branches and
  /// then closing the [StreamSplitter].
  static List<Stream<T>> splitFrom<T>(Stream<T> stream, [int? count]) {
    count ??= 2;
    var splitter = StreamSplitter<T>(stream);
    var streams = List<Stream<T>>.generate(count, (_) => splitter.split());
    splitter.close();
    return streams;
  }

  StreamSplitter(this._stream);

  /// Returns a single-subscription stream that's a copy of the input stream.
  ///
  /// This will throw a [StateError] if [close] has been called.
  Stream<T> split() {
    if (_isClosed) {
      throw StateError("Can't call split() on a closed StreamSplitter.");
    }

    var controller = StreamController<T>(
        onListen: _onListen, onPause: _onPause, onResume: _onResume);
    controller.onCancel = () => _onCancel(controller);

    for (var result in _buffer) {
      result.addTo(controller);
    }

    if (_isDone) {
      _closeGroup.add(controller.close());
    } else {
      _controllers.add(controller);
    }

    return controller.stream;
  }

  /// Indicates that no more branches will be requested via [split].
  ///
  /// This clears the internal buffer of events. If there are no branches or all
  /// branches have been canceled, this cancels the subscription to the input
  /// stream.
  ///
  /// Returns a [Future] that completes once all events have been processed by
  /// all branches and (if applicable) the subscription to the input stream has
  /// been canceled.
  Future close() {
    if (_isClosed) return _closeGroup.future;
    _isClosed = true;

    _buffer.clear();
    if (_controllers.isEmpty) _cancelSubscription();

    return _closeGroup.future;
  }

  /// Cancel [_subscription] and close [_closeGroup].
  ///
  /// This should be called after all the branches' subscriptions have been
  /// canceled and the splitter has been closed. In that case, we won't use the
  /// events from [_subscription] any more, since there's nothing to pipe them
  /// to and no more branches will be created. If [_subscription] is done,
  /// canceling it will be a no-op.
  ///
  /// This may also be called before any branches have been created, in which
  /// case [_subscription] will be `null`.
  void _cancelSubscription() {
    assert(_controllers.isEmpty);
    assert(_isClosed);

    Future? future;
    if (_subscription != null) future = _subscription!.cancel();
    if (future != null) _closeGroup.add(future);
    _closeGroup.close();
  }

  // StreamController events

  /// Subscribe to [_stream] if we haven't yet done so, and resume the
  /// subscription if we have.
  void _onListen() {
    if (_isDone) return;

    if (_subscription != null) {
      // Resume the subscription in case it was paused, either because all the
      // controllers were paused or because the last one was canceled. If it
      // wasn't paused, this will be a no-op.
      _subscription!.resume();
    } else {
      _subscription =
          _stream.listen(_onData, onError: _onError, onDone: _onDone);
    }
  }

  /// Pauses [_subscription] if every controller is paused.
  void _onPause() {
    if (!_controllers.every((controller) => controller.isPaused)) return;
    _subscription!.pause();
  }

  /// Resumes [_subscription].
  ///
  /// If [_subscription] wasn't paused, this is a no-op.
  void _onResume() {
    _subscription!.resume();
  }

  /// Removes [controller] from [_controllers] and cancels or pauses
  /// [_subscription] as appropriate.
  ///
  /// Since the controller emitting a done event will cause it to register as
  /// canceled, this is the only way that a controller is ever removed from
  /// [_controllers].
  void _onCancel(StreamController controller) {
    _controllers.remove(controller);
    if (_controllers.isNotEmpty) return;

    if (_isClosed) {
      _cancelSubscription();
    } else {
      _subscription!.pause();
    }
  }

  // Stream events

  /// Buffers [data] and passes it to [_controllers].
  void _onData(T data) {
    if (!_isClosed) _buffer.add(Result.value(data));
    for (var controller in _controllers) {
      controller.add(data);
    }
  }

  /// Buffers [error] and passes it to [_controllers].
  void _onError(Object error, StackTrace stackTrace) {
    if (!_isClosed) _buffer.add(Result.error(error, stackTrace));
    for (var controller in _controllers) {
      controller.addError(error, stackTrace);
    }
  }

  /// Marks [_controllers] as done.
  void _onDone() {
    _isDone = true;
    for (var controller in _controllers) {
      _closeGroup.add(controller.close());
    }
  }
}
