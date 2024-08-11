// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/// Runs user code and takes actions depending on success or failure.
_runUserCode<T>(T userCode(), onSuccess(T value),
    onError(Object error, StackTrace stackTrace)) {
  try {
    onSuccess(userCode());
  } catch (e, s) {
    AsyncError? replacement = Zone.current.errorCallback(e, s);
    if (replacement == null) {
      onError(e, s);
    } else {
      var error = replacement.error;
      var stackTrace = replacement.stackTrace;
      onError(error, stackTrace);
    }
  }
}

/** Helper function to cancel a subscription and wait for the potential future,
  before completing with an error. */
void _cancelAndError(StreamSubscription subscription, _Future future,
    Object error, StackTrace stackTrace) {
  var cancelFuture = subscription.cancel();
  if (cancelFuture != null && !identical(cancelFuture, Future._nullFuture)) {
    cancelFuture.whenComplete(() => future._completeError(error, stackTrace));
  } else {
    future._completeError(error, stackTrace);
  }
}

void _cancelAndErrorWithReplacement(StreamSubscription subscription,
    _Future future, Object error, StackTrace stackTrace) {
  AsyncError? replacement = Zone.current.errorCallback(error, stackTrace);
  if (replacement != null) {
    error = replacement.error;
    stackTrace = replacement.stackTrace;
  }
  _cancelAndError(subscription, future, error, stackTrace);
}

/// Helper function to make an onError argument to [_runUserCode].
void Function(Object error, StackTrace stackTrace) _cancelAndErrorClosure(
    StreamSubscription subscription, _Future future) {
  return (Object error, StackTrace stackTrace) {
    _cancelAndError(subscription, future, error, stackTrace);
  };
}

/** Helper function to cancel a subscription and wait for the potential future,
  before completing with a value. */
void _cancelAndValue(StreamSubscription subscription, _Future future, value) {
  var cancelFuture = subscription.cancel();
  if (cancelFuture != null && !identical(cancelFuture, Future._nullFuture)) {
    cancelFuture.whenComplete(() => future._complete(value));
  } else {
    future._complete(value);
  }
}

/// A [Stream] that forwards subscriptions to another stream.
///
/// This stream implements [Stream], but forwards all subscriptions
/// to an underlying stream, and wraps the returned subscription to
/// modify the events on the way.
///
/// This class is intended for internal use only.
abstract class _ForwardingStream<S, T> extends Stream<T> {
  final Stream<S> _source;

  _ForwardingStream(this._source);

  bool get isBroadcast => _source.isBroadcast;

  StreamSubscription<T> listen(void onData(T value)?,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    return _createSubscription(onData, onError, onDone, cancelOnError ?? false);
  }

  StreamSubscription<T> _createSubscription(void onData(T data)?,
      Function? onError, void onDone()?, bool cancelOnError) {
    return new _ForwardingStreamSubscription<S, T>(
        this, onData, onError, onDone, cancelOnError);
  }

  // Override the following methods in subclasses to change the behavior.

  void _handleData(S data, _EventSink<T> sink);

  void _handleError(Object error, StackTrace stackTrace, _EventSink<T> sink) {
    sink._addError(error, stackTrace);
  }

  void _handleDone(_EventSink<T> sink) {
    sink._close();
  }
}

/// Abstract superclass for subscriptions that forward to other subscriptions.
class _ForwardingStreamSubscription<S, T>
    extends _BufferingStreamSubscription<T> {
  final _ForwardingStream<S, T> _stream;

  StreamSubscription<S>? _subscription;

  _ForwardingStreamSubscription(this._stream, void onData(T data)?,
      Function? onError, void onDone()?, bool cancelOnError)
      : super(onData, onError, onDone, cancelOnError) {
    _subscription = _stream._source
        .listen(_handleData, onError: _handleError, onDone: _handleDone);
  }

  // _StreamSink interface.
  // Transformers sending more than one event have no way to know if the stream
  // is canceled or closed after the first, so we just ignore remaining events.

  void _add(T data) {
    if (_isClosed) return;
    super._add(data);
  }

  void _addError(Object error, StackTrace stackTrace) {
    if (_isClosed) return;
    super._addError(error, stackTrace);
  }

  // StreamSubscription callbacks.

  void _onPause() {
    _subscription?.pause();
  }

  void _onResume() {
    _subscription?.resume();
  }

  Future<void>? _onCancel() {
    var subscription = _subscription;
    if (subscription != null) {
      _subscription = null;
      return subscription.cancel();
    }
    return null;
  }

  // Methods used as listener on source subscription.

  void _handleData(S data) {
    _stream._handleData(data, this);
  }

  void _handleError(error, StackTrace stackTrace) {
    _stream._handleError(error, stackTrace, this);
  }

  void _handleDone() {
    _stream._handleDone(this);
  }
}

