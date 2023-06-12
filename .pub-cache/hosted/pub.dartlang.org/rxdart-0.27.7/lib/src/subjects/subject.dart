import 'dart:async';

/// The base for all Subjects. If you'd like to create a new Subject,
/// extend from this class.
///
/// It handles all of the nitty-gritty details that conform to the
/// StreamController spec and don't need to be repeated over and
/// over.
///
/// Please see `PublishSubject` for the simplest example of how to
/// extend from this class, or `BehaviorSubject` for a slightly more
/// complex example.
abstract class Subject<T> extends StreamView<T> implements StreamController<T> {
  final StreamController<T> _controller;

  bool _isAddingStreamItems = false;

  /// Constructs a [Subject] which wraps the provided [controller].
  /// This constructor is applicable only for classes that extend [Subject].
  ///
  /// To guarantee the contract of a [Subject], the [controller] must be
  /// a broadcast [StreamController] and the [stream] must also be a broadcast [Stream].
  Subject(StreamController<T> controller, Stream<T> stream)
      : _controller = controller,
        assert(stream.isBroadcast, 'Subject requires a broadcast stream'),
        super(stream);

  @override
  StreamSink<T> get sink => _StreamSinkWrapper<T>(this);

  @override
  ControllerCallback? get onListen => _controller.onListen;

  @override
  set onListen(void Function()? onListenHandler) {
    _controller.onListen = onListenHandler;
  }

  @override
  Stream<T> get stream => _SubjectStream(this);

  @override
  ControllerCallback get onPause =>
      throw UnsupportedError('Subjects do not support pause callbacks');

  @override
  set onPause(void Function()? onPauseHandler) =>
      throw UnsupportedError('Subjects do not support pause callbacks');

  @override
  ControllerCallback get onResume =>
      throw UnsupportedError('Subjects do not support resume callbacks');

  @override
  set onResume(void Function()? onResumeHandler) =>
      throw UnsupportedError('Subjects do not support resume callbacks');

  @override
  ControllerCancelCallback? get onCancel => _controller.onCancel;

  @override
  set onCancel(ControllerCancelCallback? onCancelHandler) {
    _controller.onCancel = onCancelHandler;
  }

  @override
  bool get isClosed => _controller.isClosed;

  @override
  bool get isPaused => _controller.isPaused;

  @override
  bool get hasListener => _controller.hasListener;

  @override
  Future<dynamic> get done => _controller.done;

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (_isAddingStreamItems) {
      throw StateError(
          'You cannot add an error while items are being added from addStream');
    }

    _addError(error, stackTrace);
  }

  void _addError(Object error, [StackTrace? stackTrace]) {
    if (!_controller.isClosed) {
      onAddError(error, stackTrace);
    }

    // if the controller is closed, calling addError() will throw an StateError.
    // that is expected behavior.
    _controller.addError(error, stackTrace);
  }

  /// An extension point for sub-classes. Perform any side-effect / state
  /// management you need to here, rather than overriding the `add` method
  /// directly.
  void onAddError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<T> source, {bool? cancelOnError}) {
    if (_isAddingStreamItems) {
      throw StateError(
          'You cannot add items while items are being added from addStream');
    }
    _isAddingStreamItems = true;

    final completer = Completer<void>();
    void complete() {
      if (!completer.isCompleted) {
        _isAddingStreamItems = false;
        completer.complete();
      }
    }

    source.listen(
      _add,
      onError: identical(cancelOnError, true)
          ? (Object e, StackTrace s) {
              _addError(e, s);
              complete();
            }
          : _addError,
      onDone: complete,
      cancelOnError: cancelOnError,
    );

    return completer.future;
  }

  @override
  void add(T event) {
    if (_isAddingStreamItems) {
      throw StateError(
          'You cannot add items while items are being added from addStream');
    }

    _add(event);
  }

  void _add(T event) {
    if (!_controller.isClosed) {
      onAdd(event);
    }

    // if the controller is closed, calling add() will throw an StateError.
    // that is expected behavior.
    _controller.add(event);
  }

  /// An extension point for sub-classes. Perform any side-effect / state
  /// management you need to here, rather than overriding the `add` method
  /// directly.
  void onAdd(T event) {}

  @override
  Future<dynamic> close() {
    if (_isAddingStreamItems) {
      throw StateError(
          'You cannot close the subject while items are being added from addStream');
    }

    return _controller.close();
  }
}

class _SubjectStream<T> extends Stream<T> {
  final Subject<T> _subject;

  _SubjectStream(this._subject);

  @override
  bool get isBroadcast => true;

  // Override == and hashCode so that new streams returned by the same
  // subject are considered equal.
  // The subject returns a new stream each time it's queried,
  // but doesn't have to cache the result.

  @override
  int get hashCode => _subject.hashCode ^ 0x35323532;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _SubjectStream && identical(other._subject, _subject);
  }

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _subject.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
}

/// A class that exposes only the [StreamSink] interface of an object.
class _StreamSinkWrapper<T> implements StreamSink<T> {
  final StreamController<T> _target;

  _StreamSinkWrapper(this._target);

  @override
  void add(T data) {
    _target.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _target.addError(error, stackTrace);
  }

  @override
  Future<dynamic> close() => _target.close();

  @override
  Future<dynamic> addStream(Stream<T> source) => _target.addStream(source);

  @override
  Future<dynamic> get done => _target.done;
}
