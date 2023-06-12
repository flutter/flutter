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
  Subject(StreamController<T> controller, Stream<T> stream)
      : _controller = controller,
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
  Stream<T> get stream => this;

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
    onAddError(error, stackTrace);

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

    final completer = Completer<void>();
    var isOnDoneCalled = false;
    void complete() {
      if (!isOnDoneCalled) {
        isOnDoneCalled = true;
        _isAddingStreamItems = false;
        completer.complete();
      }
    }

    _isAddingStreamItems = true;

    source.listen((T event) {
      _add(event);
    }, onError: (Object e, StackTrace s) {
      _addError(e, s);

      if (identical(cancelOnError, true)) {
        complete();
      }
    }, onDone: () {
      complete();
    }, cancelOnError: cancelOnError);

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
    onAdd(event);

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