// -------------------------------------------------------------------
// Stream transformers used by the default Stream implementation.
// -------------------------------------------------------------------

void _addErrorWithReplacement(
    _EventSink sink, Object error, StackTrace stackTrace) {
  AsyncError? replacement = Zone.current.errorCallback(error, stackTrace);
  if (replacement != null) {
    error = replacement.error;
    stackTrace = replacement.stackTrace;
  }
  sink._addError(error, stackTrace);
}

class _WhereStream<T> extends _ForwardingStream<T, T> {
  final bool Function(T) _test;

  _WhereStream(Stream<T> source, bool test(T value))
      : _test = test,
        super(source);

  void _handleData(T inputEvent, _EventSink<T> sink) {
    bool satisfies;
    try {
      satisfies = _test(inputEvent);
    } catch (e, s) {
      _addErrorWithReplacement(sink, e, s);
      return;
    }
    if (satisfies) {
      sink._add(inputEvent);
    }
  }
}

typedef T _Transformation<S, T>(S value);

/// A stream pipe that converts data events before passing them on.
class _MapStream<S, T> extends _ForwardingStream<S, T> {
  final _Transformation<S, T> _transform;

  _MapStream(Stream<S> source, T transform(S event))
      : this._transform = transform,
        super(source);

  void _handleData(S inputEvent, _EventSink<T> sink) {
    T outputEvent;
    try {
      outputEvent = _transform(inputEvent);
    } catch (e, s) {
      _addErrorWithReplacement(sink, e, s);
      return;
    }
    sink._add(outputEvent);
  }
}

/// A stream pipe that converts data events before passing them on.
class _ExpandStream<S, T> extends _ForwardingStream<S, T> {
  final _Transformation<S, Iterable<T>> _expand;

  _ExpandStream(Stream<S> source, Iterable<T> expand(S event))
      : this._expand = expand,
        super(source);

  void _handleData(S inputEvent, _EventSink<T> sink) {
    try {
      for (T value in _expand(inputEvent)) {
        sink._add(value);
      }
    } catch (e, s) {
      // If either _expand or iterating the generated iterator throws,
      // we abort the iteration.
      _addErrorWithReplacement(sink, e, s);
    }
  }
}

/// A stream pipe that converts or disposes error events
/// before passing them on.
class _HandleErrorStream<T> extends _ForwardingStream<T, T> {
  final void Function(Object, StackTrace) _onError;
  final bool Function(Object)? _test;

  _HandleErrorStream(Stream<T> source, this._onError, this._test)
      : super(source);

  void _handleData(T data, _EventSink<T> sink) {
    sink._add(data);
  }

  void _handleError(Object error, StackTrace stackTrace, _EventSink<T> sink) {
    bool matches = true;
    var test = _test;
    if (test != null) {
      try {
        matches = test(error);
      } catch (e, s) {
        _addErrorWithReplacement(sink, e, s);
        return;
      }
    }
    if (matches) {
      try {
        _onError(error, stackTrace);
      } catch (e, s) {
        if (identical(e, error)) {
          sink._addError(error, stackTrace);
        } else {
          _addErrorWithReplacement(sink, e, s);
        }
        return;
      }
    } else {
      sink._addError(error, stackTrace);
    }
  }
}

class _TakeStream<T> extends _ForwardingStream<T, T> {
  final int _count;

  _TakeStream(Stream<T> source, int count)
      : this._count = count,
        super(source);

  StreamSubscription<T> _createSubscription(void onData(T data)?,
      Function? onError, void onDone()?, bool cancelOnError) {
    if (_count == 0) {
      _source.listen(null).cancel();
      return new _DoneStreamSubscription<T>(onDone);
    }
    return new _StateStreamSubscription<int, T>(
        this, onData, onError, onDone, cancelOnError, _count);
  }

  void _handleData(T inputEvent, _EventSink<T> sink) {
    var subscription = sink as _StateStreamSubscription<int, T>;
    int count = subscription._subState;
    if (count > 0) {
      sink._add(inputEvent);
      count -= 1;
      subscription._subState = count;
      if (count == 0) {
        // Closing also unsubscribes all subscribers, which unsubscribes
        // this from source.
        sink._close();
      }
    }
  }
}

