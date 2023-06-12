import 'dart:async';
import 'dart:collection';

import 'package:rxdart/src/utils/collection_extensions.dart';
import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

/// The strategy that is used to determine how and when a new window is created.
enum WindowStrategy {
  /// cancels the open window (if any) and immediately opens a fresh one.
  everyEvent,

  /// waits until the current open window completes, then when the
  /// source [Stream] emits a next event, it opens a new window.
  eventAfterLastWindow,

  /// opens a recurring window right after the very first event on
  /// the source [Stream] is emitted.
  firstEventOnly,

  /// does not open any windows, rather all events are buffered and emitted
  /// whenever the handler triggers, after this trigger, the buffer is cleared.
  onHandler
}

class _BackpressureStreamSink<S, T> extends ForwardingSink<S, T> {
  final WindowStrategy _strategy;
  final Stream<dynamic> Function(S event)? _windowStreamFactory;
  final T Function(S event)? _onWindowStart;
  final T Function(List<S> queue)? _onWindowEnd;
  final int _startBufferEvery;
  final bool Function(List<S> queue)? _closeWindowWhen;
  final bool _ignoreEmptyWindows;
  final bool _dispatchOnClose;
  final Queue<S> queue = DoubleLinkedQueue<S>();
  final int? maxLengthQueue;
  var skip = 0;
  var _hasData = false;
  var _mainClosed = false;
  StreamSubscription<dynamic>? _windowSubscription;

  _BackpressureStreamSink(
    this._strategy,
    this._windowStreamFactory,
    this._onWindowStart,
    this._onWindowEnd,
    this._startBufferEvery,
    this._closeWindowWhen,
    this._ignoreEmptyWindows,
    this._dispatchOnClose,
    this.maxLengthQueue,
  );

  @override
  void onData(S data) {
    _hasData = true;
    maybeCreateWindow(data, sink);

    if (skip == 0) {
      queue.add(data);

      if (maxLengthQueue != null && queue.length > maxLengthQueue!) {
        queue.removeFirstElements(queue.length - maxLengthQueue!);
      }
    }

    if (skip > 0) {
      skip--;
    }

    maybeCloseWindow(sink);
  }

  @override
  void onError(Object e, StackTrace st) => sink.addError(e, st);

  @override
  void onDone() {
    _mainClosed = true;

    if (_strategy == WindowStrategy.eventAfterLastWindow) {
      return;
    }

    // treat the final event as a Window that opens
    // and immediately closes again
    if (_dispatchOnClose && queue.isNotEmpty) {
      resolveWindowStart(queue.last, sink);
    }

    resolveWindowEnd(sink, true);

    queue.clear();

    _windowSubscription?.cancel();
    sink.close();
  }

  @override
  FutureOr<void> onCancel() => _windowSubscription?.cancel();

  @override
  void onListen() {}

  @override
  void onPause() => _windowSubscription?.pause();

  @override
  void onResume() => _windowSubscription?.resume();

  void maybeCreateWindow(S event, EventSink<T> sink) {
    switch (_strategy) {
      // for example throttle
      case WindowStrategy.eventAfterLastWindow:
        if (_windowSubscription != null) return;

        _windowSubscription = singleWindow(event, sink);

        resolveWindowStart(event, sink);

        break;
      // for example scan
      case WindowStrategy.firstEventOnly:
        if (_windowSubscription != null) return;

        _windowSubscription = multiWindow(event, sink);

        resolveWindowStart(event, sink);

        break;
      // for example debounce
      case WindowStrategy.everyEvent:
        _windowSubscription?.cancel();

        _windowSubscription = singleWindow(event, sink);

        resolveWindowStart(event, sink);

        break;
      case WindowStrategy.onHandler:
        break;
    }
  }

  void maybeCloseWindow(EventSink<T> sink) {
    if (_closeWindowWhen != null && _closeWindowWhen!(unmodifiableQueue)) {
      resolveWindowEnd(sink);
    }
  }

  StreamSubscription<dynamic> singleWindow(S event, EventSink<T> sink) =>
      buildStream(event, sink).take(1).listen(
            null,
            onError: sink.addError,
            onDone: () => resolveWindowEnd(sink, _mainClosed),
          );

  // opens a new Window which is kept open until the main Stream
  // closes.
  StreamSubscription<dynamic> multiWindow(S event, EventSink<T> sink) =>
      buildStream(event, sink).listen(
        (dynamic _) => resolveWindowEnd(sink),
        onError: sink.addError,
        onDone: () => resolveWindowEnd(sink),
      );

  Stream<dynamic> buildStream(S event, EventSink<T> sink) {
    Stream stream;

    _windowSubscription?.cancel();

    stream = _windowStreamFactory!(event);

    return stream;
  }

  void resolveWindowStart(S event, EventSink<T> sink) {
    if (_onWindowStart != null) {
      sink.add(_onWindowStart!(event));
    }
  }

  void resolveWindowEnd(EventSink<T> sink, [bool isControllerClosing = false]) {
    if (isControllerClosing &&
        _strategy == WindowStrategy.eventAfterLastWindow) {
      if (_dispatchOnClose &&
          _hasData &&
          queue.length > 1 &&
          _onWindowEnd != null) {
        sink.add(_onWindowEnd!(unmodifiableQueue));
      }

      queue.clear();
      _windowSubscription?.cancel();
      _windowSubscription = null;

      sink.close();
      return;
    }

    if (isControllerClosing ||
        _strategy == WindowStrategy.eventAfterLastWindow ||
        _strategy == WindowStrategy.everyEvent) {
      _windowSubscription?.cancel();
      _windowSubscription = null;
    }

    if (isControllerClosing && !_dispatchOnClose) {
      return;
    }

    if (_hasData && (queue.isNotEmpty || !_ignoreEmptyWindows)) {
      if (_onWindowEnd != null) {
        sink.add(_onWindowEnd!(unmodifiableQueue));
      }

      // prepare the buffer for the next window.
      // by default, this is just a cleared buffer
      if (!isControllerClosing && _startBufferEvery > 0) {
        skip = _startBufferEvery > queue.length
            ? _startBufferEvery - queue.length
            : 0;

        // ...unless startBufferEvery is provided.
        // here we backtrack to the first event of the last buffer
        // and count forward using startBufferEvery until we reach
        // the next event.
        //
        // if the next event is found inside the current buffer,
        // then this event and any later events in the buffer
        // become the starting values of the next buffer.
        // if the next event is not yet available, then a skip
        // count is calculated.
        // this count will skip the next Future n-events.
        // when skip is reset to 0, then we start adding events
        // again into the new buffer.
        //
        // example:
        // startBufferEvery = 2
        // last buffer: [0, 1, 2, 3, 4]
        // 0 is the first event,
        // 2 is the n-th event
        // new buffer starts with [2, 3, 4]
        //
        // example:
        // startBufferEvery = 3
        // last buffer: [0, 1]
        // 0 is the first event,
        // the n-the event is not yet dispatched at this point
        // skip becomes 1
        // event 2 is skipped, skip becomes 0
        // event 3 is now added to the buffer
        if (_startBufferEvery < queue.length) {
          queue.removeFirstElements(_startBufferEvery);
        } else {
          queue.clear();
        }
      } else {
        queue.clear();
      }
    }
  }

  List<S> get unmodifiableQueue => List<S>.unmodifiable(queue);
}

/// A highly customizable [StreamTransformer] which can be configured
/// to serve any of the common rx backpressure operators.
///
/// The [StreamTransformer] works by creating windows, during which it
/// buffers events to a [Queue].
///
/// The [StreamTransformer] works by creating windows, during which it
/// buffers events to a [Queue]. It uses a  [WindowStrategy] to determine
/// how and when a new window is created.
///
/// onWindowStart and onWindowEnd are handlers that fire when a window
/// opens and closes, right before emitting the transformed event.
///
/// startBufferEvery allows to skip events coming from the source [Stream].
///
/// ignoreEmptyWindows can be set to true, to allow events to be emitted
/// at the end of a window, even if the current buffer is empty.
/// If the buffer is empty, then an empty [List] will be emitted.
/// If false, then nothing is emitted on an empty buffer.
///
/// dispatchOnClose will cause the remaining values in the buffer to be
/// emitted when the source [Stream] closes.
/// When false, the remaining buffer is discarded on close.
class BackpressureStreamTransformer<S, T> extends StreamTransformerBase<S, T> {
  /// Determines how the window is created
  final WindowStrategy strategy;

  /// Factory method used to create the [Stream] which will be buffered
  final Stream<dynamic> Function(S event)? windowStreamFactory;

  /// Handler which fires when the window opens
  final T Function(S event)? onWindowStart;

  /// Handler which fires when the window closes
  final T Function(List<S> queue)? onWindowEnd;

  /// Maximum length of the buffer.
  /// Specify this value to avoid running out of memory when adding too many events to the buffer.
  /// If it's `null`, maximum length of the buffer is unlimited.
  final int? maxLengthQueue;

  /// Used to skip an amount of events
  final int startBufferEvery;

  /// Predicate which determines when the current window should close
  final bool Function(List<S> queue)? closeWindowWhen;

  /// Toggle to prevent, or allow windows that contain
  /// no events to be dispatched
  final bool ignoreEmptyWindows;

  /// Toggle to prevent, or allow the final set of events to be dispatched
  /// when the source [Stream] closes
  final bool dispatchOnClose;

  /// Constructs a [StreamTransformer] which buffers events emitted by the
  /// [Stream] that is created by [windowStreamFactory].
  ///
  /// Use the various optional parameters to precisely determine how and when
  /// this buffer should be created.
  ///
  /// For more info on the parameters, see [BackpressureStreamTransformer],
  /// or see the various back pressure [StreamTransformer]s for examples.
  BackpressureStreamTransformer(
    this.strategy,
    this.windowStreamFactory, {
    this.onWindowStart,
    this.onWindowEnd,
    this.startBufferEvery = 0,
    this.closeWindowWhen,
    this.ignoreEmptyWindows = true,
    this.dispatchOnClose = true,
    this.maxLengthQueue,
  });

  @override
  Stream<T> bind(Stream<S> stream) => forwardStream(
        stream,
        () => _BackpressureStreamSink(
          strategy,
          windowStreamFactory,
          onWindowStart,
          onWindowEnd,
          startBufferEvery,
          closeWindowWhen,
          ignoreEmptyWindows,
          dispatchOnClose,
          maxLengthQueue,
        ),
      );
}