/// A [_ForwardingStreamSubscription] with one extra state field.
///
/// Use by several different classes, storing an integer, bool or general.
class _StateStreamSubscription<S, T>
    extends _ForwardingStreamSubscription<T, T> {
  S _subState;

  _StateStreamSubscription(_ForwardingStream<T, T> stream, void onData(T data)?,
      Function? onError, void onDone()?, bool cancelOnError, this._subState)
      : super(stream, onData, onError, onDone, cancelOnError);
}

class _TakeWhileStream<T> extends _ForwardingStream<T, T> {
  final bool Function(T) _test;

  _TakeWhileStream(Stream<T> source, bool test(T value))
      : this._test = test,
        super(source);

  void _handleData(T inputEvent, _EventSink<T> sink) {
    bool satisfies;
    try {
      satisfies = _test(inputEvent);
    } catch (e, s) {
      _addErrorWithReplacement(sink, e, s);
      // The test didn't say true. Didn't say false either, but we stop anyway.
      sink._close();
      return;
    }
    if (satisfies) {
      sink._add(inputEvent);
    } else {
      sink._close();
    }
  }
}

class _SkipStream<T> extends _ForwardingStream<T, T> {
  final int _count;

  _SkipStream(Stream<T> source, int count)
      : this._count = count,
        super(source) {
    // This test is done early to avoid handling an async error
    // in the _handleData method.
    RangeError.checkNotNegative(count, "count");
  }

  StreamSubscription<T> _createSubscription(void onData(T data)?,
      Function? onError, void onDone()?, bool cancelOnError) {
    return new _StateStreamSubscription<int, T>(
        this, onData, onError, onDone, cancelOnError, _count);
  }

  void _handleData(T inputEvent, _EventSink<T> sink) {
    var subscription = sink as _StateStreamSubscription<int, T>;
    int count = subscription._subState;
    if (count > 0) {
      subscription._subState = count - 1;
      return;
    }
    sink._add(inputEvent);
  }
}

class _SkipWhileStream<T> extends _ForwardingStream<T, T> {
  final bool Function(T) _test;

  _SkipWhileStream(Stream<T> source, bool test(T value))
      : this._test = test,
        super(source);

  StreamSubscription<T> _createSubscription(void onData(T data)?,
      Function? onError, void onDone()?, bool cancelOnError) {
    return new _StateStreamSubscription<bool, T>(
        this, onData, onError, onDone, cancelOnError, false);
  }

  void _handleData(T inputEvent, _EventSink<T> sink) {
    var subscription = sink as _StateStreamSubscription<bool, T>;
    bool hasFailed = subscription._subState;
    if (hasFailed) {
      sink._add(inputEvent);
      return;
    }
    bool satisfies;
    try {
      satisfies = _test(inputEvent);
    } catch (e, s) {
      _addErrorWithReplacement(sink, e, s);
      // A failure to return a boolean is considered "not matching".
      subscription._subState = true;
      return;
    }
    if (!satisfies) {
      subscription._subState = true;
      sink._add(inputEvent);
    }
  }
}

class _DistinctStream<T> extends _ForwardingStream<T, T> {
  static final _SENTINEL = new Object();

  final bool Function(T, T)? _equals;

  _DistinctStream(Stream<T> source, bool equals(T a, T b)?)
      : _equals = equals,
        super(source);

  StreamSubscription<T> _createSubscription(void onData(T data)?,
      Function? onError, void onDone()?, bool cancelOnError) {
    return new _StateStreamSubscription<Object?, T>(
        this, onData, onError, onDone, cancelOnError, _SENTINEL);
  }

  void _handleData(T inputEvent, _EventSink<T> sink) {
    var subscription = sink as _StateStreamSubscription<Object?, T>;
    var previous = subscription._subState;
    if (identical(previous, _SENTINEL)) {
      // First event. Cannot use [_equals].
      subscription._subState = inputEvent;
      sink._add(inputEvent);
    } else {
      T previousEvent = previous as T;
      var equals = _equals;
      bool isEqual;
      try {
        if (equals == null) {
          isEqual = (previousEvent == inputEvent);
        } else {
          isEqual = equals(previousEvent, inputEvent);
        }
      } catch (e, s) {
        _addErrorWithReplacement(sink, e, s);
        return;
      }
      if (!isEqual) {
        sink._add(inputEvent);
        subscription._subState = inputEvent;
      }
    }
  }
}
